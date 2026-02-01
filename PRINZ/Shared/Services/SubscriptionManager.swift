//
//  SubscriptionManager.swift
//  PRINZ
//
//  Created on 2026-02-01.
//

import Foundation
import RevenueCat

@MainActor
class SubscriptionManager: ObservableObject {
  static let shared = SubscriptionManager()

  // TODO: RevenueCat Public API Keyに差し替え
  private let apiKey = "appl_XXXXXXX"

  @Published var isProUser = false
  @Published var currentOffering: Offering?
  @Published var isPurchasing = false

  private init() {}

  // MARK: - Setup

  func configure() {
    Purchases.logLevel = .warn
    Purchases.configure(withAPIKey: apiKey)
    Purchases.shared.delegate = self

    Task { await checkSubscriptionStatus() }
  }

  // MARK: - Subscription Status

  func checkSubscriptionStatus() async {
    do {
      let info = try await Purchases.shared.customerInfo()
      isProUser = info.entitlements["premium"]?.isActive ?? false
    } catch {
      print("❌ SubscriptionManager: Failed to get customer info - \(error)")
    }
  }

  // MARK: - Fetch Offerings

  func fetchOfferings() async {
    do {
      let offerings = try await Purchases.shared.offerings()
      currentOffering = offerings.current
    } catch {
      print("❌ SubscriptionManager: Failed to fetch offerings - \(error)")
    }
  }

  // MARK: - Purchase

  func purchase(_ package: Package) async throws -> Bool {
    isPurchasing = true
    defer { isPurchasing = false }

    let result = try await Purchases.shared.purchase(package: package)

    if !result.userCancelled {
      isProUser = result.customerInfo.entitlements["premium"]?.isActive ?? false
      return true
    }
    return false
  }

  // MARK: - Restore

  func restorePurchases() async throws {
    isPurchasing = true
    defer { isPurchasing = false }

    let info = try await Purchases.shared.restorePurchases()
    isProUser = info.entitlements["premium"]?.isActive ?? false
  }
}

// MARK: - PurchasesDelegate

extension SubscriptionManager: PurchasesDelegate {
  nonisolated func purchases(
    _ purchases: Purchases,
    receivedUpdated customerInfo: CustomerInfo
  ) {
    Task { @MainActor in
      isProUser = customerInfo.entitlements["premium"]?.isActive ?? false
    }
  }
}
