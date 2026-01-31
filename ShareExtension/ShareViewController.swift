//
//  ShareViewController.swift
//  ShareExtension
//
//  Created on 2026-01-11.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers
import Firebase

// MARK: - Share Extension Log Manager

/// Share Extension用の永続化ログ（デバッグ用）
class ShareExtensionLogger {
    static let shared = ShareExtensionLogger()
    private let logKey = "com.prinz.shareExtension.logs"
    
    private init() {}
    
    func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logEntry = "[\(timestamp)] [\(fileName):\(line)] \(function): \(message)"
        
        // コンソール出力
        print("📱 ShareExt: \(logEntry)")
        
        // UserDefaults（AppGroup）に永続化
        if let defaults = UserDefaults(suiteName: "group.com.prinz.shared") {
            var logs = defaults.stringArray(forKey: logKey) ?? []
            logs.append(logEntry)
            // 最新100件のみ保持
            if logs.count > 100 {
                logs = Array(logs.suffix(100))
            }
            defaults.set(logs, forKey: logKey)
            defaults.synchronize()
        }
    }
    
    func getLogs() -> [String] {
        return UserDefaults(suiteName: "group.com.prinz.shared")?.stringArray(forKey: logKey) ?? []
    }
    
    func clearLogs() {
        UserDefaults(suiteName: "group.com.prinz.shared")?.removeObject(forKey: logKey)
    }
}

// MARK: - ShareViewController

class ShareViewController: UIViewController {
    
    private var hostingController: UIHostingController<ShareExtensionView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ShareExtensionLogger.shared.log("viewDidLoad started")
        
        // Firebase初期化（Share Extensionは別プロセスなので必要）
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            ShareExtensionLogger.shared.log("Firebase initialized")
        }
        
        // SwiftUIビューをホスト
        let shareView = ShareExtensionView(extensionContext: extensionContext)
        hostingController = UIHostingController(rootView: shareView)
        
        if let hostingController = hostingController {
            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.view.frame = view.bounds
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostingController.didMove(toParent: self)
        }
        
        // 背景を透明に
        view.backgroundColor = .clear
        
        ShareExtensionLogger.shared.log("viewDidLoad completed")
    }
}

// MARK: - ShareExtensionView (SwiftUI)

struct ShareExtensionView: View {
    let extensionContext: NSExtensionContext?
    
    @State private var currentStep: ShareStep = .loading
    @State private var loadedImage: UIImage?
    @State private var selectedTone: ReplyType = .safe
    @State private var isShortMode = true
    @State private var generatedReplies: [Reply] = []
    @State private var copiedReplyId: UUID?
    @State private var errorMessage: String?
    @State private var isGenerating = false
    @State private var isCopied = false
    
    // タイピングアニメーション用
    @State private var displayedTexts: [UUID: String] = [:]
    @State private var animationTimers: [UUID: Timer] = [:]
    
    // BOX順次出現用
    @State private var visibleBoxCount = 0
    
    enum ShareStep {
        case loading
        case toneSelection   // 気分選択画面（安牌・攻め・変化球）
        case generating
        case results
        case error
    }
    
