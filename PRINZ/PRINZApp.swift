//
//  PRINZApp.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import SwiftUI

@main
struct PRINZApp: App {
    init() {
        // App Group初期化（データ共有用）
        setupAppGroup()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // ダークモード強制
        }
    }
    
    private func setupAppGroup() {
        // App Groupのディレクトリが存在するか確認
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.prinz.app"
        ) {
            print("✅ App Group Container: \(containerURL.path)")
        } else {
            print("⚠️ App Group not configured")
        }
    }
}
