//
//  ReplyResultView.swift
//  PRINZ
//
//  RIZZスタイル完全再現版
//

import SwiftUI

struct ReplyResultView: View {
    let image: UIImage?
    let extractedText: String
    let context: Context
    let initialTone: ReplyType  // 初期選択トーン
    
    // 状態管理（シンプル化）
    @State private var isAnalyzing = false
    @State private var hasGenerated = false
    @State private var allReplies: [Reply] = []
    @State private var copiedReplyId: UUID?
    @State private var mainMessage = ""
    
    // タイピングアニメーション用
    @State private var displayedTexts: [UUID: String] = [:]
    @State private var animationTimers: [UUID: Timer] = [:]
    
    // BOX順次出現用
    @State private var visibleBoxCount = 0
    
    // カスタマイズ用
    @State private var selectedTone: ReplyType
    @State private var isShortMode = true
    
    private let toneTypes: [ReplyType] = [.safe, .chill, .witty]

    private func iconColorForType(_ type: ReplyType) -> Color {
        switch type {
        case .safe: return .cyan
        case .chill: return .orange
        case .witty: return .purple
        }
    }

    init(image: UIImage?, extractedText: String, context: Context, initialTone: ReplyType = .safe) {
        self.image = image
        self.extractedText = extractedText
        self.context = context
        self.initialTone = initialTone
        self._selectedTone = State(initialValue: initialTone)
    }
    
