//
//  ScanningAnimationView.swift
//  ShareExtension
//
//  Created on 2026-01-11.
//

import SwiftUI

struct ScanningAnimationView: View {
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                // 外側のリング
                Circle()
                    .stroke(Color.neonPurple.opacity(0.3), lineWidth: 2)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .stroke(Color.neonCyan.opacity(0.3), lineWidth: 2)
                    .frame(width: 160, height: 160)
                
                // レーダースキャンライン
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            colors: [.neonPurple, .neonCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 2).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                
                // 中央のクラウンアイコン
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.neonPurple, .neonCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .neonPurple, radius: pulseAnimation ? 30 : 10)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
            }
            
            // テキスト
            VStack(spacing: 8) {
                Text("解析中...")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("魔法の鏡がメッセージを読み取っています")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            isAnimating = true
            pulseAnimation = true
        }
    }
}

#Preview {
    ZStack {
        Color.darkBackground.ignoresSafeArea()
        ScanningAnimationView()
    }
}
