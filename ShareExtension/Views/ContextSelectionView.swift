//
//  ContextSelectionView.swift
//  ShareExtension
//
//  Created on 2026-01-11.
//

import SwiftUI

struct ContextSelectionView: View {
    let onSelect: (Context) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // タイトル
            VStack(spacing: 8) {
                Text("状況を選択")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("どんなシチュエーションですか？")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // コンテキストボタン - 2列グリッド
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Context.allCases, id: \.self) { context in
                    Button(action: {
                        onSelect(context)
                    }) {
                        VStack(spacing: 8) {
                            Text(context.emoji)
                                .font(.title)
                            
                            Text(context.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.glassBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.neonPurple.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
    }
}

#Preview {
    ZStack {
        Color.darkBackground.ignoresSafeArea()
        ContextSelectionView(onSelect: { _ in })
    }
}
