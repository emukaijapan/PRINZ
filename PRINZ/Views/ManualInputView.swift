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
            
            VStack(spacing: 20) {
                // 説明テキスト
                Text("相手のメッセージを入力してください")
                    .font(.headline)
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.top, 20)
                
                // テキスト入力エリア
                TextEditor(text: $inputText)
                    .frame(minHeight: 150)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 5)
                    )
                    .padding(.horizontal)
                
                // コンテキスト選択
                VStack(alignment: .leading, spacing: 12) {
                    Text("状況を選択")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black.opacity(0.7))
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Context.allCases, id: \.self) { context in
                                ContextButton(
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
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    colors: [.neonPurple, .neonCyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
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

// MARK: - Context Button

struct ContextButton: View {
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
            .foregroundColor(isSelected ? .white : .black)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.neonPurple : Color.white)
                    .shadow(color: isSelected ? .neonPurple.opacity(0.4) : .black.opacity(0.1), radius: 5)
            )
        }
    }
}

#Preview {
    NavigationStack {
        ManualInputView()
    }
}
