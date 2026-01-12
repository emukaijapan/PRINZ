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
            
            // コンテキストボタン
            VStack(spacing: 16) {
                ForEach(Context.allCases, id: \.self) { context in
                    Button(action: {
                        onSelect(context)
                    }) {
                        HStack(spacing: 12) {
                            Text(context.emoji)
                                .font(.title)
                            
                            Text(context.displayName)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    .neonButtonStyle(color: .purple)
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
