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
    @State private var showReplyResult = false
    @State private var isProcessing = false
    @State private var extractedText = ""
    @State private var selectedContext: Context = .matchStart
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景グラデーション（RIZZ風の淡いグラデーション）
                LinearGradient(
                    colors: [
                        Color(hex: "#E8E0F0"),
                        Color(hex: "#F0F8FF"),
                        Color(hex: "#E0F0E8")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // ヘッダー
                    headerView
                    
                    // メインコンテンツ
                    ScrollView {
                        VStack(spacing: 24) {
                            // キャッチコピー
                            catchCopyView
                            
                            // サンプルプレビュー
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
            .onChange(of: selectedItem) { _, newItem in
                handleImageSelection(newItem)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(.black.opacity(0.6))
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
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.neonCyan)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Catch Copy
    
    private var catchCopyView: some View {
        VStack(spacing: 8) {
            Text("スクショをアップ")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text("チャットやバイオの")
                .font(.title3)
                .foregroundColor(.black.opacity(0.7))
        }
        .padding(.top, 20)
    }
    
    // MARK: - Sample Preview
    
    private var samplePreviewView: some View {
        ZStack {
            // サンプル画像のプレースホルダー
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.5))
                .frame(height: 300)
                .overlay(
                    VStack(spacing: 16) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .padding()
                        } else {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("スクリーンショットをアップロード")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
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
                            .tint(.white)
                    } else {
                        Text("スクショをアップ")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.black)
                )
            }
            .disabled(isProcessing)
            
            // サブボタン
            HStack(spacing: 12) {
                Button(action: {
                    showManualInput = true
                }) {
                    Text("手動で入力")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 5)
                        )
                }
                
                Button(action: {
                    // ピックアップライン機能（将来実装）
                }) {
                    Text("ピックアップラインをゲット")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 5)
                        )
                }
            }
        }
        .padding()
        .background(
            Color.white.opacity(0.9)
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
                    showReplyResult = true
                case .failure(let error):
                    print("OCR Error: \(error)")
                    // エラーでも結果画面へ遷移（テキストなしで）
                    extractedText = ""
                    showReplyResult = true
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
