//
//  ReviewRequestView.swift
//  PRINZ
//
//  カスタムレビュー依頼画面（テスト用: 3回、本番: 31回利用後に表示）
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

            // カード（白い吹き出し風）
            VStack(spacing: 20) {
                // ヘッダー
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.neonPurple, .neonCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("PRINZを気に入っていただけましたか？")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text("あなたのレビューが、PRINZをより良くする力になります")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                // レビュー例
                VStack(alignment: .leading, spacing: 6) {
                    Text("レビュー例")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("「返信に悩む時間が減った！AIの提案がちょうどいい感じで助かってます」")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.8))
                        .italic()
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
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
                        .padding(.vertical, 14)
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
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
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
