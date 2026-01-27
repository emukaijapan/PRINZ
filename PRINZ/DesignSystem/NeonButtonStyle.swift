//
//  NeonButtonStyle.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import SwiftUI

struct NeonButtonStyle: ButtonStyle {
    enum NeonColor {
        case purple
        case cyan
        
        var color: Color {
            switch self {
            case .purple: return .neonPurple
            case .cyan: return .neonCyan
            }
        }
    }
    
    let neonColor: NeonColor
    let isCompact: Bool
    
    init(color: NeonColor = .purple, compact: Bool = false) {
        self.neonColor = color
        self.isCompact = compact
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isCompact ? .subheadline : .headline)
            .fontWeight(.bold)
            .foregroundColor(neonColor.color)
            .padding(.horizontal, isCompact ? 16 : 24)
            .padding(.vertical, isCompact ? 8 : 12)
            .background(
                RoundedRectangle(cornerRadius: isCompact ? 12 : 16)
                    .fill(Color.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: isCompact ? 12 : 16)
                            .stroke(neonColor.color, lineWidth: 2)
                    )
            )
            .shadow(
                color: neonColor.color.opacity(configuration.isPressed ? 0.8 : 0.5),
                radius: configuration.isPressed ? 15 : 10,
                x: 0,
                y: 0
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extension

extension View {
    func neonButtonStyle(color: NeonButtonStyle.NeonColor = .purple, compact: Bool = false) -> some View {
        self.buttonStyle(NeonButtonStyle(color: color, compact: compact))
    }
}
