//
//  PRINZApp.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import SwiftUI
import Firebase
import Combine

/// アプリ全体の状態管理
class AppState: ObservableObject {
    static let shared = AppState()
    
    /// ShareExtensionから起動されたか
    @Published var launchedFromShare = false
    
    /// 共有された画像
    @Published var sharedImage: UIImage?
    
    /// 共有されたコンテキスト
    @Published var sharedContext: Context?
    
    private init() {}
    
    /// ShareExtensionからのデータをロード
    func loadSharedData() {
        if let data = SharedImageManager.shared.loadSharedData() {
            sharedImage = data.image
            sharedContext = data.context
            launchedFromShare = true
            print("✅ AppState: Loaded shared data from ShareExtension")
            // 注意: ここではファイルをクリアしない（処理完了後にクリア）
        }
    }
    
    /// 共有データをクリア（UI状態のみ）
    func clearUIState() {
        sharedImage = nil
        sharedContext = nil
        launchedFromShare = false
        print("🔄 AppState: UI state cleared")
    }
    
    /// 共有データを完全にクリア（ファイル含む）
    func clearSharedData() {
        clearUIState()
        SharedImageManager.shared.clearSharedData()
    }
}

@main
struct PRINZApp: App {
    @StateObject private var appState = AppState.shared
    @AppStorage("hasCompletedOnboarding", store: UserDefaults(suiteName: "group.com.mgolworks.prinz"))
    private var hasCompletedOnboarding: Bool = false

    init() {
        // Firebase初期化
        FirebaseApp.configure()
        print("✅ Firebase initialized")

        // RevenueCat初期化（課金処理）
        SubscriptionManager.shared.configure()

        // App Group初期化（データ共有用）
        setupAppGroup()
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .preferredColorScheme(.dark)
                    .environmentObject(appState)
                    .onOpenURL { url in
                        handleOpenURL(url)
                    }
                    .onAppear {
                        // 起動時に共有データがあればロード
                        checkForSharedData()
                    }
            } else {
                OnboardingView()
                    .preferredColorScheme(.dark)
            }
        }
    }
    
    private func setupAppGroup() {
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.mgolworks.prinz"
        ) {
            print("✅ App Group Container: \(containerURL.path)")
        } else {
            print("⚠️ App Group not configured")
        }
    }
    
    /// URL Schemeを処理
    private func handleOpenURL(_ url: URL) {
        print("📱 Received URL: \(url)")
        
        if url.scheme == "prinz" {
            if url.host == "open" {
                // ShareExtensionからの起動
                appState.loadSharedData()
            }
        }
    }
    
    /// 起動時に共有データをチェック
    private func checkForSharedData() {
        if SharedImageManager.shared.hasSharedData {
            appState.loadSharedData()
        }
    }
}
