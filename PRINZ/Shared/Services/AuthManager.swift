//
//  AuthManager.swift
//  PRINZ
//
//  Firebase匿名認証を管理
//

import Foundation
import FirebaseAuth
import Combine

/// Firebase匿名認証を管理するシングルトン
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var isAuthenticated = false
    @Published private(set) var userId: String?
    @Published private(set) var authError: Error?

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        // 認証状態の変化を監視
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.userId = user?.uid
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Public Methods

    /// 匿名認証を実行（未認証の場合のみ）
    func signInAnonymouslyIfNeeded() async {
        // 既に認証済みの場合はスキップ
        if Auth.auth().currentUser != nil {
            print("✅ AuthManager: Already authenticated (uid: \(Auth.auth().currentUser?.uid ?? "nil"))")
            return
        }

        do {
            let result = try await Auth.auth().signInAnonymously()
            print("✅ AuthManager: Anonymous sign-in successful (uid: \(result.user.uid))")
            await MainActor.run {
                self.isAuthenticated = true
                self.userId = result.user.uid
                self.authError = nil
            }
        } catch {
            print("❌ AuthManager: Sign-in failed: \(error.localizedDescription)")
            await MainActor.run {
                self.authError = error
            }
        }
    }

    /// 認証を確実に完了させてから続行（Functions呼び出し前に使用）
    func ensureAuthenticated() async throws {
        if Auth.auth().currentUser != nil {
            return
        }

        // 匿名認証を試行
        await signInAnonymouslyIfNeeded()

        // 認証確認
        guard Auth.auth().currentUser != nil else {
            throw AuthError.authenticationRequired
        }
    }

    /// 現在のユーザーID（認証済みの場合）
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
}

// MARK: - Auth Error

enum AuthError: Error, LocalizedError {
    case authenticationRequired

    var errorDescription: String? {
        switch self {
        case .authenticationRequired:
            return "認証に失敗しました。ネットワーク接続を確認してください。"
        }
    }
}
