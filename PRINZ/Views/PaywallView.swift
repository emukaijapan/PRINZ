//
//  PaywallView.swift
//  PRINZ
//
//  Created on 2026-02-01.
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
  @Environment(\.dismiss) private var dismiss
  @ObservedObject private var subscriptionManager = SubscriptionManager.shared
  @State private var selectedPackage: Package?
  @State private var errorMessage: String?
  @State private var showError = false

  /// 初期選択プラン（"weekly" or "yearly"）
  var preferredPlan: String?

  var body: some View {
    ZStack {
      MagicBackground()

      ScrollView {
        VStack(spacing: 24) {
          // 閉じるボタン
          HStack {
            Spacer()
            Button(action: { dismiss() }) {
              Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.5))
            }
          }
          .padding(.horizontal)

          // ヘッダー
          headerView

          // 機能比較
          featureComparisonView

          // プラン選択
          planSelectionView

          // 購入ボタン
          purchaseButton

          // 復元リンク
          restoreButton

          // 法的リンク
          legalLinks
        }
        .padding()
      }
    }
    .task {
      await subscriptionManager.fetchOfferings()
      // プラン選択（preferredPlanがあればそれを優先）
      if let offering = subscriptionManager.currentOffering {
        if preferredPlan == "yearly", let annual = offering.annual {
          selectedPackage = annual
        } else {
          // デフォルトは週額
          selectedPackage = offering.weekly ?? offering.annual
        }
      }
    }
    .alert("エラー", isPresented: $showError) {
      Button("OK") {}
    } message: {
      Text(errorMessage ?? "不明なエラーが発生しました")
    }
  }

  // MARK: - Header

  private var headerView: some View {
    VStack(spacing: 16) {
      HStack(spacing: 6) {
        Image(systemName: "crown.fill")
          .font(.system(size: 36))
        Text("PRINZ")
          .font(.system(size: 36, weight: .black))
          .italic()
      }
      .foregroundStyle(
        LinearGradient(
          colors: [.neonPurple, .neonCyan],
          startPoint: .leading,
          endPoint: .trailing
        )
      )
      .shadow(color: .neonPurple.opacity(0.5), radius: 15)

      Text("Premium")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.white)

      Text("もっと使いこなそう")
        .font(.subheadline)
        .foregroundColor(.white.opacity(0.6))
    }
    .padding(.top, 10)
  }

  // MARK: - Feature Comparison

  private var featureComparisonView: some View {
    GlassCard(glowColor: .neonPurple) {
      VStack(spacing: 14) {
        featureRow("返信生成", free: "5回/日", premium: "無制限")
        Divider().background(Color.white.opacity(0.1))
        featureRow("チャット返信", free: "○", premium: "○")
        Divider().background(Color.white.opacity(0.1))
        featureRow("あいさつ作成", free: "○", premium: "○")
      }
    }
  }

  private func featureRow(_ title: String, free: String, premium: String) -> some View {
    HStack {
      Text(title)
        .font(.subheadline)
        .foregroundColor(.white.opacity(0.7))
        .frame(maxWidth: .infinity, alignment: .leading)

      Text(free)
        .font(.subheadline)
        .foregroundColor(.white.opacity(0.4))
        .frame(width: 60)

      Text(premium)
        .font(.subheadline)
        .fontWeight(.bold)
        .foregroundColor(.neonCyan)
        .frame(width: 60)
    }
  }

  // MARK: - Plan Selection

  private var planSelectionView: some View {
    VStack(spacing: 12) {
      if let offering = subscriptionManager.currentOffering {
        // 週額プラン
        if let weekly = offering.weekly {
          VStack(spacing: 6) {
            // 背中を押すメッセージ
            Text("トライアルキャンペーン中")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundColor(.neonCyan)

            planCard(
              package: weekly,
              title: "週額プラン",
              badge: nil
            )
          }
        }

        // 年額プラン
        if let annual = offering.annual {
          planCard(
            package: annual,
            title: "年額プラン",
            badge: "お得"
          )
        }
      } else {
        // ローディング
        ProgressView()
          .tint(.white)
          .padding(40)
      }
    }
  }

  private func planCard(package: Package, title: String, badge: String?) -> some View {
    let isSelected = selectedPackage?.identifier == package.identifier

    return Button(action: {
      selectedPackage = package
    }) {
      HStack(spacing: 14) {
        // 選択インジケーター（ラジオボタン風）
        ZStack {
          Circle()
            .stroke(isSelected ? Color.neonCyan : Color.white.opacity(0.3), lineWidth: 2)
            .frame(width: 24, height: 24)

          if isSelected {
            Circle()
              .fill(Color.neonCyan)
              .frame(width: 14, height: 14)
          }
        }

        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 8) {
            Text(title)
              .font(.subheadline)
              .fontWeight(.bold)

            if let badge = badge {
              Text(badge)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.neonCyan)
                .cornerRadius(4)
            }

            if isSelected {
              Text("選択中")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.neonCyan)
            }
          }

          if let intro = package.storeProduct.introductoryDiscount,
             intro.paymentMode == .freeTrial {
            // トライアル既使用の場合は表示しない
            if !UsageManager.shared.hasAlreadyUsedTrial() {
              Text("\(intro.subscriptionPeriod.value)日間無料トライアル")
                .font(.caption)
                .foregroundColor(.neonCyan)
            } else {
              Text("トライアル済み")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
            }
          }
        }

        Spacer()

        Text(package.localizedPriceString)
          .font(.headline)
          .fontWeight(.bold)
      }
      .foregroundColor(.white)
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(isSelected ? Color.magicPurple.opacity(0.5) : Color.glassBackground)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(isSelected ? Color.neonCyan : Color.glassBorder, lineWidth: isSelected ? 2.5 : 1)
      )
      .shadow(color: isSelected ? Color.neonCyan.opacity(0.3) : Color.clear, radius: 8)
    }
  }

  // MARK: - Purchase Button

  private var purchaseButton: some View {
    Button(action: {
      Task { await handlePurchase() }
    }) {
      HStack {
        if subscriptionManager.isPurchasing {
          ProgressView()
            .tint(.black)
        } else {
          Image(systemName: "crown.fill")
          Text("プレミアムを開始")
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
    .disabled(selectedPackage == nil || subscriptionManager.isPurchasing)
    .opacity(selectedPackage == nil ? 0.5 : 1.0)
  }

  // MARK: - Restore

  private var restoreButton: some View {
    Button(action: {
      Task { await handleRestore() }
    }) {
      Text("購入を復元")
        .font(.subheadline)
        .foregroundColor(.white.opacity(0.5))
    }
    .disabled(subscriptionManager.isPurchasing)
  }

  // MARK: - Legal Links

  private var legalLinks: some View {
    HStack(spacing: 16) {
      Link("利用規約", destination: URL(string: "https://prinz-app.com/terms")!)
      Text("・").foregroundColor(.white.opacity(0.3))
      Link("プライバシーポリシー", destination: URL(string: "https://prinz-app.com/privacy")!)
    }
    .font(.caption2)
    .foregroundColor(.white.opacity(0.3))
    .padding(.bottom, 20)
  }

  // MARK: - Actions

  private func handlePurchase() async {
    guard let package = selectedPackage else { return }

    do {
      let success = try await subscriptionManager.purchase(package)
      if success {
        // トライアルを使用済みとしてマーク
        UsageManager.shared.markTrialAsUsed()
        dismiss()
      }
    } catch {
      errorMessage = "購入に失敗しました: \(error.localizedDescription)"
      showError = true
    }
  }

  private func handleRestore() async {
    do {
      try await subscriptionManager.restorePurchases()
      if subscriptionManager.isProUser {
        dismiss()
      } else {
        errorMessage = "復元可能な購入が見つかりませんでした"
        showError = true
      }
    } catch {
      errorMessage = "復元に失敗しました: \(error.localizedDescription)"
      showError = true
    }
  }
}

#Preview {
  PaywallView()
    .preferredColorScheme(.dark)
}
