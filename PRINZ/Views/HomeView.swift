//
//  HomeView.swift
//  PRINZ
//
//  Created on 2026-01-12.
//

import SwiftUI
import PhotosUI

struct HomeView: View {
    // チャット返信用
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showToneSelection = false
    @State private var showReplyResult = false
    @State private var isProcessing = false
    @State private var extractedText = ""
    @State private var selectedTone: ReplyType = .safe
    @State private var selectedContext: Context = .matchStart

    // プロフィール挨拶用
    @State private var profileSelectedItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var profileText = ""
    @State private var showProfileToneSelection = false
    @State private var showProfileResult = false
    @State private var profileTone: ReplyType = .safe
    @State private var isProfileProcessing = false

    // アプリ情報
    @State private var showAppInfo = false
    
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
            .navigationDestination(isPresented: $showReplyResult) {
                ReplyResultView(
                    image: selectedImage,
                    extractedText: extractedText,
                    context: selectedContext,
                    initialTone: selectedTone
                )
            }
            .navigationDestination(isPresented: $showProfileResult) {
                ReplyResultView(
                    image: profileImage,
                    extractedText: profileText,
                    context: .matchStart,
                    initialTone: profileTone,
                    mode: .profileGreeting
                )
            }
            .fullScreenCover(isPresented: $showToneSelection) {
                ToneSelectionSheet(
                    selectedTone: $selectedTone,
                    onSelect: { _ in
                        showToneSelection = false
                        showReplyResult = true
                    },
                    onCancel: {
                        showToneSelection = false
                        resetState()
                    }
                )
            }
            .fullScreenCover(isPresented: $showProfileToneSelection) {
                ToneSelectionSheet(
                    selectedTone: $profileTone,
                    onSelect: { _ in
                        showProfileToneSelection = false
                        showProfileResult = true
                    },
                    onCancel: {
                        showProfileToneSelection = false
                        resetProfileState()
                    }
                )
            }
            .onChange(of: selectedItem) { _, newItem in
                handleImageSelection(newItem)
            }
            .onChange(of: profileSelectedItem) { _, newItem in
                handleProfileImageSelection(newItem)
            }
            .onChange(of: showReplyResult) { _, isShowing in
                if !isShowing {
                    resetState()
                }
            }
            .onChange(of: showProfileResult) { _, isShowing in
                if !isShowing {
                    resetProfileState()
                }
            }
            .sheet(isPresented: $showAppInfo) {
                AppInfoSheet()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: { showAppInfo = true }) {
                Image(systemName: "info.circle")
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

            // 右側のスペーサー（左右対称のため）
            Color.clear
                .frame(width: 28, height: 28)
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
            // メインボタン: チャット返信を作成
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "bubble.left.and.text.bubble.right")
                        Text("チャットの返信を作成")
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
            .disabled(isProcessing || isProfileProcessing)

            // サブボタン: あいさつメッセージを作成
            PhotosPicker(selection: $profileSelectedItem, matching: .images) {
                HStack {
                    if isProfileProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "hand.wave")
                        Text("あいさつメッセージを作成")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
                .shadow(color: .orange.opacity(0.4), radius: 10)
            }
            .disabled(isProcessing || isProfileProcessing)
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
    
    /// チャット返信の状態リセット
    func resetState() {
        selectedItem = nil
        selectedImage = nil
        extractedText = ""
        selectedTone = .safe
        selectedContext = .matchStart
    }

    // MARK: - Profile Image Selection Handler

    private func handleProfileImageSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }

        isProfileProcessing = true

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    profileImage = image
                    performProfileOCR(on: image)
                }
            } else {
                await MainActor.run {
                    isProfileProcessing = false
                }
            }
        }
    }

    private func performProfileOCR(on image: UIImage) {
        OCRService.shared.recognizeText(from: image) { result in
            DispatchQueue.main.async {
                isProfileProcessing = false

                switch result {
                case .success(let text):
                    profileText = text
                    showProfileToneSelection = true
                case .failure(let error):
                    print("Profile OCR Error: \(error)")
                    profileText = ""
                    showProfileToneSelection = true
                }
            }
        }
    }

    /// プロフィール挨拶の状態リセット
    func resetProfileState() {
        profileSelectedItem = nil
        profileImage = nil
        profileText = ""
        profileTone = .safe
    }
}

