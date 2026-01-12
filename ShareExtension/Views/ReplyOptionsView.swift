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
        VStack(spacing: 24) {
            // タイトル
            VStack(spacing: 8) {
                Text("返信案")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("タップしてコピー")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // 返信案リスト
            VStack(spacing: 16) {
                ForEach(replies) { reply in
                    ReplyBubble(reply: reply) {
                        onCopy(reply)
                    }
                }
            }
            
            // 閉じるボタン
            Button("閉じる") {
                onClose()
            }
            .neonButtonStyle(color: .cyan, compact: true)
        }
        .padding()
    }
}

// MARK: - Reply Bubble (LINE風)

struct ReplyBubble: View {
    let reply: Reply
    let onTap: () -> Void
    
    @State private var isCopied = false
    
    var body: some View {
        Button(action: {
            isCopied = true
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // タイプバッジ
                HStack {
                    Text(reply.type.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(reply.type == .safe ? .neonCyan : .neonPurple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.glassBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            reply.type == .safe ? Color.neonCyan : Color.neonPurple,
                                            lineWidth: 1
                                        )
                                )
                        )
                    
                    Spacer()
                    
                    if isCopied {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("コピー済み")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
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
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        reply.type == .safe ? Color.neonCyan : Color.neonPurple,
                                        reply.type == .safe ? Color.neonCyan.opacity(0.3) : Color.neonPurple.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(
                color: (reply.type == .safe ? Color.neonCyan : Color.neonPurple).opacity(0.4),
                radius: 15,
                x: 0,
                y: 5
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
