//
//  Color+Extensions.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import SwiftUI

extension Color {
    // MARK: - Magic Gradient Colors（魔法のグラデーション）
    
    /// 深い紫（夜）- グラデーション上部
    static let magicPurple = Color(red: 0.2, green: 0.0, blue: 0.3)
    
    /// ローズピンク（夜明け/成就）- グラデーション下部
    static let magicPink = Color(red: 0.8, green: 0.2, blue: 0.5)
    
    /// ネオンパープル - アクセントカラー
    static let neonPurple = Color(hex: "#D000FF")
    
    /// ネオンシアン - サブアクセントカラー
    static let neonCyan = Color(hex: "#00FFFF")
    
    // MARK: - Background
    
    /// ダークバックグラウンド - ShareExtension用
    static let darkBackground = Color(red: 0.05, green: 0.02, blue: 0.1)
    
    /// 魔法のグラデーション背景
    static var magicGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [magicPurple, magicPink]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// グラスバックグラウンド - 半透明の暗色
    static let glassBackground = Color.white.opacity(0.1)
    
    /// グラスボーダー - 半透明の明色
    static let glassBorder = Color.white.opacity(0.2)
    
    // MARK: - Hex Initializer
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Magic Background View

struct MagicBackground: View {
    var body: some View {
        Color.magicGradient
            .ignoresSafeArea()
    }
}
