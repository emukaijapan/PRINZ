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
    
    @State private var generatedReplies: [Reply] = []
    @State private var focusKeyword = ""
    @State private var selectedReply: Reply?
    @State private var showCustomize = false
    @State private var copiedReplyId: UUID?
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [
                    Color(hex: "#E8E0F0"),
                    Color(hex: "#F0F8FF")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 画像またはテキストプレビュー
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 5)
                    } else if !extractedText.isEmpty {
                        textPreviewView
                    }
                    
                    // フォーカスキーワード入力
                    focusKeywordInput
                    
                    // AI回答セクション
                    aiAnswerSection
                    
                    // 返信案リスト
                    repliesListView
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            
            // 下部ボタン
            VStack {
                Spacer()
                bottomButton
            }
        }
        .navigationTitle("AI回答")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showCustomize) {
            if let reply = selectedReply {
                ReplyCustomizeView(reply: reply, context: context)
            }
        }
        .onAppear {
            generateReplies()
        }
    }
    
    // MARK: - Text Preview
    
    private var textPreviewView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("抽出テキスト")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(extractedText)
                .font(.body)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                )
        }
    }
    
    // MARK: - Focus Keyword
    
    private var focusKeywordInput: some View {
        HStack {
            Image(systemName: "text.magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("フォーカスする言葉を教えて", text: $focusKeyword)
                .font(.body)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 3)
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
    
    // MARK: - Replies List
    
    private var repliesListView: some View {
        VStack(spacing: 12) {
            ForEach(generatedReplies) { reply in
                ReplyBubbleCard(
                    reply: reply,
                    isCopied: copiedReplyId == reply.id,
                    onTap: {
                        copyReply(reply)
                    },
                    onCustomize: {
                        selectedReply = reply
                        showCustomize = true
                    }
                )
            }
        }
    }
    
    // MARK: - Bottom Button
    
    private var bottomButton: some View {
        Button(action: {
            // 大人な返信を取得（将来実装）
        }) {
            HStack {
                Text("😈")
                Text("ちょっと大人な返信をゲット")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 10)
            )
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func generateReplies() {
        generatedReplies = ReplyGenerator.shared.generateReplies(
            for: extractedText,
            context: context
        )
    }
    
    private func copyReply(_ reply: Reply) {
        UIPasteboard.general.string = reply.text
        copiedReplyId = reply.id
        
        // 履歴に保存
        DataManager.shared.saveReply(reply)
        
        // 少し後にリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedReplyId == reply.id {
                copiedReplyId = nil
            }
        }
    }
}

// MARK: - Reply Bubble Card

struct ReplyBubbleCard: View {
    let reply: Reply
    let isCopied: Bool
    let onTap: () -> Void
    let onCustomize: () -> Void
    
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
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
            
            // カスタマイズボタン
            HStack {
                Spacer()
                Button(action: onCustomize) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("カスタマイズ")
                            .font(.caption)
                    }
                    .foregroundColor(.neonPurple)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.5))
                .shadow(color: .black.opacity(0.1), radius: 8)
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
        case .safe: return .blue
        case .chill: return .orange
        case .witty: return .purple
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
