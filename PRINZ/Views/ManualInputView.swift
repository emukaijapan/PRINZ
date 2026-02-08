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
    @State private var selectedMode: GenerationMode = .chatReply
    @State private var showResults = false

    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        ZStack {
            // 魔法のグラデーション背景
            MagicBackground()

            VStack(spacing: 20) {
                // モード切り替え
                modeSelectorView

                // 説明テキスト
                VStack(spacing: 8) {
                    Text(selectedMode == .chatReply ? "相手のメッセージを入力" : "相手のプロフィールを入力")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(selectedMode == .chatReply
                         ? "返信したい相手のメッセージを貼り付けてね"
                         : "プロフィールの内容をコピペしてね")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }

                // テキスト入力エリア
                TextEditor(text: $inputText)
                    .focused($isTextEditorFocused)
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

                Spacer()

                // 生成ボタン
                Button(action: {
                    showResults = true
                }) {
                    HStack {
                        Image(systemName: selectedMode == .chatReply ? "sparkles" : "hand.wave")
                        Text(selectedMode == .chatReply ? "チャットの返信を作成" : "あいさつメッセージを作成")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: selectedMode == .chatReply
                                ? [.magicPurple, .magicPink]
                                : [.orange, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: (selectedMode == .chatReply ? Color.magicPink : Color.orange).opacity(0.4), radius: 10)
                }
                .disabled(inputText.isEmpty)
                .opacity(inputText.isEmpty ? 0.5 : 1.0)
                .padding()
            }
        }
        .navigationTitle("テキスト入力")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    isTextEditorFocused = false
                }
                .foregroundColor(.neonCyan)
            }
        }
        .navigationDestination(isPresented: $showResults) {
            ReplyResultView(
                image: nil,
                extractedText: inputText,
                context: selectedMode == .chatReply ? selectedContext : .matchStart,
                mode: selectedMode
            )
        }
    }

    // MARK: - Mode Selector

    private var modeSelectorView: some View {
        HStack(spacing: 0) {
            modeTab("チャット返信", mode: .chatReply)
            modeTab("あいさつ作成", mode: .profileGreeting)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.glassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.glassBorder, lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private func modeTab(_ title: String, mode: GenerationMode) -> some View {
        let isSelected = selectedMode == mode
        let accentColor: Color = mode == .chatReply ? .neonPurple : .orange

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedMode = mode
            }
        }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? accentColor.opacity(0.5) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? accentColor : Color.clear, lineWidth: 1.5)
                )
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Context Tag Button

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
            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.magicPink : Color.glassBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.magicPink : Color.glassBorder, lineWidth: 1)
            )
        }
    }
}

#Preview {
    NavigationStack {
        ManualInputView()
    }
}
