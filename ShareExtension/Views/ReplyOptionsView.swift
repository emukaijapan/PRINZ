//
//  ReplyOptionsView.swift
//  ShareExtension
//
//  Created on 2026-01-11.
//

import SwiftUI

struct ReplyOptionsView: View {
    let replies: [Reply]
    let onCopy: (Reply) -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // タイトル
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.neonCyan)
                    Text("AI返信案")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text("タップしてコピー")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // 返信案リスト
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(replies) { reply in
                        ReplyBubble(reply: reply) {
                            onCopy(reply)
                        }
                    }
                }
            }
            
            // 閉じるボタン
            Button(action: onClose) {
                Text("閉じる")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.glassBorder, lineWidth: 1)
                            )
                    )
            }
        }
        .padding()
    }
}

// MARK: - Reply Bubble (シンプル版)

struct ReplyBubble: View {
    let reply: Reply
    let onTap: () -> Void
    
    @State private var isCopied = false
    
    private var typeColor: Color {
        switch reply.type {
        case .safe: return .neonCyan
        case .chill: return .orange
        case .witty: return .neonPurple
        }
    }
    
    private var typeIcon: String {
        switch reply.type {
        case .safe: return "shield.fill"
        case .chill: return "flame.fill"
        case .witty: return "sparkles"
        }
    }
    
    var body: some View {
        Button(action: {
            isCopied = true
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // タイプバッジ
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: typeIcon)
                            .font(.caption)
                        Text(reply.type.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(typeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(typeColor.opacity(0.15))
                    )
                    
                    Spacer()
                    
                    if isCopied {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("コピー済み")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                }
                
                // 返信テキスト
                Text(reply.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(typeColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.darkBackground.ignoresSafeArea()
        
        ReplyOptionsView(
            replies: [
                Reply(text: "楽しかった！また行こう！", type: .safe, context: .matchStart),
                Reply(text: "おつー、今度は飲みね🍻", type: .chill, context: .matchStart),
                Reply(text: "逆にいつ空いてるの？笑", type: .witty, context: .matchStart)
            ],
            onCopy: { _ in },
            onClose: {}
        )
    }
}

