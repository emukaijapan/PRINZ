//
//  SettingsView.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("userAge", store: UserDefaults(suiteName: "group.com.mgolworks.prinz"))
    private var userAge: Double = 25
    @AppStorage("userGender", store: UserDefaults(suiteName: "group.com.mgolworks.prinz"))
    private var userGender: String = "男性"
    @AppStorage("personalType", store: UserDefaults(suiteName: "group.com.mgolworks.prinz"))
    private var personalTypeRaw: String = PersonalType.natural.rawValue

    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    @State private var shareExtensionLogs: [String] = []
    @State private var showDebugLogs = false

    private var personalType: PersonalType {
        PersonalType(rawValue: personalTypeRaw) ?? .natural
    }

    private var selectedAgeGroup: UserAgeGroup {
        UserAgeGroup.from(age: Int(userAge))
    }

    private let genderOptions = ["男性", "女性", "その他"]

    var body: some View {
        NavigationView {
            ZStack {
                // 魔法のグラデーション背景
                MagicBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // ヘッダー
                        headerView

                        // プレミアムプラン
                        premiumSectionView

                        // パーソナルタイプ設定
                        personalTypeSettingView

                        // 年齢設定
                        ageSettingView

                        // 性別設定
                        genderSettingView

                        // デバッグ用：Share Extensionログ
                        #if DEBUG
                        debugLogsSection
                        #endif

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Premium Section

    private var premiumSectionView: some View {
        GlassCard(glowColor: .neonCyan) {
            if subscriptionManager.isProUser {
                // プレミアム会員
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.neonPurple, .neonCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Premium")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("プレミアム会員")
                            .font(.caption)
                            .foregroundColor(.neonCyan)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.neonCyan)
                }
            } else {
                // 無料会員 → アップグレード誘導
                Button(action: { showPaywall = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.5))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Premium")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("プレミアムにアップグレード")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.magicPurple, .magicPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .magicPink, radius: 20)
            
            Text("あなたのタイプを設定")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("AIがあなたらしい返信を提案します")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.top, 10)
    }
    
    // MARK: - Personal Type Setting
    
    private var personalTypeSettingView: some View {
        GlassCard(glowColor: .magicPink) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("パーソナルタイプ")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(personalType.emoji) \(personalType.displayName)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.magicPink)
                }
                
                // タイプグリッド
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(PersonalType.allCases, id: \.self) { type in
                        Button(action: {
                            personalTypeRaw = type.rawValue
                        }) {
                            HStack(spacing: 6) {
                                Text(type.emoji)
                                    .font(.caption)
                                Text(type.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(personalType == type ? .white : .white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(personalType == type ? Color.magicPink : Color.glassBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(personalType == type ? Color.magicPink : Color.glassBorder, lineWidth: 1)
                            )
                        }
                    }
                }
                
                // 選択中のタイプの説明
                if let description = PersonalType(rawValue: personalTypeRaw)?.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 4)
                }
            }
        }
    }
    
    // MARK: - Age Setting
    
    private var ageSettingView: some View {
        GlassCard(glowColor: .neonCyan) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("年代")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text(selectedAgeGroup.displayName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.neonCyan)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(UserAgeGroup.allCases, id: \.self) { group in
                        Button(action: {
                            userAge = ageForGroup(group)
                        }) {
                            Text(group.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedAgeGroup == group ? .white : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedAgeGroup == group ? Color.neonCyan.opacity(0.6) : Color.glassBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedAgeGroup == group ? Color.neonCyan : Color.glassBorder, lineWidth: 1)
                                )
                                .contentShape(Rectangle())
                        }
                    }
                }
            }
        }
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
    
    // MARK: - Gender Setting
    
    private var genderSettingView: some View {
        GlassCard(glowColor: .magicPurple) {
            VStack(alignment: .leading, spacing: 16) {
                Text("性別")
                    .font(.headline)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(genderOptions, id: \.self) { option in
                        Button(action: {
                            userGender = option
                        }) {
                            Text(option)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(userGender == option ? .white : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(userGender == option ? Color.magicPurple : Color.glassBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(userGender == option ? Color.magicPurple : Color.glassBorder, lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Debug Logs Section

    #if DEBUG
    private var debugLogsSection: some View {
        GlassCard(glowColor: .orange) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "ant.fill")
                        .foregroundColor(.orange)
                    Text("デバッグ")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }

                Button(action: {
                    loadShareExtensionLogs()
                    showDebugLogs.toggle()
                }) {
                    HStack {
                        Text("Share Extension ログを表示")
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Image(systemName: showDebugLogs ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                if showDebugLogs {
                    VStack(alignment: .leading, spacing: 4) {
                        if shareExtensionLogs.isEmpty {
                            Text("ログがありません")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(shareExtensionLogs.reversed(), id: \.self) { log in
                                        Text(log)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                            .frame(maxHeight: 200)

                            Button(action: clearShareExtensionLogs) {
                                Text("ログをクリア")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private func loadShareExtensionLogs() {
        let logKey = "com.prinz.shareExtension.logs"
        if let defaults = UserDefaults(suiteName: "group.com.mgolworks.prinz") {
            shareExtensionLogs = defaults.stringArray(forKey: logKey) ?? []
        }
    }

    private func clearShareExtensionLogs() {
        let logKey = "com.prinz.shareExtension.logs"
        UserDefaults(suiteName: "group.com.mgolworks.prinz")?.removeObject(forKey: logKey)
        shareExtensionLogs = []
    }
    #endif
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
