//
//  HistoryView.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import SwiftUI

struct HistoryView: View {
    @State private var history: [Reply] = []
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationView {
            ZStack {
                // 魔法のグラデーション背景
                MagicBackground()
                
                if history.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: clearHistory) {
                        Image(systemName: "trash")
                            .foregroundColor(.magicPink)
                    }
                }
            }
        }
        .onAppear {
            loadHistory()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                loadHistory()
                print("🔄 HistoryView: Reloaded history on app activation")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "crown.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.magicPurple, .magicPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .magicPink, radius: 20)
            
            Text("まだ履歴がありません")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("返信案をコピーすると履歴に保存されます")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - History List
    
    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(history) { reply in
                    HistoryCard(reply: reply)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Actions
    
    private func loadHistory() {
        history = DataManager.shared.loadHistory()
    }
    
    private func clearHistory() {
        DataManager.shared.clearHistory()
        history = []
    }
}

// MARK: - History Card

struct HistoryCard: View {
    let reply: Reply
    @State private var showCopied = false

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    var body: some View {
        GlassCard(glowColor: .magicPink) {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー（トーン種別バッジのみ）
                HStack {
                    Text(reply.type.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.glassBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.magicPink, lineWidth: 1)
                                )
                        )

                    Spacer()
                }

                // 返信テキスト
                Text(reply.text)
                    .font(.body)
                    .foregroundColor(.white)

                // タイムスタンプ & コピー状態
                HStack {
                    Text(formatTimestamp(reply.timestamp))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    if showCopied {
                        Label("コピー済み", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .onTapGesture {
            UIPasteboard.general.string = reply.text
            showCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showCopied = false
            }
        }
    }
}

#Preview {
    HistoryView()
        .preferredColorScheme(.dark)
}
