//
//  ReplyResultView.swift
//  PRINZ
//
//  RIZZスタイル完全再現版
//

import SwiftUI
import StoreKit

/// 生成モード
enum GenerationMode {
    case chatReply        // チャット返信
    case profileGreeting  // プロフィールから挨拶
}

struct ReplyResultView: View {
    let image: UIImage?
    let extractedText: String
    let context: Context
    let initialTone: ReplyType  // 初期選択トーン
    let mode: GenerationMode

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

    // Paywall表示用
    @State private var showPaywall = false
    @State private var showRateLimitAlert = false

    // レビュー誘導用
    @AppStorage("generationSuccessCount") private var generationSuccessCount: Int = 0
    @AppStorage("hasRequestedReview") private var hasRequestedReview: Bool = false
    @State private var showReviewRequest = false

    // ユーザー設定（App Group共有）
    @AppStorage("userGender", store: UserDefaults(suiteName: "group.com.mgolworks.prinz"))
    private var userGenderRaw: String = "男性"
    @AppStorage("userAge", store: UserDefaults(suiteName: "group.com.mgolworks.prinz"))
    private var userAge: Double = 25
    @AppStorage("personalType", store: UserDefaults(suiteName: "group.com.mgolworks.prinz"))
    private var personalTypeRaw: String = PersonalType.natural.rawValue

    private let toneTypes: [ReplyType] = [.safe, .chill, .witty]

    private func iconColorForType(_ type: ReplyType) -> Color {
        switch type {
        case .safe: return .cyan
        case .chill: return .orange
        case .witty: return .purple
        }
    }

    init(image: UIImage?, extractedText: String, context: Context, initialTone: ReplyType = .safe, mode: GenerationMode = .chatReply) {
        self.image = image
        self.extractedText = extractedText
        self.context = context
        self.initialTone = initialTone
        self.mode = mode
        self._selectedTone = State(initialValue: initialTone)
    }
    
