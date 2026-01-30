//
//  HomeView.swift
//  PRINZ
//
//  Created on 2026-01-12.
//

import SwiftUI
import PhotosUI

struct HomeView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showManualInput = false
    @State private var showToneSelection = false
    @State private var showReplyResult = false
    @State private var isProcessing = false
    @State private var extractedText = ""
    @State private var selectedTone: ReplyType = .safe
    @State private var selectedContext: Context = .matchStart
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 魔法のグラデーション背景
                MagicBackground()
                
                VStack(spacing: 0) {
                    // ヘッダー
                    headerView
                    
                    // メインコンテンツ
                    ScrollView {
                        VStack(spacing: 24) {
                            // キャッチコピー
                            catchCopyView
                            
                            // サンプルプレビュー（LINE会話成功イメージ）
                            samplePreviewView
                            
                            Spacer(minLength: 100)
                        }
                        .padding()
                    }
                    
                    // 下部固定ボタン
                    bottomButtonsView
                }
            }
            .navigationDestination(isPresented: $showManualInput) {
                ManualInputView()
            }
            .navigationDestination(isPresented: $showReplyResult) {
                ReplyResultView(
                    image: selectedImage,
                    extractedText: extractedText,
                    context: selectedContext
                )
            }
            .fullScreenCover(isPresented: $showToneSelection) {
                ToneSelectionSheet(
                    selectedTone: $selectedTone,
                    onSelect: { _ in
                        showToneSelection = false
                        showReplyResult = true
                    }
                )
            }
            .onChange(of: selectedItem) { _, newItem in
                handleImageSelection(newItem)
            }
            .onChange(of: showReplyResult) { _, isShowing in
                // 結果画面から戻ったら写真をリセット
                if !isShowing {
                    resetState()
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // ロゴ
            HStack(spacing: 4) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.neonPurple, .neonCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .neonPurple.opacity(0.5), radius: 10)
                
                Text("PRINZ")
                    .font(.title)
                    .fontWeight(.black)
                    .italic()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.neonPurple, .neonCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Catch Copy（キャッチコピー）
    
    private var catchCopyView: some View {
        VStack(spacing: 12) {
            // メインキャッチコピー
            Text("既読のまま、")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("終わらせない。")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.neonPurple, .neonCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // 説明文
            Text("スクショをアップするだけ\n最適な返信をAIが提案します")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 30)
    }
    
    // MARK: - Sample Preview（LINE会話成功イメージ）
    
    private var samplePreviewView: some View {
        ZStack {
            // ガラスカード
            GlassCard(glowColor: .neonPurple) {
                VStack(spacing: 16) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    } else {
                        // LINE会話サンプル表示
                        VStack(spacing: 12) {
                            // サンプル会話
                            HStack {
                                Spacer()
                                Text("今日ありがとう！楽しかった😊")
                                    .font(.subheadline)
                                    .padding(12)
                                    .background(Color.neonPurple.opacity(0.3))
                                    .cornerRadius(16)
                            }
                            
                            HStack {
                                Text("こちらこそ！\nまた行こうね✨")
                                    .font(.subheadline)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(16)
                                Spacer()
                            }
                            
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("👑 PRINZが提案")
                                        .font(.caption2)
                                        .foregroundColor(.neonCyan)
                                    Text("来週の土曜、空いてる？")
                                        .font(.subheadline)
                                        .padding(12)
                                        .background(
                                            LinearGradient(
                                                colors: [.neonPurple.opacity(0.5), .neonCyan.opacity(0.3)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                    }
                }
            }
            .frame(height: 280)
        }
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtonsView: some View {
        VStack(spacing: 12) {
            // メインボタン: スクショをアップ
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("スクショをアップ")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
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
                .shadow(color: .neonPurple.opacity(0.5), radius: 10)
            }
            .disabled(isProcessing)
            
            // サブボタン: 手動で入力のみ
            Button(action: {
                showManualInput = true
            }) {
                HStack {
                    Image(systemName: "keyboard")
                    Text("手動で入力")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.glassBorder, lineWidth: 1)
                        )
                )
            }
        }
        .padding()
        .background(
            Color.darkBackground
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Image Selection Handler
    
    private func handleImageSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        isProcessing = true
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                    performOCR(on: image)
                }
            } else {
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
    
    private func performOCR(on image: UIImage) {
        OCRService.shared.recognizeText(from: image) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success(let text):
                    extractedText = text
                    // トーン選択モーダルを表示
                    showToneSelection = true
                case .failure(let error):
                    print("OCR Error: \(error)")
                    extractedText = ""
                    showToneSelection = true
                }
            }
        }
    }
    
    /// 画面リセット
    func resetState() {
        selectedItem = nil
        selectedImage = nil
        extractedText = ""
        selectedTone = .safe
        selectedContext = .matchStart
    }
}

// MARK: - Tone Selection Sheet (選択=即座に生成開始)

struct ToneSelectionSheet: View {
    @Binding var selectedTone: ReplyType
    let onSelect: (ReplyType) -> Void  // 選択時のコールバック
    
    private let toneOptions: [(type: ReplyType, emoji: String, description: String)] = [
        (.safe, "💛", "無難で安心な返信"),
        (.chill, "💜", "少し踏み込んだ返信"),
        (.witty, "💙", "意外性のある返信")
    ]
    
    var body: some View {
        ZStack {
            Color.magicGradient.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // タイトル
                VStack(spacing: 8) {
                    Text("どんな雰囲気で返信する？")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("タップで回答生成を開始")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 30)
                
                // トーン選択ボタン（タップで即座に遷移）
                VStack(spacing: 16) {
                    ForEach(toneOptions, id: \.type) { option in
                        Button(action: {
                            selectedTone = option.type
                            onSelect(option.type)
                        }) {
                            HStack(spacing: 16) {
                                Text(option.emoji)
                                    .font(.largeTitle)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.type.displayName)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Text(option.description)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.glassBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.glassBorder, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

#Preview {
    HomeView()
}
