//
//  ReplyResultView.swift
//  PRINZ
//
//  Created on 2026-01-12.
//

import SwiftUI

struct ReplyResultView: View {
    let image: UIImage?
    let extractedText: String
    let context: Context
    
    // 状態管理
    @State private var isAnalyzing = false  // 最初はfalse、生成ボタンで開始
    @State private var hasGenerated = false  // 生成済みフラグ
    @State private var currentToneIndex = 0  // 安牌→ちょい攻め→変化球のサイクル
    @State private var replyStack: [Reply] = []  // スタック形式で積み上げ
    @State private var cachedReplies: [ReplyType: [Reply]] = [:]  // キャッシュ
    @State private var mainMessage = ""
    @State private var isShortMode = true  // 短文モード（デフォルト）
    @State private var copiedReplyId: UUID?
    
    // BOXインターフェース用ステート
    @State private var allReplies: [Reply] = []     // 3案すべて保持
    @State private var currentReplyIndex = 0       // 表示中のインデックス
    @State private var isTypingComplete = false    // タイピング完了フラグ
    @State private var showSkeleton = false        // スケルトン表示フラグ
    
    private let toneTypes: [ReplyType] = [.safe, .chill, .witty]
    
    var body: some View {
        ZStack {
            // 魔法のグラデーション背景
            MagicBackground()
            
            if isAnalyzing {
                // 解析演出
                AnalyzingView()
            } else {
                // メインコンテンツ
                mainContentView
            }
        }
        .navigationTitle("AI回答")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Main Content
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // スクリーンショットプレビュー
                    if image != nil {
                        imagePreviewView
                    }
                    
                    // メインメッセージ入力
                    mainMessageInput
                    
                    // 生成済みの場合のみ表示
                    if hasGenerated {
                        // AI回答セクション
                        aiAnswerSection
                        
                        // 🆕 BOXインターフェース
                        replyBoxView
                        
                        // トーン切り替えボタン
                        toneButtonsView
                        
                        // 返信スタック（過去の回答）
                        if replyStack.count > 0 {
                            Text("過去の回答")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 20)
                            
                            replyStackView
                        }
                    }
                    