    var body: some View {
        ZStack {
            // 背景
            MagicBackground()
            
            if isAnalyzing {
                if let image = image {
                    // スクショがある場合はスキャンエフェクト
                    ScannerOverlayView(image: image)
                } else {
                    // スクショがない場合は従来のアニメーション
                    AnalyzingView()
                }
            } else {
                mainContentView
            }

            // レビュー依頼画面（テスト用: 3回利用後に表示、本番は31回）
            if showReviewRequest {
                ReviewRequestView(isPresented: $showReviewRequest)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut, value: showReviewRequest)
        .navigationTitle("AI回答")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 画面表示時に即座に生成開始
            if !hasGenerated {
                generateReply()
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("本日の無料回数を使い切りました", isPresented: $showRateLimitAlert) {
            Button("プレミアムにアップグレード", role: .none) { showPaywall = true }
            Button("\(UsageManager.shared.timeUntilResetString())にリセット", role: .cancel) {}
        } message: {
            Text("無料プランは1日5回まで。プレミアムなら無制限で使えます！")
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
                        Image(systemName: mode == .profileGreeting ? "hand.wave.fill" : "sparkles")
                            .foregroundColor(.yellow)
                        Text(mode == .profileGreeting ? "PRINZの挨拶提案" : "PRINZのAI回答")
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
            
            TextField(mode == .profileGreeting ? "触れてほしい話題があれば" : "フォーカスする言葉を教えて", text: $mainMessage)
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
        // 利用回数チェック（プレミアムユーザーはスキップ）
        if !SubscriptionManager.shared.isProUser && !UsageManager.shared.canUse() {
            showRateLimitAlert = true
            return
        }

        isAnalyzing = true

        guard let image = image else {
            generateAIReply(with: extractedText.isEmpty ? "メッセージ" : extractedText)
            return
        }

        switch mode {
        case .profileGreeting:
            // プロフィール挨拶モード: OCR → ProfileParser → API
            OCRService.shared.recognizeText(from: image) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let text):
                        #if DEBUG
                        print("🔍 [ProfileGreeting] OCR結果:\n\(text)")
                        #endif
                        let profile = ProfileParser.shared.parse(text)
                        #if DEBUG
                        print("📋 [ProfileGreeting] パース結果:")
                        print("  名前: \(profile.name ?? "未検出")")
                        print("  年齢: \(profile.age.map { "\($0)歳" } ?? "未検出")")
                        print("  居住地: \(profile.location ?? "未検出")")
                        print("  趣味: \(profile.hobbies.isEmpty ? "未検出" : profile.hobbies.joined(separator: ", "))")
                        print("  自己紹介: \(profile.bio ?? "未検出")")
                        print("📤 [ProfileGreeting] API送信サマリー:\n\(profile.summary)")
                        #endif
                        generateProfileGreeting(profile: profile)
                    case .failure(let error):
                        #if DEBUG
                        print("❌ [ProfileGreeting] OCR失敗: \(error)")
                        #endif
                        generateProfileGreeting(profile: ParsedProfile(
                            name: nil, age: nil, location: nil,
                            hobbies: [], bio: nil, rawText: extractedText
                        ))
                    }
                }
            }
        case .chatReply:
            // 既存のチャット返信モード
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

    // MARK: - Profile Greeting Generation

    private func generateProfileGreeting(profile: ParsedProfile) {
        let userMessageToSend = mainMessage.isEmpty ? nil : mainMessage

        Task {
            do {
                let gender = UserGender(rawValue: userGenderRaw) ?? .male
                let ageGroup = UserAgeGroup.from(age: Int(userAge))
                let personalType = PersonalType(rawValue: personalTypeRaw) ?? .natural

                #if DEBUG
                print("🚀 [ProfileGreeting] API呼び出し開始")
                print("  mode: profileGreeting")
                print("  tone: \(selectedTone)")
                print("  personalType: \(personalType.rawValue)")
                print("  gender: \(gender.rawValue), ageGroup: \(ageGroup.rawValue)")
                print("  profileInfo: \(profile.dictionary)")
                #endif

                let result = try await FirebaseService.shared.generateReplies(
                    message: profile.summary,
                    personalType: personalType,
                    gender: gender,
                    ageGroup: ageGroup,
                    relationship: "マッチ直後",
                    userMessage: userMessageToSend,
                    isShortMode: isShortMode,
                    selectedTone: selectedTone,
                    mode: "profileGreeting",
                    profileInfo: profile.dictionary
                )

                #if DEBUG
                print("✅ [ProfileGreeting] API応答: \(result.replies.count)件")
                for (i, reply) in result.replies.enumerated() {
                    print("  [\(i+1)] (\(reply.type.displayName)) \(reply.text)")
                }
                #endif

                await MainActor.run {
                    generationSuccessCount += 1
                    print("📊 [ProfileGreeting] Generation success! New count: \(generationSuccessCount)")
                    // ローカル利用回数を消費
                    _ = UsageManager.shared.consumeUsage()

                    withAnimation {
                        isAnalyzing = false
                        hasGenerated = true
                    }
                    allReplies = result.replies
                    // 残り回数0でPaywall表示（ローディング終了後に遅延表示）
                    if result.remainingToday <= 0 || UsageManager.shared.getRemainingCount() <= 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showRateLimitAlert = true
                        }
                    }
                }
            } catch let error as FirebaseError where error == .rateLimitExceeded {
                #if DEBUG
                print("⚠️ [ProfileGreeting] レート制限到達")
                #endif
                await MainActor.run {
                    withAnimation {
                        isAnalyzing = false
                    }
                    // ローディング終了後にアラート表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showRateLimitAlert = true
                    }
                }
            } catch {
                #if DEBUG
                print("❌ [ProfileGreeting] APIエラー: \(error)")
                #endif
                await MainActor.run {
                    fallbackToMockReplies()
                }
            }
        }
    }

    // MARK: - Chat Reply Generation

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
                let gender = UserGender(rawValue: userGenderRaw) ?? .male
                let ageGroup = UserAgeGroup.from(age: Int(userAge))
                let personalType = PersonalType(rawValue: personalTypeRaw) ?? .natural

                let result = try await FirebaseService.shared.generateReplies(
                    message: partnerMessage,
                    personalType: personalType,
                    gender: gender,
                    ageGroup: ageGroup,
                    relationship: context.displayName,
                    userMessage: userMessageToSend,
                    isShortMode: isShortMode,
                    selectedTone: selectedTone
                )

                await MainActor.run {
                    generationSuccessCount += 1
                    print("📊 [ChatReply] Generation success! New count: \(generationSuccessCount)")
                    // ローカル利用回数を消費
                    _ = UsageManager.shared.consumeUsage()

                    withAnimation {
                        isAnalyzing = false
                        hasGenerated = true
                    }
                    allReplies = result.replies
                    // 残り回数0でPaywall表示（ローディング終了後に遅延表示）
                    if result.remainingToday <= 0 || UsageManager.shared.getRemainingCount() <= 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showRateLimitAlert = true
                        }
                    }
                }
            } catch let error as FirebaseError where error == .rateLimitExceeded {
                #if DEBUG
                print("⚠️ [ChatReply] レート制限到達")
                #endif
                await MainActor.run {
                    withAnimation {
                        isAnalyzing = false
                    }
                    // ローディング終了後にアラート表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showRateLimitAlert = true
                    }
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

        // レビュー誘導: 3回以上生成成功 → カスタム画面を表示（テスト用: hasRequestedReview チェック無効化）
        #if !APP_EXTENSION
        print("📊 Review check: count=\(generationSuccessCount), hasRequested=\(hasRequestedReview)")
        // テスト用: hasRequestedReview を無視して毎回表示可能にする
        if generationSuccessCount >= 3 {
            // hasRequestedReview = true  // テスト中は無効化
            print("📊 Showing review request popup!")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showReviewRequest = true
            }
        }
        #endif

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
