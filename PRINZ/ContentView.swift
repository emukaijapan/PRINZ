//
//  ContentView.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ホーム画面（メイン）
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)
            
            // 履歴画面
            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "clock.fill")
                }
                .tag(1)
            
            // 設定画面
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .accentColor(.neonPurple)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
