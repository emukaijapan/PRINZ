//
//  ContentView.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showSharedResult = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ホーム画面（メイン）
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)
            
            // 手動入力画面
            NavigationStack {
                ManualInputView()
            }
                .tabItem {
                    Label("テキスト入力", systemImage: "keyboard")
                }
                .tag(1)

            // 履歴画面
            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "clock.fill")
                }
                .tag(2)

            // 設定画面
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.neonPurple)
        .onChange(of: appState.launchedFromShare) { _, launched in
            if launched {
                showSharedResult = true
            }
        }
        .fullScreenCover(isPresented: $showSharedResult) {
            // ShareExtensionからのデータでReplyResultViewを表示
            SharedResultView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Shared Result View (ShareExtensionからの遷移用)

struct SharedResultView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                MagicBackground()
                
                if let image = appState.sharedImage,
                   let context = appState.sharedContext {
                    ReplyResultView(
                        image: image,
                        extractedText: "",  // OCRはここで実行
                        context: context
                    )
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("データの読み込みに失敗しました")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Button("閉じる") {
                            closeAndClear()
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: closeAndClear) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }
    
    private func closeAndClear() {
        appState.clearSharedData()
        dismiss()
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .environmentObject(AppState.shared)
}
