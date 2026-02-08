//
//  SubscriptionManager.swift
//  PRINZ
//
//  Created on 2026-02-01.
//

import Foundation
import RevenueCat
import Combine

@MainActor
class SubscriptionManager: NSObject, ObservableObject {
  static let shared = SubscriptionManager()

  /// RevenueCat Public API Key
  private let apiKey = "appl_znImYznVHRLtSVMfNhepwAMNzNb"

  /// RevenueCat が正しく初期化されたかどうか
  private var isConfigured = false

  @Published var isProUser = false
  @Published var currentOffering: Offering?
  @Published var isPurchasing = false

  private override init() {
    super.init()
  }

  // MARK: - Setup

  func configure() {
    Purchases.logLevel = .debug
    Purchases.configure(withAPIKey: apiKey)
    Purchases.shared.delegate = self
    isConfigured = true
    print("✅ RevenueCat initialized with API key")

    Task { await checkSubscriptionStatus() }
  }

  // MARK: - Subscription Status

  func checkSubscriptionStatus() async {
    guard isConfigured else { return }
    do {
      let info = try await Purchases.shared.customerInfo()
      isProUser = info.entitlements["premium"]?.isActive ?? false
    } catch {
      print("❌ SubscriptionManager: Failed to get customer info - \(error)")
    }
  }

  // MARK: - Fetch Offerings

  func fetchOfferings() async {
    guard isConfigured else {
      print("⚠️ SubscriptionManager: RevenueCat not configured, skipping fetchOfferings")
      return
    }
    do {
      let offerings = try await Purchases.shared.offerings()
      currentOffering = offerings.current
    } catch {
      print("❌ SubscriptionManager: Failed to fetch offerings - \(error)")
    }
  }

  // MARK: - Purchase

  func purchase(_ package: Package) async throws -> Bool {
    guard isConfigured else {
      throw NSError(domain: "SubscriptionManager", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "RevenueCat not configured"])
    }
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
    guard isConfigured else {
      throw NSError(domain: "SubscriptionManager", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "RevenueCat not configured"])
    }
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