    var body: some View {
        ZStack {
            // 背景 - メインアプリと統一
            MagicBackground()
            
            VStack(spacing: 0) {
                // ヘッダー
                headerView
                
                // メインコンテンツ
                ScrollView {
                    Group {
                        switch currentStep {
                        case .loading:
                            loadingView
                        case .toneSelection:
                            toneSelectionView
                        case .generating:
                            generatingView
                        case .results:
                            resultsView
                        case .error:
                            errorView
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            ShareExtensionLogger.shared.log("ShareExtensionView appeared")
            loadSharedImage()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.neonPurple, .neonCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .neonPurple, radius: 10)
            
            Text("PRINZ")
                .font(.title2)
                .fontWeight(.black)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.neonPurple, .neonCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Spacer()
            
            Button(action: closeExtension) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(.neonPurple)
                .scaleEffect(1.5)
            
            Text("画像を読み込み中...")
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Tone Selection View (新UI：安牌・攻め・変化球)
    
    private var toneSelectionView: some View {
        VStack(spacing: 24) {
            // 画像プレビュー
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.glassBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10)
            }
            
            // タイトル
            VStack(spacing: 8) {
                Text("どんな返信にする？")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("タップで選択 → AI生成開始")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // 3ボタン選択（安牌・攻め・変化球）
            VStack(spacing: 14) {
                // 安牌
                ToneButton(
                    tone: .safe,
                    title: "安牌",
                    subtitle: "無難で失敗しない返信",
                    icon: "shield.fill",
                    color: .neonCyan,
                    isSelected: selectedTone == .safe
                ) {
                    selectToneAndGenerate(.safe)
                }
                
                // ちょい攻め
                ToneButton(
                    tone: .chill,
                    title: "ちょい攻め",
                    subtitle: "距離を縮める積極的な返信",
                    icon: "flame.fill",
                    color: .orange,
                    isSelected: selectedTone == .chill
                ) {
                    selectToneAndGenerate(.chill)
                }
                
                // 変化球
                ToneButton(
                    tone: .witty,
                    title: "変化球",
                    subtitle: "予想を裏切るユニークな返信",
                    icon: "sparkles",
                    color: .neonPurple,
                    isSelected: selectedTone == .witty
                ) {
                    selectToneAndGenerate(.witty)
                }
            }
            .padding(.horizontal)
            
            Spacer().frame(height: 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Generating View
    
    private var generatingView: some View {
        VStack(spacing: 24) {
            // スケルトンローダー
            SkeletonLoaderView()
            
            Text("AI回答を生成中...")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("「\(selectedTone.displayName)」の返信を作成しています")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Results View (RIZZスタイル: 3件リスト表示)
    
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // スクリーンショット表示
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                // ヘッダー
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("PRINZのAI回答")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // BOX順次出現リスト
                ForEach(Array(generatedReplies.enumerated()), id: \.element.id) { index, reply in
                    if index < visibleBoxCount {
                        replyRowView(reply: reply)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
                    }
                }
                
                // カスタマイズセクション
                VStack(alignment: .leading, spacing: 12) {
                    Text("さらにカスタマイズする")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal)
                    
                    // トーン選択（安牌/ちょい攻め/変化球）
                    HStack(spacing: 8) {
                        ForEach([ReplyType.safe, .chill, .witty], id: \.self) { tone in
                            TagButton(
                                title: tone.displayName,
                                isSelected: selectedTone == tone
                            ) {
                                selectedTone = tone
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 長さ選択（短文/長文）
                    HStack(spacing: 8) {
                        TagButton(
                            title: "短文",
                            isSelected: isShortMode
                        ) {
                            isShortMode = true
                        }
                        
                        TagButton(
                            title: "長文",
                            isSelected: !isShortMode
                        ) {
                            isShortMode = false
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
                
                // 再生成ボタン
                Button(action: regenerateWithTone) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("回答を再生成")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .padding(.horizontal)
                
                // 完了ボタン
                Button(action: closeExtension) {
                    Text("完了")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 8)
            }
            .padding(.vertical)
        }
        .onAppear {
            startSequentialBoxAppearance()
        }
    }
    
    /// BOXを上から順番に出現させる
    private func startSequentialBoxAppearance() {
        visibleBoxCount = 0
        
        for i in 0..<generatedReplies.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    visibleBoxCount = i + 1
                }
            }
        }
    }
    
    /// トーンタイプに応じたアイコン色
    private func iconColorForType(_ type: ReplyType) -> Color {
        switch type {
        case .safe: return .cyan
        case .chill: return .orange
        case .witty: return .purple
        }
    }

    /// 個別の返信行ビュー（タイピングアニメーション付き）
    private func replyRowView(reply: Reply) -> some View {
        let displayText = displayedTexts[reply.id] ?? ""

        return HStack(alignment: .top, spacing: 12) {
            // カテゴリ縦線バー
            RoundedRectangle(cornerRadius: 2)
                .fill(iconColorForType(reply.type))
                .frame(width: 4)

            // 返信テキスト（タイピングアニメーション）
            Text(displayText)
                .font(.body)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .overlay(
            copiedReplyId == reply.id ?
            HStack {
                Spacer()
                Text("✓ コピー")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(8)
            } : nil
        )
        .padding(.horizontal)
        .onTapGesture {
            copyReplyWithFeedback(reply)
        }
        .onAppear {
            startTypingAnimation(for: reply)
        }
    }
    
    /// コピー（フィードバック付き）+ 履歴保存
    private func copyReplyWithFeedback(_ reply: Reply) {
        UIPasteboard.general.string = reply.text
        copiedReplyId = reply.id
        
        // コピー時のみ履歴に保存
        DataManager.shared.saveReply(reply)
        ShareExtensionLogger.shared.log("Copied and saved reply: \(reply.text.prefix(30))...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedReplyId == reply.id {
                copiedReplyId = nil
            }
        }
    }
    
    // MARK: - Typing Animation
    
    private func startTypingAnimation(for reply: Reply) {
        if animationTimers[reply.id] != nil { return }
        
        let fullText = reply.text
        var currentIndex = 0
        displayedTexts[reply.id] = ""
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { timer in
            if currentIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
                displayedTexts[reply.id] = String(fullText[...index])
                currentIndex += 1
            } else {
                timer.invalidate()
                animationTimers.removeValue(forKey: reply.id)
            }
        }
        animationTimers[reply.id] = timer
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(errorMessage ?? "エラーが発生しました")
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("閉じる") {
                closeExtension()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.glassBackground)
            )
        }
    }
    
    // MARK: - Actions
    
    private func loadSharedImage() {
        ShareExtensionLogger.shared.log("loadSharedImage started")
        
        guard let extensionContext = extensionContext,
              let item = extensionContext.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            ShareExtensionLogger.shared.log("No attachments found")
            showError("画像が見つかりませんでした")
            return
        }
        
        ShareExtensionLogger.shared.log("Found \(attachments.count) attachments")
        
        // 画像を探す
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                ShareExtensionLogger.shared.log("Loading image from provider")
                
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (item, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            ShareExtensionLogger.shared.log("Image load error: \(error.localizedDescription)")
                            showError("画像の読み込みに失敗しました: \(error.localizedDescription)")
                            return
                        }
                        
                        var image: UIImage?
                        
                        if let url = item as? URL {
                            image = UIImage(contentsOfFile: url.path)
                        } else if let data = item as? Data {
                            image = UIImage(data: data)
                        } else if let img = item as? UIImage {
                            image = img
                        }
                        
                        if let image = image {
                            loadedImage = image
                            currentStep = .toneSelection
                            ShareExtensionLogger.shared.log("Image loaded successfully, transitioning to toneSelection")
                        } else {
                            ShareExtensionLogger.shared.log("Image format invalid")
                            showError("画像の形式が不正です")
                        }
                    }
                }
                return
            }
        }
        
        ShareExtensionLogger.shared.log("No image found in attachments")
        showError("画像が見つかりませんでした")
    }
    
