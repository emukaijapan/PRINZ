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
    
    var body: some View {
        GlassCard(glowColor: .magicPink) {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                HStack {
                    Text(reply.context.emoji)
                        .font(.title2)
                    
                    Text(reply.context.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.magicPink)
                    
                    Spacer()
                    
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
                }
                
                // 返信テキスト
                Text(reply.text)
                    .font(.body)
                    .foregroundColor(.white)
                
                // タイムスタンプ & コピー状態
                HStack {
                    Text(reply.timestamp.formatted(date: .abbreviated, time: .shortened))
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
