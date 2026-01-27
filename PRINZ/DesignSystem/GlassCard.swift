//
//  GlassCard.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    let glowColor: Color
    
    init(glowColor: Color = .neonPurple, @ViewBuilder content: () -> Content) {
        self.glowColor = glowColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                ZStack {
                    // ガラス効果
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    
                    // グラデーションオーバーレイ
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.glassBackground,
                                    Color.glassBackground.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // ボーダー
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.glassBorder, lineWidth: 1)
                }
            )
            .shadow(color: glowColor.opacity(0.3), radius: 15, x: 0, y: 5)
    }
}

#Preview {
    ZStack {
        Color.darkBackground.ignoresSafeArea()
        
        VStack(spacing: 20) {
            GlassCard(glowColor: .neonPurple) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("サンプルカード")
                        .font(.headline)
                        .foregroundColor(.neonPurple)
                    Text("これはガラスモーフィズムのカードです")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            GlassCard(glowColor: .neonCyan) {
                Text("シアンカラー")
                    .foregroundColor(.neonCyan)
            }
        }
        .padding()
    }
}
