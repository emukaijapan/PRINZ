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

    // App Store App ID
    private let appStoreId = "6740875498"

    // レビュー例のパターン
    private let reviewExamples = [
        "返信に悩む時間が減った！\nAIの提案がちょうどいい感じで助かってます",
        "マッチングアプリで会話が続くようになった！\n返信のバリエーションが増えて楽しい",
        "既読スルーされがちだったけど、\nこのアプリ使ってから返信率アップ！"
    ]

    @State private var currentExampleIndex = 0

    var body: some View {
        ZStack {
            // 背景（タップで閉じる）
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // カード
            VStack(spacing: 16) {
                // 閉じるボタン
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }

                // ヘッダー
                VStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.neonPurple, .neonCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("PRINZを\n気に入っていただけましたか？")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("あなたのレビューが\nPRINZをより良くする力になります")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }

                // レビュー例（複数パターン）
                VStack(spacing: 8) {
                    Text("レビュー例")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TabView(selection: $currentExampleIndex) {
                        ForEach(0..<reviewExamples.count, id: \.self) { index in
                            Text("「\(reviewExamples[index])」")
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.8))
                                .italic()
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.08))
                                )
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: 100)

                    // ページインジケーター
                    HStack(spacing: 6) {
                        ForEach(0..<reviewExamples.count, id: \.self) { index in
                            Circle()
                                .fill(currentExampleIndex == index ? Color.neonPurple : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }

                // ボタン
                VStack(spacing: 10) {
                    // レビューを書くボタン
                    Button(action: openAppStoreReview) {
                        HStack(spacing: 8) {
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
                    .padding(.top, 4)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 28)
        }
        .onAppear {
            // 表示するたびにランダムな例から開始
            currentExampleIndex = Int.random(in: 0..<reviewExamples.count)
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
