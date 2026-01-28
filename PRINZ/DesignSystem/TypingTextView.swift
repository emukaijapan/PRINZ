//
//  TypingTextView.swift
//  PRINZ
//
//  タイピングアニメーション - 1文字ずつ表示でライブ感を演出
//

import SwiftUI

struct TypingTextView: View {
    let fullText: String
    let typingSpeed: Double
    let onComplete: (() -> Void)?
    
    @State private var displayedText = ""
    @State private var isComplete = false
    
    init(fullText: String, typingSpeed: Double = 0.03, onComplete: (() -> Void)? = nil) {
        self.fullText = fullText
        self.typingSpeed = typingSpeed
        self.onComplete = onComplete
    }
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                startTyping()
            }
            .onChange(of: fullText) { newText in
                // テキストが変わったらリセットして再開
                displayedText = ""
                isComplete = false
                startTyping()
            }
    }
    
    private func startTyping() {
        guard !isComplete else { return }
        
        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * typingSpeed) {
                if index < fullText.count {
                    displayedText.append(character)
                    
                    // 完了チェック
                    if displayedText.count == fullText.count {
                        isComplete = true
                        onComplete?()
                    }
                }
            }
        }
    }
}

// MARK: - カーソル付きタイピングビュー

struct TypingTextViewWithCursor: View {
    let fullText: String
    let typingSpeed: Double
    let onComplete: (() -> Void)?
    
    @State private var displayedText = ""
    @State private var showCursor = true
    @State private var isComplete = false
    
    init(fullText: String, typingSpeed: Double = 0.03, onComplete: (() -> Void)? = nil) {
        self.fullText = fullText
        self.typingSpeed = typingSpeed
        self.onComplete = onComplete
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(displayedText)
            
            // ブリンクカーソル（タイピング中のみ）
            if !isComplete {
                Text("|")
                    .opacity(showCursor ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showCursor)
            }
        }
        .onAppear {
            showCursor = true
            startTyping()
        }
        .onChange(of: fullText) { _ in
            displayedText = ""
            isComplete = false
            startTyping()
        }
    }
    
    private func startTyping() {
        guard !isComplete else { return }
        
        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * typingSpeed) {
                if index < fullText.count {
                    displayedText.append(character)
                    
                    if displayedText.count == fullText.count {
                        isComplete = true
                        onComplete?()
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TypingTextView(fullText: "今日も楽しかったね！また遊ぼう😊")
            .font(.body)
            .foregroundColor(.white)
        
        TypingTextViewWithCursor(fullText: "AIが返信を考えています...")
            .font(.headline)
            .foregroundColor(.neonCyan)
    }
    .padding()
    .background(Color.black)
}
