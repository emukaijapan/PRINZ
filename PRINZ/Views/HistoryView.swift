//
//  HistoryView.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import SwiftUI

struct HistoryView: View {
    @State private var history: [Reply] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color.darkBackground.ignoresSafeArea()
                
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
                            .foregroundColor(.neonPurple)
                    }
                }
            }
        }
        .onAppear {
            loadHistory()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "crown.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.neonPurple, .neonCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .neonPurple, radius: 20)
            
            Text("まだ履歴がありません")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Share Extensionから返信案を生成してみましょう")
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
    
    var body: some View {
        GlassCard(glowColor: reply.type == .safe ? .neonCyan : .neonPurple) {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                HStack {
                    Text(reply.context.emoji)
                        .font(.title2)
                    
                    Text(reply.context.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.neonCyan)
                    
                    Spacer()
                    
                    Text(reply.type.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(reply.type == .safe ? .neonCyan : .neonPurple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.glassBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(reply.type == .safe ? Color.neonCyan : Color.neonPurple, lineWidth: 1)
                                )
                        )
                }
                
                // 返信テキスト
                Text(reply.text)
                    .font(.body)
                    .foregroundColor(.white)
                
                // タイムスタンプ
                Text(reply.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .onTapGesture {
            UIPasteboard.general.string = reply.text
            // TODO: トースト通知を表示
        }
    }
}

#Preview {
    HistoryView()
        .preferredColorScheme(.dark)
}
