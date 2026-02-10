//
//  ReviewRequestView.swift
//  PRINZ
//
//  カスタムレビュー依頼画面（31回利用後に表示）
//

import SwiftUI

struct ReviewRequestView: View {
    @Binding var isPresented: Bool

    // URLを開く（Share Extension対応）
    @Environment(\.openURL) private var openURL

    // App Store App ID（App Store Connectで確認）
    private let appStoreId = "6740875498"  // TODO: 実際のApp IDに変更

    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // カード
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.neonPurple, .neonCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .neonPurple.opacity(0.5), radius: 10)

                    Text("PRINZを気に入っていただけましたか？")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("あなたのレビューが、PRINZをより良くする力になります")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                // レビュー例（控えめに）
                VStack(alignment: .leading, spacing: 8) {
                    Text("レビュー例")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))

                    Text("「返信に悩む時間が減った！AIの提案がちょうどいい感じで助かってます」")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .italic()
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // ボタン
                VStack(spacing: 12) {
                    // レビューを書くボタン
                    Button(action: openAppStoreReview) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("レビューを書く")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.neonPurple, .neonCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                    }

                    // 後でボタン
                    Button(action: { isPresented = false }) {
                        Text("また今度")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.glassBorder, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Actions

    private func openAppStoreReview() {
        // App Storeのレビュー画面（コメント入力可能）を開く
        let urlString = "https://apps.apple.com/app/id\(appStoreId)?action=write-review"
        if let url = URL(string: urlString) {
            openURL(url)
        }
        isPresented = false
    }
}

#Preview {
    ReviewRequestView(isPresented: .constant(true))
}