    var body: some View {
        ZStack {
            // 背景
            MagicBackground()
            
            if isAnalyzing {
                AnalyzingView()
            } else {
                mainContentView
            }
        }
        .navigationTitle("AI回答")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 画面表示時に即座に生成開始
            if !hasGenerated {
                generateReply()
            }
        }
    }
    
    // MARK: - Main Content
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // スクリーンショット
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                }
                
                // 入力欄
                inputFieldView
                
                // 生成済みの場合
                if hasGenerated {
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
                    .padding(.top, 8)
                    
                    // 3件の返信リスト
                    repliesListView
                    
                    // カスタマイズセクション
                    customizationSection
                    
                    // 再生成ボタン
                    regenerateButton
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    // MARK: - Input Field
    
    private var inputFieldView: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.cyan)
            
            TextField("フォーカスする言葉を教えて", text: $mainMessage)
                .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }
    
    // MARK: - Replies List (BOX順次出現 + タイピング)
    
    private var repliesListView: some View {
        VStack(spacing: 12) {
            ForEach(Array(allReplies.enumerated()), id: \.element.id) { index, reply in
                if index < visibleBoxCount {
                    replyRow(reply)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                        .onAppear {
                            startTypingAnimation(for: reply)
                        }
                }
            }
        }
        .onAppear {
            startSequentialBoxAppearance()
        }
    }
    
    /// BOXを上から順番に出現させる
    private func startSequentialBoxAppearance() {
        visibleBoxCount = 0
        
        for i in 0..<allReplies.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    visibleBoxCount = i + 1
                }
            }
        }
    }
    
    private func replyRow(_ reply: Reply) -> some View {
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
                .fill(Color.white)  // 明示的に白背景
        )
        .onTapGesture {
            copyReply(reply)
        }
        .overlay(
            // コピー済み表示
            copiedReplyId == reply.id ?
            HStack {
                Spacer()
                Text("✓ コピー")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(8)
            } : nil
        )
    }
    
    // MARK: - Typing Animation
    
    private func startTypingAnimation(for reply: Reply) {
        // 既にアニメーション中なら何もしない
        if animationTimers[reply.id] != nil { return }
        
        let fullText = reply.text
        var currentIndex = 0
        displayedTexts[reply.id] = ""
        
        // 25ms間隔で1文字ずつ表示
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
    
    // MARK: - Customization Section
    
    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("さらにカスタマイズする")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            // グループ1: トーン選択
            HStack(spacing: 8) {
                ForEach(toneTypes, id: \.self) { tone in
                    tagButton(tone.displayName, isSelected: selectedTone == tone) {
                        selectedTone = tone
                    }
                }
            }
            
            // グループ2: 長さ選択
            HStack(spacing: 8) {
                tagButton("短文", isSelected: isShortMode) {
                    isShortMode = true
                }
                tagButton("長文", isSelected: !isShortMode) {
                    isShortMode = false
                }
                Spacer()
            }
        }
        .padding(.top, 8)
    }
    
    private func tagButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
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
    }
    
    // MARK: - Buttons
    
    private var regenerateButton: some View {
        Button(action: generateReply) {
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
    }
    
    // MARK: - Actions
    
    private func generateReply() {
        isAnalyzing = true
        
        guard let image = image else {
            generateAIReply(with: extractedText.isEmpty ? "メッセージ" : extractedText)
            return
        }
        
        // OCR実行
        OCRService.shared.recognizeTextWithCoordinates(from: image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    let parsedChat = ChatParser.shared.parseWithCoordinates(items)
                    let partnerMessage = parsedChat.partnerMessagesText.isEmpty
                        ? parsedChat.rawText
                        : parsedChat.partnerMessagesText
                    generateAIReply(with: partnerMessage, parsedChat: parsedChat)
                case .failure:
                    fallbackToTextOCR()
                }
            }
        }
    }
    
    private func fallbackToTextOCR() {
        guard let image = image else {
            generateAIReply(with: extractedText.isEmpty ? "メッセージ" : extractedText)
            return
        }
        
        OCRService.shared.recognizeText(from: image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    let parsedChat = ChatParser.shared.parse(text)
                    generateAIReply(with: text, parsedChat: parsedChat)
                case .failure:
                    generateAIReply(with: extractedText.isEmpty ? "メッセージ" : extractedText)
                }
            }
        }
    }
    
    private func generateAIReply(with message: String, parsedChat: ParsedChat? = nil) {
        let partnerMessage = parsedChat?.partnerMessagesText.isEmpty == false
            ? parsedChat!.partnerMessagesText
            : message
        
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
                let result = try await FirebaseService.shared.generateReplies(
                    message: partnerMessage,
                    personalType: .funny,
                    gender: .male,
                    ageGroup: .early20s,
                    relationship: context.displayName,
                    partnerName: parsedChat?.partnerName,
                    userMessage: userMessageToSend,
                    isShortMode: isShortMode,
                    selectedTone: selectedTone
                )
                
                await MainActor.run {
                    withAnimation {
                        isAnalyzing = false
                        hasGenerated = true
                    }
                    allReplies = result.replies
                }
            } catch {
                await MainActor.run {
                    fallbackToMockReplies()
                }
            }
        }
    }
    
    private func fallbackToMockReplies() {
        withAnimation {
            isAnalyzing = false
            hasGenerated = true
        }
        
        let replies = ReplyGenerator.shared.generateReplies(
            for: extractedText.isEmpty ? "メッセージ" : extractedText,
            context: context,
            type: selectedTone
        )
        allReplies = replies
    }
    
    private func copyReply(_ reply: Reply) {
        UIPasteboard.general.string = reply.text
        copiedReplyId = reply.id
        DataManager.shared.saveReply(reply)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedReplyId == reply.id {
                copiedReplyId = nil
            }
        }
    }
}

// MARK: - Analyzing View

// MARK: - Analyzing View (ローディングアニメーション強化)

struct AnalyzingView: View {
    @State private var rotation: Double = 0
    @State private var pulse: Bool = false
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                // 外側の回転リング
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.8), .cyan.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 3
                        )
                        .frame(width: CGFloat(90 + index * 35), height: CGFloat(90 + index * 35))
                        .rotationEffect(.degrees(rotation + Double(index * 30)))
                }
                
                // 白い回転ライン（追加）
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            colors: [.white, .white.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-rotation * 1.5))
                
                // 中心の王冠アイコン
                Image(systemName: "crown.fill")
                    .font(.system(size: 45))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(pulse ? 1.1 : 1.0)
                    .shadow(color: .purple.opacity(0.5), radius: 15)
            }
            
            VStack(spacing: 8) {
                Text("AIが回答を作成中...")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("少々お待ちください")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .onAppear {
            // 回転アニメーション
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            // パルスアニメーション
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReplyResultView(
            image: nil,
            extractedText: "今日楽しかったね！また遊ぼう",
            context: .matchStart,
            initialTone: .safe
        )
    }
}
