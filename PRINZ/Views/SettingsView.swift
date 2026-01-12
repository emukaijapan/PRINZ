//
//  SettingsView.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("userAge") private var userAge: Double = 25
    @AppStorage("userGender") private var userGender: String = "未設定"
    
    private let genderOptions = ["男性", "女性", "その他", "未設定"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color.darkBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // ヘッダー
                        headerView
                        
                        // 年齢設定
                        ageSettingView
                        
                        // 性別設定
                        genderSettingView
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.neonPurple, .neonCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .neonPurple, radius: 20)
            
            Text("PRINZ")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.neonPurple, .neonCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.top, 20)
    }
    
    // MARK: - Age Setting
    
    private var ageSettingView: some View {
        GlassCard(glowColor: .neonPurple) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("年齢")
                        .font(.headline)
                        .foregroundColor(.neonPurple)
                    
                    Spacer()
                    
                    Text("\(Int(userAge))歳")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.neonCyan)
                }
                
                // カスタムスライダー
                VStack(spacing: 8) {
                    Slider(value: $userAge, in: 18...60, step: 1)
                        .accentColor(.neonPurple)
                    
                    HStack {
                        Text("18")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Text("60")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
    }
    
    // MARK: - Gender Setting
    
    private var genderSettingView: some View {
        GlassCard(glowColor: .neonCyan) {
            VStack(alignment: .leading, spacing: 16) {
                Text("性別")
                    .font(.headline)
                    .foregroundColor(.neonCyan)
                
                // ゲーミング風ボタングリッド
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(genderOptions, id: \.self) { option in
                        Button(action: {
                            userGender = option
                        }) {
                            Text(option)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(userGender == option ? .neonCyan : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(userGender == option ? Color.glassBackground : Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    userGender == option ? Color.neonCyan : Color.glassBorder,
                                                    lineWidth: userGender == option ? 2 : 1
                                                )
                                        )
                                )
                                .shadow(
                                    color: userGender == option ? Color.neonCyan.opacity(0.5) : .clear,
                                    radius: 10
                                )
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
