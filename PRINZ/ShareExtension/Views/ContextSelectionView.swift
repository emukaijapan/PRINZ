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
        VStack(spacing: 20) {
            // タイトル
            VStack(spacing: 6) {
                Text("状況を選択")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("どんなシチュエーションですか？")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // コンテキストボタン - コンパクトな縦リスト
            VStack(spacing: 8) {
                ForEach(Context.allCases, id: \.self) { context in
                    Button(action: {
                        onSelect(context)
                    }) {
                        HStack(spacing: 10) {
                            Text(context.emoji)
                                .font(.body)
                            
                            Text(context.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.glassBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.neonPurple.opacity(0.3), lineWidth: 1)
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

