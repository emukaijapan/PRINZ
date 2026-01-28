//
//  SkeletonLoaderView.swift
//  PRINZ
//
//  スケルトンローダー - AIが生成中であることを視覚的に伝える
//

import SwiftUI

struct SkeletonLoaderView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: 8) {
                    // バッジ部分
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 20)
                    
                    Spacer()
                }
                
                // テキスト部分（複数行）
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)
                        .shimmerEffect(isAnimating: isAnimating, delay: Double(index) * 0.2)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: UIScreen.main.bounds.width * 0.6, height: 16)
                        .shimmerEffect(isAnimating: isAnimating, delay: Double(index) * 0.2 + 0.1)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.glassBackground)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - シマーエフェクト

extension View {
    func shimmerEffect(isAnimating: Bool, delay: Double = 0) -> some View {
        self
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(delay),
                        value: isAnimating
                    )
                }
            )
            .mask(self)
    }
}

#Preview {
    ZStack {
        Color.black
        SkeletonLoaderView()
            .padding()
    }
}
