//
//  OnboardingView.swift
//  PRINZ
//
//  Created on 2026-01-31.
//

import SwiftUI

struct OnboardingView: View {
    private static let store = UserDefaults(suiteName: "group.com.prinz.app")

    @AppStorage("userGender", store: UserDefaults(suiteName: "group.com.prinz.app"))
    private var userGenderRaw: String = "男性"

    @AppStorage("userAge", store: UserDefaults(suiteName: "group.com.prinz.app"))
    private var userAge: Double = 25

    @AppStorage("personalType", store: UserDefaults(suiteName: "group.com.prinz.app"))
    private var personalTypeRaw: String = PersonalType.natural.rawValue

    @AppStorage("hasCompletedOnboarding", store: UserDefaults(suiteName: "group.com.prinz.app"))
    private var hasCompletedOnboarding: Bool = false

    @State private var currentStep = 0
    @State private var selectedGender: String? = nil
    @State private var selectedAgeGroup: UserAgeGroup? = nil
    @State private var selectedPersonalType: PersonalType? = nil

    private let genderOptions = ["男性", "女性", "その他"]
    private let totalSteps = 6  // チュートリアル3 + 設定3

    var body: some View {
        ZStack {
            MagicBackground()

            VStack(spacing: 0) {
                // プログレスインジケーター
                progressIndicator
                    .padding(.top, 60)
                    .padding(.bottom, 30)

                // ステップコンテンツ
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    tutorialChatReplyStep.tag(1)
                    tutorialProfileGreetingStep.tag(2)
                    genderStep.tag(3)
                    ageStep.tag(4)
                    personalTypeStep.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
                .simultaneousGesture(DragGesture())

                // ボタン
                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
            }
        }
    }

    // MARK: - Tutorial: Welcome