                    Spacer(minLength: 150)
                }
                .padding()
            }
            
            // 下部固定ボタン
            bottomButtonsView
        }
    }
    
    // MARK: - Image Preview
    
    private var imagePreviewView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("スクリーンショット")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.glassBorder, lineWidth: 1)
                    )
                    .frame(maxHeight: 200)
            }
        }
    }
    
    // MARK: - Main Message Input
    
    private var mainMessageInput: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.neonCyan)
            
            TextField("何をメインで伝える？", text: $mainMessage)
                .foregroundColor(.white)
                .font(.body)
            
            if !mainMessage.isEmpty && hasGenerated {
                Button(action: regenerateWithMainMessage) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.neonPurple)
                }
            }
        }
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
    
    // MARK: - AI Answer Section
    
    private var aiAnswerSection: some View {
        HStack {
            Text("👇")
            Text("PRINZのAI回答")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.neonPurple, .neonCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text("👇")
        }
        .padding(.top, 10)
    }
    
    // MARK: - Reply BOX View (🆕 BOXインターフェース)
    
    private var replyBoxView: some View {
        VStack(spacing: 12) {
            if showSkeleton {
                // スケルトンローダー
                SkeletonLoaderView()
            } else if let currentReply = allReplies[safe: currentReplyIndex] {
                // 現在の回答BOX
                VStack(alignment: .leading, spacing: 10) {
                    // タイプバッジ
                    HStack {
                        replyTypeBadge(for: currentReply.type)
                        Spacer()
                        if copiedReplyId == currentReply.id {
                            Label("コピー済み", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // タイピングアニメーション付きテキスト
                    TypingTextView(
                        fullText: currentReply.text,
                        typingSpeed: 0.025,
                        onComplete: { isTypingComplete = true }
                    )
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.glassBackground)
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(replyTypeColor(for: currentReply.type).opacity(0.5), lineWidth: 2)
                        )
                )
                .onTapGesture {
                    copyReply(currentReply)
                }
            }
        }
    }
    
    // MARK: - Tone Buttons View
    
    private var toneButtonsView: some View {
        HStack(spacing: 12) {
            ForEach(Array(toneTypes.enumerated()), id: \.offset) { index, tone in
                Button(action: { selectTone(at: index) }) {
                    VStack(spacing: 4) {
                        Text(toneEmoji(for: tone))
                            .font(.title2)
                        Text(tone.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(currentReplyIndex == index ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(currentReplyIndex == index ? replyTypeColor(for: tone) : Color.glassBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(replyTypeColor(for: tone), lineWidth: currentReplyIndex == index ? 0 : 1)
                    )
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Reply Stack
    
    private var replyStackView: some View {
        VStack(spacing: 12) {
            ForEach(replyStack) { reply in
                ReplyBubbleCard(
                    reply: reply,
                    isCopied: copiedReplyId == reply.id,
                    onTap: {
                        copyReply(reply)
                    }
                )
            }
        }
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtonsView: some View {
        VStack(spacing: 12) {
            // オプション行: トーン選択 + 長文/短文
            HStack(spacing: 8) {
                // トーン選択ボタン（安牌/ちょい攻め/変化球）
                Button(action: cycleNextTone) {
                    HStack(spacing: 4) {
                        Text(currentToneEmoji)
                            .font(.caption)
                        Text(toneTypes[currentToneIndex].displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.glassBackground)
                            .overlay(
                                Capsule()
                                    .stroke(Color.neonPurple, lineWidth: 1)
                            )
                    )
                }
                
                // 長文/短文切り替え
                Button(action: { isShortMode.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isShortMode ? "text.alignleft" : "doc.text")
                            .font(.caption)
                        Text(isShortMode ? "短文" : "長文")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.glassBackground)
                            .overlay(
                                Capsule()
                                    .stroke(Color.neonCyan, lineWidth: 1)
                            )
                    )
                }
                
                Spacer()
            }
            
            // メインボタン: 回答を生成
            Button(action: generateReply) {
                HStack {
                    Image(systemName: "sparkles")
                    Text(hasGenerated ? "別の回答を生成" : "回答を生成")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.magicPurple, .magicPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
                .shadow(color: .magicPink.opacity(0.5), radius: 10)
            }
        }
        .padding()
        .background(
            Color.magicPurple.opacity(0.8)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Computed Properties
    
    private var currentToneEmoji: String {
        toneEmoji(for: toneTypes[currentToneIndex])
    }
    
    private func toneEmoji(for type: ReplyType) -> String {
        switch type {
        case .safe: return "🛡️"
        case .chill: return "🔥"
        case .witty: return "⚡"
        }
    }
    
    private func replyTypeColor(for type: ReplyType) -> Color {
        switch type {
        case .safe: return .neonCyan
        case .chill: return .orange
        case .witty: return .neonPurple
        }
    }
    
    private func replyTypeBadge(for type: ReplyType) -> some View {
        HStack(spacing: 4) {
            Image(systemName: replyTypeIcon(for: type))
            Text(type.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(replyTypeColor(for: type))
    }
    
    private func replyTypeIcon(for type: ReplyType) -> String {
        switch type {
        case .safe: return "shield.fill"
        case .chill: return "flame.fill"
        case .witty: return "sparkles"
        }
    }
    
    // MARK: - Actions
    
    private func generateReply() {
        isAnalyzing = true
        showSkeleton = true
        isTypingComplete = false
        
        // 画像からOCRでテキストを抽出
        performOCRAndGenerate()
    }
    
    private func selectTone(at index: Int) {
        guard index != currentReplyIndex else { return }
        currentReplyIndex = index
        isTypingComplete = false
    }
    
    private func performOCRAndGenerate() {
        guard let image = image else {
            // 画像がない場合は直接AI生成
            generateAIReply(with: extractedText.isEmpty ? "メッセージ" : extractedText, parsedChat: nil)
            return
        }
        
        // 座標付きOCR実行（話者分離用）
        OCRService.shared.recognizeTextWithCoordinates(from: image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    print("📝 OCR Result (with coordinates): \(items.count) items")
                    for item in items.prefix(5) {
                        print("  [\(item.isFromPartner ? "相手" : "自分")] x=\(String(format: "%.2f", item.normalizedX)): \(item.text.prefix(30))")
                    }
                    
                    // 座標ベースで解析
                    let parsedChat = ChatParser.shared.parseWithCoordinates(items)
                    let partnerMessage = parsedChat.partnerMessagesText.isEmpty
                        ? parsedChat.rawText
                        : parsedChat.partnerMessagesText
                    
                    generateAIReply(with: partnerMessage, parsedChat: parsedChat)
                    
                case .failure(let error):
                    print("❌ OCR Error: \(error)")
                    // フォールバック: 通常のOCR
                    fallbackToTextOCR()
                }
            }
        }
    }
    
    private func fallbackToTextOCR() {
        guard let image = image else {
            generateAIReply(with: extractedText.isEmpty ? "メッセージ" : extractedText, parsedChat: nil)
            return
        }
        
        OCRService.shared.recognizeText(from: image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    let parsedChat = ChatParser.shared.parse(text)
                    generateAIReply(with: text, parsedChat: parsedChat)
                case .failure:
                    generateAIReply(with: extractedText.isEmpty ? "メッセージ" : extractedText, parsedChat: nil)
                }
            }
        }
    }
    
    private func generateAIReply(with message: String, parsedChat: ParsedChat?) {
        // TODO: 設定画面からユーザー情報を取得
        let personalType: PersonalType = .funny  // デフォルト
        let gender: UserGender = .male  // デフォルト
        let ageGroup: UserAgeGroup = .early20s  // デフォルト
        
        // 相手からのメッセージのみを抽出
        let partnerMessage = parsedChat?.partnerMessagesText.isEmpty == false
            ? parsedChat!.partnerMessagesText
            : message
        
        print("📝 Parsed Chat:")
        print("  Partner Name: \(parsedChat?.partnerName ?? "不明")")
        print("  Partner Messages: \(partnerMessage.prefix(100))...")
        print("  User Message (input): \(mainMessage.isEmpty ? "なし" : mainMessage)")
        print("  Last User Message (OCR): \(parsedChat?.lastUserMessage ?? "なし")")
        print("  Short Mode: \(isShortMode)")
        
        // userMessageの決定: 入力欄 > OCRから抽出した自分の直近発言
        let userMessageToSend: String?
        if !mainMessage.isEmpty {
            userMessageToSend = mainMessage
        } else if let lastUserMsg = parsedChat?.lastUserMessage {
            userMessageToSend = "自分の最後の発言: \(lastUserMsg)"
        } else {
            userMessageToSend = nil
        }
        
        Task {
            do {
                // Firebase経由でAI返信を生成
                let result = try await FirebaseService.shared.generateReplies(
                    message: partnerMessage,
                    personalType: personalType,
                    gender: gender,
                    ageGroup: ageGroup,
                    relationship: context.displayName,
                    partnerName: parsedChat?.partnerName,
                    userMessage: userMessageToSend,
                    isShortMode: isShortMode
                )
                
                await MainActor.run {
                    withAnimation {
                        isAnalyzing = false
                        hasGenerated = true
                        showSkeleton = false
                    }
                    
                    // BOXインターフェース用に保持
                    allReplies = result.replies
                    currentReplyIndex = 0
                    isTypingComplete = false
                    
                    // 過去の回答としてスタックに追加
                    // withAnimation {
                    //     replyStack.insert(contentsOf: result.replies, at: 0)
                    // }
                    
                    print("✅ Generated \(result.replies.count) replies, remaining: \(result.remainingToday)")
                }
                
            } catch let error as FirebaseError {
                await MainActor.run {
                    handleGenerationError(error)
                }
            } catch {
                await MainActor.run {
                    print("❌ AI Generation Error: \(error)")
                    // フォールバック: モック返信を使用
                    fallbackToMockReplies()
                }
            }
        }
    }
    
    private func handleGenerationError(_ error: FirebaseError) {
        print("❌ Firebase Error: \(error.localizedDescription)")
        
        switch error {
        case .rateLimitExceeded:
            // レート制限エラー時はモックを使用してUIは表示
            fallbackToMockReplies()
        case .unauthenticated:
            // 認証エラー時もモックを使用
            fallbackToMockReplies()
        default:
            // その他のエラーもモックでフォールバック
            fallbackToMockReplies()
        }
    }
    
    private func fallbackToMockReplies() {
        withAnimation {
            isAnalyzing = false
            hasGenerated = true
            showSkeleton = false
        }
        
        let currentTone = toneTypes[currentToneIndex]
        let replies = ReplyGenerator.shared.generateReplies(
            for: extractedText.isEmpty ? "メッセージ" : extractedText,
            context: context,
            type: currentTone
        )
        
        // BOXインターフェース用に保持
        allReplies = replies
        currentReplyIndex = 0
        isTypingComplete = false
        
        print("⚠️ Using mock replies as fallback")
    }
    
    private func cycleNextTone() {
        currentToneIndex = (currentToneIndex + 1) % toneTypes.count
    }
    
    private func regenerateWithMainMessage() {
        // キャッシュクリア＆初回から再生成
        cachedReplies.removeAll()
        replyStack.removeAll()
        hasGenerated = false
        generateReply()
    }
    
    private func copyReply(_ reply: Reply) {
        UIPasteboard.general.string = reply.text
        copiedReplyId = reply.id
        
        // 履歴に保存
        DataManager.shared.saveReply(reply)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedReplyId == reply.id {
                copiedReplyId = nil
            }
        }
    }
}

// MARK: - Analyzing View

struct AnalyzingView: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // レーダー演出
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.neonPurple.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: CGFloat(100 + index * 40), height: CGFloat(100 + index * 40))
                        .rotationEffect(.degrees(rotation))
                }
                
                // 中央のクラウン
                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.magicPurple, .magicPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(scale)
            }
            
            Text("AI回答作成中...")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("最適な返信を分析しています")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                scale = 1.2
            }
        }
    }
}

// MARK: - Reply Bubble Card

struct ReplyBubbleCard: View {
    let reply: Reply
    let isCopied: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // タイプアイコン
            HStack {
                typeIcon
                Spacer()
                if isCopied {
                    Label("コピー済み", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // 返信テキスト
            Text(reply.text)
                .font(.body)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.glassBackground)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.glassBorder, lineWidth: 1)
                )
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private var typeIcon: some View {
        HStack(spacing: 4) {
            Image(systemName: typeSystemImage)
            Text(reply.type.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(typeColor)
    }
    
    private var typeSystemImage: String {
        switch reply.type {
        case .safe: return "shield.fill"
        case .chill: return "flame.fill"
        case .witty: return "sparkles"
        }
    }
    
    private var typeColor: Color {
        switch reply.type {
        case .safe: return .neonCyan
        case .chill: return .orange
        case .witty: return .neonPurple
        }
    }
}

#Preview {
    NavigationStack {
        ReplyResultView(
            image: nil,
            extractedText: "今日楽しかったね！また遊ぼう",
            context: .matchStart
        )
    }
}

// MARK: - Array Safe Access Extension

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