    private func selectToneAndGenerate(_ tone: ReplyType) {
        ShareExtensionLogger.shared.log("selectToneAndGenerate: \(tone.displayName)")
        
        selectedTone = tone
        currentStep = .generating
        
        // OCR実行 → AI生成
        performOCRAndGenerate()
    }
    
    private func performOCRAndGenerate() {
        guard let image = loadedImage else {
            ShareExtensionLogger.shared.log("performOCRAndGenerate: No image")
            showError("画像が見つかりませんでした")
            return
        }
        
        ShareExtensionLogger.shared.log("Starting OCR with coordinates")
        
        // 座標付きOCR実行
        OCRService.shared.recognizeTextWithCoordinates(from: image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    ShareExtensionLogger.shared.log("OCR success: \(items.count) items")
                    
                    // 座標ベースで解析
                    let parsedChat = ChatParser.shared.parseWithCoordinates(items)
                    ShareExtensionLogger.shared.log("Parsed: partner=\(parsedChat.partnerName ?? "nil"), messages=\(parsedChat.messages.count)")
                    
                    generateAIReplies(with: parsedChat)
                    
                case .failure(let error):
                    ShareExtensionLogger.shared.log("OCR error: \(error.localizedDescription)")
                    // フォールバック: 通常のOCR
                    fallbackToTextOCR()
                }
            }
        }
    }
    
    private func fallbackToTextOCR() {
        guard let image = loadedImage else {
            fallbackToMockReplies()
            return
        }
        
        OCRService.shared.recognizeText(from: image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    let parsedChat = ChatParser.shared.parse(text)
                    generateAIReplies(with: parsedChat)
                case .failure:
                    fallbackToMockReplies()
                }
            }
        }
    }
    
    private func generateAIReplies(with parsedChat: ParsedChat) {
        let partnerMessage = parsedChat.partnerMessagesText.isEmpty 
            ? parsedChat.rawText 
            : parsedChat.partnerMessagesText
        
        // userMessageの決定: OCRから抽出した自分の直近発言を使用
        let userMessageToSend = parsedChat.lastUserMessage.map { "自分の最後の発言: \($0)" }
        
        ShareExtensionLogger.shared.log("Generating AI replies: partner=\(partnerMessage.prefix(50))...")
        
        Task {
            do {
                // Firebase経由でAI返信を生成
                let result = try await FirebaseService.shared.generateReplies(
                    message: partnerMessage,
                    personalType: .funny,
                    gender: .male,
                    ageGroup: .early20s,
                    relationship: nil,
                    partnerName: parsedChat.partnerName,
                    userMessage: userMessageToSend,
                    isShortMode: isShortMode,
                    selectedTone: selectedTone
                )
                
                await MainActor.run {
                    // 3案全て表示（安牌・ちょい攻め・変化球 各1案）
                    generatedReplies = result.replies

                    currentStep = .results
                    ShareExtensionLogger.shared.log("Transitioned to results: \(generatedReplies.count) replies")
                }
                
            } catch {
                await MainActor.run {
                    ShareExtensionLogger.shared.log("AI generation error: \(error)")
                    fallbackToMockReplies()
                }
            }
        }
    }
    
    private func fallbackToMockReplies() {
        ShareExtensionLogger.shared.log("Using mock replies")
        
        let replies = ReplyGenerator.shared.generateReplies(
            for: "メッセージ",
            context: .matchStart,
            type: selectedTone
        )
        
        generatedReplies = replies
        // ※履歴保存はコピー時のみ実行
        currentStep = .results
    }
    
    private func regenerateWithTone() {
        ShareExtensionLogger.shared.log("regenerateWithTone: tone=\(selectedTone.displayName), short=\(isShortMode)")
        currentStep = .generating
        performOCRAndGenerate()
    }
    
    
    private func closeExtension() {
        ShareExtensionLogger.shared.log("closeExtension called")
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private func openMainApp() {
        let urlScheme = "prinz://"
        ShareExtensionLogger.shared.log("openMainApp: Attempting to open URL scheme '\(urlScheme)'")
        
        guard let url = URL(string: urlScheme) else {
            ShareExtensionLogger.shared.log("openMainApp: Failed to create URL from scheme")
            closeExtension()
            return
        }
        
        ShareExtensionLogger.shared.log("openMainApp: URL created successfully: \(url.absoluteString)")
        ShareExtensionLogger.shared.log("openMainApp: Calling extensionContext?.open()")
        
        // extensionContext経由でURLを開く
        extensionContext?.open(url) { success in
            ShareExtensionLogger.shared.log("openMainApp: completionHandler called with success=\(success)")
            
            DispatchQueue.main.async {
                if success {
                    ShareExtensionLogger.shared.log("openMainApp: Successfully opened main app")
                } else {
                    ShareExtensionLogger.shared.log("openMainApp: Failed to open via extensionContext, trying UIApplication fallback")
                    self.openURLViaUIApplication(url)
                }
                
                // 遷移後に閉じる
                ShareExtensionLogger.shared.log("openMainApp: Calling closeExtension")
                self.closeExtension()
            }
        }
    }
    
    private func openURLViaUIApplication(_ url: URL) {
        ShareExtensionLogger.shared.log("openURLViaUIApplication: Attempting UIApplication fallback for \(url.absoluteString)")
        
        // UIApplication.shared.open を間接的に呼び出す
        if let sharedApplication = UIApplication.value(forKeyPath: "sharedApplication") as? UIApplication {
            ShareExtensionLogger.shared.log("openURLViaUIApplication: Got sharedApplication, calling open()")
            sharedApplication.open(url, options: [:]) { success in
                ShareExtensionLogger.shared.log("openURLViaUIApplication: UIApplication.open completed with success=\(success)")
            }
        } else {
            ShareExtensionLogger.shared.log("openURLViaUIApplication: Failed to get sharedApplication")
        }
    }
    
    private func showError(_ message: String) {
        ShareExtensionLogger.shared.log("showError: \(message)")
        errorMessage = message
        currentStep = .error
    }
}

// MARK: - Tone Button Component

struct ToneButton: View {
    let tone: ReplyType
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // アイコン
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )
                
                // テキスト
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // 矢印
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.glassBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tag Button Component (RIZZスタイル)

struct TagButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.purple : Color.white.opacity(0.2))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.purple : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Share Reply Card

struct ShareReplyCard: View {
    let reply: Reply
    let onTap: () -> Void
    
    @State private var isCopied = false
    
    private var typeColor: Color {
        switch reply.type {
        case .safe: return .neonCyan
        case .chill: return .orange
        case .witty: return .neonPurple
        }
    }
    
    private var typeIcon: String {
        switch reply.type {
        case .safe: return "shield.fill"
        case .chill: return "flame.fill"
        case .witty: return "sparkles"
        }
    }
    
    var body: some View {
        Button(action: {
            isCopied = true
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // タイプバッジ
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: typeIcon)
                            .font(.caption)
                        Text(reply.type.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(typeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(typeColor.opacity(0.15))
                    )
                    
                    Spacer()
                    
                    if isCopied {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("コピー済み")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                }
                
                // 返信テキスト
                Text(reply.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(typeColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