    private var welcomeStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // ロゴ
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 44))
                    Text("PRINZ")
                        .font(.system(size: 44, weight: .black))
                        .italic()
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: [.neonPurple, .neonCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .neonPurple.opacity(0.5), radius: 20)

                Text("既読のまま、終わらせない。")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("マッチングアプリの返信に悩む時間を\nAIが解決します")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 10)

                // 機能一覧
                VStack(spacing: 16) {
                    featureRow(
                        icon: "bubble.left.and.text.bubble.right",
                        color: .neonPurple,
                        title: "チャット返信",
                        description: "相手のメッセージから最適な返信を提案"
                    )
                    featureRow(
                        icon: "hand.wave",
                        color: .orange,
                        title: "あいさつ作成",
                        description: "プロフィールから初回メッセージを生成"
                    )
                    featureRow(
                        icon: "keyboard",
                        color: .neonCyan,
                        title: "テキスト入力",
                        description: "テキストを直接貼り付けて返信を作成"
                    )
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Tutorial: Chat Reply

    private var tutorialChatReplyStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                stepHeader(
                    icon: "bubble.left.and.text.bubble.right",
                    title: "チャット返信の使い方",
                    subtitle: "3ステップで最適な返信を作成"
                )

                VStack(spacing: 20) {
                    tutorialStepRow(
                        number: 1,
                        icon: "photo.on.rectangle.angled",
                        color: .neonPurple,
                        title: "スクショをアップ",
                        description: "相手とのトーク画面をスクショして\nアプリにアップロード"
                    )
                    tutorialStepRow(
                        number: 2,
                        icon: "slider.horizontal.3",
                        color: .magicPink,
                        title: "トーンを選択",
                        description: "安牌・ちょい攻め・変化球\nから雰囲気を選ぶ"
                    )
                    tutorialStepRow(
                        number: 3,
                        icon: "doc.on.doc",
                        color: .neonCyan,
                        title: "コピーして送信",
                        description: "AIが提案した返信をコピーして\nそのまま送信"
                    )
                }
                .padding(.horizontal, 24)

                // サンプル会話
                sampleChatPreview
                    .padding(.horizontal, 24)
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Tutorial: Profile Greeting

    private var tutorialProfileGreetingStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                stepHeader(
                    icon: "hand.wave",
                    title: "あいさつ作成の使い方",
                    subtitle: "プロフィールから初回メッセージを生成"
                )

                VStack(spacing: 20) {
                    tutorialStepRow(
                        number: 1,
                        icon: "person.text.rectangle",
                        color: .orange,
                        title: "プロフィールをスクショ",
                        description: "気になる相手のプロフィール画面を\nスクリーンショット"
                    )
                    tutorialStepRow(
                        number: 2,
                        icon: "slider.horizontal.3",
                        color: .pink,
                        title: "トーンを選択",
                        description: "あなたのスタイルに合った\n雰囲気を選ぶ"
                    )
                    tutorialStepRow(
                        number: 3,
                        icon: "paperplane.fill",
                        color: .neonCyan,
                        title: "メッセージを送信",
                        description: "プロフィールに合った\nオリジナルの挨拶が完成"
                    )
                }
                .padding(.horizontal, 24)

                // サンプル挨拶
                sampleGreetingPreview
                    .padding(.horizontal, 24)
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Tutorial Components

    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(
                    Circle().fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.glassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.glassBorder, lineWidth: 1)
        )
    }

    private func tutorialStepRow(number: Int, icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 52, height: 52)
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                    Text("STEP \(number)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(color.opacity(0.8))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineSpacing(2)
            }

            Spacer()
        }
    }

    private var sampleChatPreview: some View {
        VStack(spacing: 10) {
            Text("例: こんな返信を提案")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))

            VStack(spacing: 8) {
                // 相手のメッセージ
                HStack {
                    Text("今日ありがとう！楽しかった")
                        .font(.caption)
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    Spacer()
                }

                // AI提案
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8))
                            Text("PRINZ")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.neonCyan)

                        Text("こちらこそ！次はどこ行く？")
                            .font(.caption)
                            .padding(10)
                            .background(
                                LinearGradient(
                                    colors: [.neonPurple.opacity(0.4), .neonCyan.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
            }
            .foregroundColor(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.glassBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.glassBorder, lineWidth: 1)
            )
        }
    }

    private var sampleGreetingPreview: some View {
        VStack(spacing: 10) {
            Text("例: こんな挨拶を提案")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))

            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8))
                            Text("PRINZ")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.neonCyan)

                        Text("はじめまして！カフェ巡りが\n好きなんですね。最近行った\nおすすめのお店ありますか？")
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                            .padding(10)
                            .background(
                                LinearGradient(
                                    colors: [.orange.opacity(0.4), .pink.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
            }
            .foregroundColor(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.glassBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.glassBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.magicPink : Color.white.opacity(0.2))
                    .frame(width: index == currentStep ? 24 : 8, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - Step 1: Gender

    private var genderStep: some View {
        ScrollView {
            VStack(spacing: 30) {
                stepHeader(
                    icon: "person.fill",
                    title: "性別を教えてください",
                    subtitle: "あなたに合った言葉遣いで返信を提案します"
                )

                VStack(spacing: 12) {
                    ForEach(genderOptions, id: \.self) { option in
                        selectionButton(
                            title: option,
                            isSelected: selectedGender == option
                        ) {
                            selectedGender = option
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Step 2: Age

    private var ageStep: some View {
        ScrollView {
            VStack(spacing: 30) {
                stepHeader(
                    icon: "calendar",
                    title: "年代を教えてください",
                    subtitle: "年代に合った自然な表現を選びます"
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(UserAgeGroup.allCases, id: \.self) { group in
                        selectionButton(
                            title: group.displayName,
                            isSelected: selectedAgeGroup == group
                        ) {
                            selectedAgeGroup = group
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Step 3: Personal Type

    private var personalTypeStep: some View {
        ScrollView {
            VStack(spacing: 30) {
                stepHeader(
                    icon: "sparkles",
                    title: "あなたのタイプは？",
                    subtitle: "AIがあなたらしい返信を提案します"
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(PersonalType.allCases, id: \.self) { type in
                        Button(action: {
                            selectedPersonalType = type
                        }) {
                            HStack(spacing: 6) {
                                Text(type.emoji)
                                    .font(.caption)
                                Text(type.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(selectedPersonalType == type ? .white : .white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedPersonalType == type ? Color.magicPink : Color.glassBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedPersonalType == type ? Color.magicPink : Color.glassBorder, lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)

                // 選択中のタイプ説明
                if let type = selectedPersonalType {
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Shared Components

    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.magicPurple, .magicPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .magicPink.opacity(0.5), radius: 20)

            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func selectionButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? Color.magicPurple : Color.glassBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.magicPurple : Color.glassBorder, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Bottom Button

    private var canProceed: Bool {
        switch currentStep {
        case 0, 1, 2: return true  // チュートリアルは常に進める
        case 3: return selectedGender != nil
        case 4: return selectedAgeGroup != nil
        case 5: return selectedPersonalType != nil
        default: return false
        }
    }

    private var isLastStep: Bool {
        currentStep == totalSteps - 1
    }

    private var bottomButton: some View {
        Button(action: {
            if !isLastStep {
                currentStep += 1
            } else {
                completeOnboarding()
            }
        }) {
            Text(isLastStep ? "はじめる" : "次へ")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            canProceed
                                ? LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                        )
                )
        }
        .disabled(!canProceed)
    }

    // MARK: - Save

    private func completeOnboarding() {
        if let gender = selectedGender {
            userGenderRaw = gender
        }
        if let ageGroup = selectedAgeGroup {
            userAge = ageForGroup(ageGroup)
        }
        if let type = selectedPersonalType {
            personalTypeRaw = type.rawValue
        }
        hasCompletedOnboarding = true
    }

    private func ageForGroup(_ group: UserAgeGroup) -> Double {
        switch group {
        case .teens: return 18
        case .early20s: return 22
        case .late20s: return 27
        case .thirties: return 35
        case .forties: return 45
        case .fifties: return 55
        }
    }
}

#Preview {
    OnboardingView()
        .preferredColorScheme(.dark)
}
