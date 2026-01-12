//
//  ShareViewController.swift
//  ShareExtension
//
//  Created on 2026-01-11.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    private var hostingController: UIHostingController<ShareExtensionView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SwiftUIビューをホスト
        let shareView = ShareExtensionView(extensionContext: extensionContext)
        hostingController = UIHostingController(rootView: shareView)
        
        if let hostingController = hostingController {
            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.view.frame = view.bounds
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostingController.didMove(toParent: self)
        }
        
        // 背景を透明に
        view.backgroundColor = .clear
    }
}

// MARK: - ShareExtensionView (SwiftUI)

struct ShareExtensionView: View {
    let extensionContext: NSExtensionContext?
    
    @State private var currentStep: ShareStep = .loading
    @State private var extractedText: String = ""
    @State private var selectedContext: Context?
    @State private var generatedReplies: [Reply] = []
    @State private var errorMessage: String?
    
    enum ShareStep {
        case loading
        case contextSelection
        case scanning
        case results
        case error
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color.darkBackground.ignoresSafeArea()
            
            VStack {
                // ヘッダー
                headerView
                
                Spacer()
                
                // メインコンテンツ
                Group {
                    switch currentStep {
                    case .loading:
                        loadingView
                    case .contextSelection:
                        ContextSelectionView(onSelect: handleContextSelection)
                    case .scanning:
                        ScanningAnimationView()
                    case .results:
                        ReplyOptionsView(
                            replies: generatedReplies,
                            onCopy: handleCopyReply,
                            onClose: closeExtension
                        )
                    case .error:
                        errorView
                    }
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadSharedImage()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "crown.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.neonPurple, .neonCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .neonPurple, radius: 10)
            
            Text("PRINZ")
                .font(.title2)
                .fontWeight(.black)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.neonPurple, .neonCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Spacer()
            
            Button(action: closeExtension) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(.neonPurple)
                .scaleEffect(1.5)
            
            Text("画像を読み込み中...")
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text(errorMessage ?? "エラーが発生しました")
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("閉じる") {
                closeExtension()
            }
            .neonButtonStyle(color: .purple)
        }
    }
    
    // MARK: - Actions
    
    private func loadSharedImage() {
        guard let extensionContext = extensionContext,
              let item = extensionContext.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            showError("画像が見つかりませんでした")
            return
        }
        
        // 画像を探す
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (item, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            showError("画像の読み込みに失敗しました: \(error.localizedDescription)")
                            return
                        }
                        
                        var image: UIImage?
                        
                        if let url = item as? URL {
                            image = UIImage(contentsOfFile: url.path)
                        } else if let data = item as? Data {
                            image = UIImage(data: data)
                        } else if let img = item as? UIImage {
                            image = img
                        }
                        
                        if let image = image {
                            // コンテキスト選択へ
                            currentStep = .contextSelection
                        } else {
                            showError("画像の形式が不正です")
                        }
                    }
                }
                return
            }
        }
        
        showError("画像が見つかりませんでした")
    }
    
    private func handleContextSelection(_ context: Context) {
        selectedContext = context
        currentStep = .scanning
        
        // OCR実行
        performOCR()
    }
    
    private func performOCR() {
        guard let extensionContext = extensionContext,
              let item = extensionContext.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            showError("画像が見つかりませんでした")
            return
        }
        
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (item, error) in
                    var image: UIImage?
                    
                    if let url = item as? URL {
                        image = UIImage(contentsOfFile: url.path)
                    } else if let data = item as? Data {
                        image = UIImage(data: data)
                    } else if let img = item as? UIImage {
                        image = img
                    }
                    
                    guard let image = image else {
                        DispatchQueue.main.async {
                            showError("画像の読み込みに失敗しました")
                        }
                        return
                    }
                    
                    // OCR実行
                    OCRService.shared.recognizeText(from: image) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let text):
                                extractedText = text
                                print("📝 Extracted Text:\n\(text)")
                                generateReplies()
                            case .failure(let error):
                                showError("テキスト認識に失敗しました: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                return
            }
        }
    }
    
    private func generateReplies() {
        guard let context = selectedContext else { return }
        
        // 少し遅延を入れてアニメーションを見せる
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            generatedReplies = ReplyGenerator.shared.generateReplies(
                for: extractedText,
                context: context
            )
            
            // 履歴に保存
            DataManager.shared.saveReplies(generatedReplies)
            
            currentStep = .results
        }
    }
    
    private func handleCopyReply(_ reply: Reply) {
        UIPasteboard.general.string = reply.text
        
        // 少し遅延してから閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            closeExtension()
        }
    }
    
    private func closeExtension() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        currentStep = .error
    }
}
