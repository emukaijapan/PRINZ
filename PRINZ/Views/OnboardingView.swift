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
                    genderStep.tag(0)
                    ageStep.tag(1)
                    personalTypeStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)

                // ボタン
                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.magicPink : Color.white.opacity(0.2))
                    .frame(width: index == currentStep ? 28 : 8, height: 8)
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
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Bottom Button

    private var canProceed: Bool {
        switch currentStep {
        case 0: return selectedGender != nil
        case 1: return selectedAgeGroup != nil
        case 2: return selectedPersonalType != nil
        default: return false
        }
    }

    private var bottomButton: some View {
        Button(action: {
            if currentStep < 2 {
                currentStep += 1
            } else {
                completeOnboarding()
            }
        }) {
            Text(currentStep < 2 ? "次へ" : "はじめる")
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
