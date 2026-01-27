//
//  ReplyCustomizeView.swift
//  PRINZ
//
//  Created on 2026-01-12.
//

import SwiftUI

struct ReplyCustomizeView: View {
    let reply: Reply
    let context: Context
    
    @Environment(\.dismiss) private var dismiss
    @State private var editedText: String
    @State private var selectedTones: Set<ToneTag> = []
    @State private var isCopied = false
    
    init(reply: Reply, context: Context) {
        self.reply = reply
        self.context = context
        self._editedText = State(initialValue: reply.text)
    }
    
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
                // 編集可能テキスト
                editableTextSection
                
                // トーンタグ選択
                toneTagSection
                
                Spacer()
                
                // 下部ボタン
                bottomButtons
            }
            .padding()
        }
        .navigationTitle("カスタマイズ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: copyText) {
                    HStack {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "コピー済み" : "コピー")
                    }
                    .foregroundColor(isCopied ? .green : .neonCyan)
                }
            }
        }
    }
    
    // MARK: - Editable Text
    
    private var editableTextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: {
                    editedText = ""
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("削除")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: copyText) {
                    HStack {
                        Text("コピー")
                        Image(systemName: "doc.on.doc")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
            
            TextEditor(text: $editedText)
                .frame(minHeight: 100)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                )
        }
    }
    
    // MARK: - Tone Tags
    
    private var toneTagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("別のトーンで返信を作成")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            // タググリッド
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(ToneTag.allCases, id: \.self) { tone in
                    ToneTagButton(
                        tone: tone,
                        isSelected: selectedTones.contains(tone)
                    ) {
                        if selectedTones.contains(tone) {
                            selectedTones.remove(tone)
                        } else {
                            selectedTones.insert(tone)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8)
        )
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        Button(action: regenerateWithTones) {
            HStack {
                Text("似たような返信をゲット")
                    .fontWeight(.bold)
                Text("✨")
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.black)
            )
        }
    }
    
    // MARK: - Actions
    
    private func copyText() {
        UIPasteboard.general.string = editedText
        isCopied = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }
    
    private func regenerateWithTones() {
        // トーンに基づいて再生成（将来実装）
        // 現在はモックのため、dismiss
        dismiss()
    }
}

// MARK: - Tone Tag Button

struct ToneTagButton: View {
    let tone: ToneTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(tone.emoji)
                    .font(.caption)
                Text(tone.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .black)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.black : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    NavigationStack {
        ReplyCustomizeView(
            reply: Reply(text: "楽しかった！また行こう！", type: .safe, context: .matchStart),
            context: .matchStart
        )
    }
}
