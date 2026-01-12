//
//  ManualInputView.swift
//  PRINZ
//
//  Created on 2026-01-12.
//

import SwiftUI

struct ManualInputView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @State private var selectedContext: Context = .matchStart
    @State private var showResults = false
    
    var body: some View {
        ZStack {
            // ダークテーマ背景
            Color.darkBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 説明テキスト
                VStack(spacing: 8) {
                    Text("相手のメッセージを入力")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("返信したい相手のメッセージを貼り付けてね")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 20)
                
                // テキスト入力エリア
                TextEditor(text: $inputText)
                    .frame(minHeight: 150)
                    .padding()
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.glassBorder, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                
                // コンテキスト選択
                VStack(alignment: .leading, spacing: 12) {
                    Text("状況を選択")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Context.allCases, id: \.self) { context in
                                ContextTagButton(
                                    context: context,
                                    isSelected: selectedContext == context
                                ) {
                                    selectedContext = context
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // 生成ボタン
                Button(action: {
                    showResults = true
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("PRINZのAI回答")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.neonPurple, .neonCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: .neonPurple.opacity(0.4), radius: 10)
                }
                .disabled(inputText.isEmpty)
                .opacity(inputText.isEmpty ? 0.5 : 1.0)
                .padding()
            }
        }
        .navigationTitle("手動入力")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showResults) {
            ReplyResultView(
                image: nil,
                extractedText: inputText,
                context: selectedContext
            )
        }
    }
}

// MARK: - Context Tag Button（ダークテーマ対応）

struct ContextTagButton: View {
    let context: Context
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(context.emoji)
                Text(context.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.neonCyan : Color.glassBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.neonCyan : Color.glassBorder, lineWidth: 1)
            )
        }
    }
}

#Preview {
    NavigationStack {
        ManualInputView()
    }
}
