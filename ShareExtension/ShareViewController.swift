//
//  ShareViewController.swift
//  ShareExtension
//
//  Created on 2026-01-11.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    private var hostingController: UIHostingController<ShareExtensionView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    }
}

// MARK: - ShareExtensionView (SwiftUI)

struct ShareExtensionView: View {
    let extensionContext: NSExtensionContext?
    
    @State private var currentStep: ShareStep = .loading
    @State private var loadedImage: UIImage?
    @State private var selectedContext: Context?
    @State private var generatedReplies: [Reply] = []
    @State private var errorMessage: String?
    @State private var isGenerating = false
    @State private var userMessage: String = ""  // ユーザー入力メッセージ
    
    enum ShareStep {
        case loading
        case inputAndContext  // 入力+状況選択画面
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
                        case .inputAndContext:
                            inputAndContextView
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
    
    // MARK: - Input and Context View
    
    private var inputAndContextView: some View {
        VStack(spacing: 20) {
            // 上部スペース（画面を上に伸ばす）
            Spacer()
                .frame(height: 40)
            
            // 画像プレビュー（大きめに）
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)  // 120 → 180 (+50%)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.glassBorder, lineWidth: 1)
                    )
            }
            
            // メッセージ入力
            VStack(alignment: .leading, spacing: 8) {
                Text("PRINZに任せたい内容")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("例: 次のデートに誘いたい", text: $userMessage)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.glassBorder, lineWidth: 1)
                            )
                    )
            }
            
            // 状況選択
            VStack(alignment: .leading, spacing: 10) {
                Text("状況を選択")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                // 横スクロール（少し大きめに）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Context.allCases, id: \.self) { context in
                            Button(action: {
                                selectedContext = context
                            }) {
                                HStack(spacing: 6) {
                                    Text(context.emoji)
                                        .font(.subheadline)
                                    Text(context.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(selectedContext == context ? .black : .white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(selectedContext == context ? Color.neonCyan : Color.glassBackground)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(selectedContext == context ? Color.neonCyan : Color.glassBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                }
            }
            
            // 生成ボタン
            Button(action: startGeneration) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("回答を生成")
                        .fontWeight(.bold)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.neonCyan, .neonPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .opacity(selectedContext == nil ? 0.5 : 1)
            }
            .disabled(selectedContext == nil)
            
            Spacer()
                .frame(height: 20)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Generating View
    
    private var generatingView: some View {
        VStack(spacing: 24) {
            ScanningAnimationView()
            
            Text("AI回答を生成中...")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("少々お待ちください")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
        VStack(spacing: 16) {
            // タイトル
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.neonCyan)
                    Text("AI返信案")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text("タップしてコピー")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // 返信リスト
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(generatedReplies) { reply in
                        ShareReplyCard(reply: reply) {
                            copyReply(reply)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 閉じるボタン
            Button(action: closeExtension) {
                Text("完了")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.glassBackground)
                    )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
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
        guard let extensionContext = extensionContext,
              let item = extensionContext.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            showError("画像が見つかりませんでした")
            return
        }
        
        // 画像を探す
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (item, error) in
                    DispatchQueue.main.async {
                        if let error = error {
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
                            currentStep = .inputAndContext
                        } else {
                            showError("画像の形式が不正です")
                        }
                    }
                }
                return
            }
        }
        
        showError("画像が見つかりませんでした")
    }
    
    private func startGeneration() {
        currentStep = .generating
        
        // OCR実行 → AI生成
        performOCRAndGenerate()
    }
    
    private func performOCRAndGenerate() {
        guard let image = loadedImage else {
            showError("画像が見つかりませんでした")
            return
        }
        
        // OCR実行
        OCRService.shared.recognizeText(from: image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    print("📝 ShareExtension OCR: \(text.prefix(100))...")
                    generateAIReplies(with: text)
                case .failure(let error):
                    print("❌ ShareExtension OCR Error: \(error)")
                    // OCR失敗時はモック返信を使用
                    fallbackToMockReplies()
                }
            }
        }
    }
    
    private func generateAIReplies(with message: String) {
        guard let context = selectedContext else {
            fallbackToMockReplies()
            return
        }
        
        Task {
            do {
                // Firebase経由でAI返信を生成
                let result = try await FirebaseService.shared.generateReplies(
                    message: message,
                    personalType: .funny,
                    gender: .male,
                    ageGroup: .early20s,
                    relationship: context.displayName
                )
                
                await MainActor.run {
                    generatedReplies = result.replies
                    
                    // 履歴に保存
                    DataManager.shared.saveReplies(result.replies)
                    
                    currentStep = .results
                    print("✅ ShareExtension: Generated \(result.replies.count) replies")
                }
                
            } catch {
                await MainActor.run {
                    print("❌ ShareExtension AI Error: \(error)")
                    fallbackToMockReplies()
                }
            }
        }
    }
    
    private func fallbackToMockReplies() {
        guard let context = selectedContext else {
            showError("状況が選択されていません")
            return
        }
        
        let replies = ReplyGenerator.shared.generateReplies(
            for: "メッセージ",
            context: context
        )
        
        generatedReplies = replies
        DataManager.shared.saveReplies(replies)
        currentStep = .results
        print("⚠️ ShareExtension: Using mock replies")
    }
    
    private func copyReply(_ reply: Reply) {
        UIPasteboard.general.string = reply.text
        print("📋 Copied: \(reply.text.prefix(50))...")
    }
    
    private func closeExtension() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        currentStep = .error
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