// MARK: - Tone Selection Sheet (選択=即座に生成開始)

struct ToneSelectionSheet: View {
    @Binding var selectedTone: ReplyType
    let onSelect: (ReplyType) -> Void  // 選択時のコールバック
    var onCancel: (() -> Void)?  // キャンセル時のコールバック（オプション）

    private let toneOptions: [(type: ReplyType, icon: String, color: Color, description: String)] = [
        (.safe, "shield.fill", .cyan, "無難で安心な返信"),
        (.chill, "flame.fill", .orange, "少し踏み込んだ返信"),
        (.witty, "sparkles", .purple, "意外性のある返信")
    ]

    var body: some View {
        ZStack {
            Color.magicGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                // キャンセルボタン（右上）
                HStack {
                    Spacer()
                    Button(action: {
                        onCancel?()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)  // ノッチ/ダイナミックアイランド回避

                // タイトル
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("どんな雰囲気で返信する？")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("タップで回答生成を開始")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()
                    .frame(height: 20)

                // トーン選択ボタン（タップで即座に遷移）
                VStack(spacing: 16) {
                    ForEach(toneOptions, id: \.type) { option in
                        Button(action: {
                            selectedTone = option.type
                            onSelect(option.type)
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: option.icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(option.color)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(option.color.opacity(0.15))
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.type.displayName)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Text(option.description)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                }

                                Spacer()

                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)

                // キャンセルリンク（下部）
                Button(action: {
                    onCancel?()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("キャンセル")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 16)

                Spacer()
            }
        }
    }
}

// MARK: - App Info Sheet

struct AppInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "不明"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "不明"
    }

    private var osVersion: String {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
    }

    private var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return mapDeviceIdentifier(identifier)
    }

    /// デバイス識別子をモデル名に変換
    private func mapDeviceIdentifier(_ identifier: String) -> String {
        let mapping: [String: String] = [
            // iPhone 17 Series (2025)
            "iPhone18,1": "iPhone 17",
            "iPhone18,2": "iPhone 17 Plus",
            "iPhone18,3": "iPhone 17 Pro",
            "iPhone18,4": "iPhone 17 Pro Max",
            "iPhone18,5": "iPhone 17 Air",
            // iPhone 16 Series (2024)
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",
            // iPhone 15 Series (2023)
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            // iPhone 14 Series (2022)
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            // iPhone SE
            "iPhone14,6": "iPhone SE (3rd)",
            // Simulator
            "x86_64": "Simulator",
            "arm64": "Simulator",
        ]
        return mapping[identifier] ?? identifier
    }

    var body: some View {
        NavigationView {
            ZStack {
                MagicBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // ロゴ
                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 50))
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
                        .padding(.top, 20)

                        // デバイス情報カード
                        GlassCard(glowColor: .neonPurple) {
                            VStack(spacing: 0) {
                                infoRow(label: "アプリバージョン", value: "\(appVersion) (\(buildNumber))")
                                Divider().background(Color.white.opacity(0.1))
                                infoRow(label: "iOSバージョン", value: osVersion)
                                Divider().background(Color.white.opacity(0.1))
                                infoRow(label: "デバイス", value: deviceModel)
                            }
                        }

                        // コピーボタン
                        Button(action: copyInfoToClipboard) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("情報をコピー")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.neonPurple.opacity(0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neonPurple, lineWidth: 1)
                            )
                        }

                        // サポートリンク
                        Link(destination: URL(string: "https://forms.gle/C2yGhNb6o2rTHikM6")!) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("お問い合わせ")
                            }
                            .font(.headline)
                            .foregroundColor(.neonCyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.neonCyan.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neonCyan.opacity(0.3), lineWidth: 1)
                            )
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("アプリ情報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.neonCyan)
                }
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.vertical, 12)
    }

    private func copyInfoToClipboard() {
        let info = """
        PRINZ アプリ情報
        ─────────────────
        アプリバージョン: \(appVersion) (\(buildNumber))
        iOSバージョン: \(osVersion)
        デバイス: \(deviceModel)
        """
        UIPasteboard.general.string = info
    }
}

#Preview {
    HomeView()
}
