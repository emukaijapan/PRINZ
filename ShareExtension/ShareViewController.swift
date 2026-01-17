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
        let shareView = ShareExtensionView(
            extensionContext: extensionContext,
            openMainApp: openMainApp
        )
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
    
    /// メインアプリを開く
    private func openMainApp() {
        // URL Schemeでメインアプリを起動
        let url = URL(string: "prinz://open?source=share")!
        
        // ShareExtensionからアプリを開く（iOS 13+）
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                break
            }
            responder = responder?.next
        }
        
        // 少し遅延してからExtensionを閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}

// MARK: - ShareExtensionView (SwiftUI)

struct ShareExtensionView: View {
    let extensionContext: NSExtensionContext?
    let openMainApp: () -> Void
    
    @State private var currentStep: ShareStep = .loading
    @State private var loadedImage: UIImage?
    @State private var errorMessage: String?
    
    enum ShareStep {
        case loading
        case contextSelection
        case launching
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
                    case .launching:
                        launchingView
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
    
    // MARK: - Launching View
    
    private var launchingView: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.up.forward.app.fill")
                .font(.system(size: 50))
                .foregroundColor(.neonCyan)
            
            Text("PRINZアプリを起動中...")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("AI回答を生成します")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
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
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.glassBackground)
            )
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
                            loadedImage = image
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
        guard let image = loadedImage else {
            showError("画像が見つかりませんでした")
            return
        }
        
        // App Groupに画像とコンテキストを保存
        let success = SharedImageManager.shared.saveSharedData(image: image, context: context)
        
        if success {
            currentStep = .launching
            
            // 少し遅延してからメインアプリを起動
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                openMainApp()
            }
        } else {
            showError("データの保存に失敗しました")
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
