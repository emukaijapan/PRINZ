//
//  ScannerOverlayView.swift
//  PRINZ
//
//  スクリーンショットをスキャン中のサイバー風エフェクト
//

import SwiftUI

/// スクショの上をスキャンラインが上下するエフェクト
struct ScannerOverlayView: View {
  let image: UIImage
  @State private var scanPosition: CGFloat = 0.0

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // スクリーンショット画像（少し暗く）
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: geometry.size.width * 0.85)
          .clipShape(RoundedRectangle(cornerRadius: 20))
          .overlay(
            RoundedRectangle(cornerRadius: 20)
              .fill(Color.black.opacity(0.3))
          )
          .overlay(
            // スキャンライン
            scanLineOverlay(height: geometry.size.height * 0.6)
          )
          .overlay(
            // 枠線（ネオングロー）
            RoundedRectangle(cornerRadius: 20)
              .stroke(
                LinearGradient(
                  colors: [.neonPurple, .neonCyan],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                ),
                lineWidth: 2
              )
              .shadow(color: .neonPurple.opacity(0.5), radius: 8)
          )

        // ステータステキスト
        VStack {
          Spacer()
          HStack(spacing: 8) {
            ProgressView()
              .tint(.neonCyan)
            Text("解析中...")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundColor(.white.opacity(0.8))
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 10)
          .background(
            Capsule()
              .fill(Color.glassBackground)
              .overlay(
                Capsule()
                  .stroke(Color.glassBorder, lineWidth: 1)
              )
          )
          .padding(.bottom, 40)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onAppear {
      startScanAnimation()
    }
  }

  // MARK: - Scan Line

  private func scanLineOverlay(height: CGFloat) -> some View {
    GeometryReader { geo in
      VStack(spacing: 0) {
        // スキャンライン（ネオングラデーション）
        Rectangle()
          .fill(
            LinearGradient(
              colors: [
                Color.neonCyan.opacity(0.0),
                Color.neonCyan.opacity(0.8),
                Color.neonPurple.opacity(0.8),
                Color.neonPurple.opacity(0.0)
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .frame(height: 4)
          .shadow(color: .neonCyan, radius: 10)
          .shadow(color: .neonCyan, radius: 20)

        // スキャン後の残像（上から下へ）
        Rectangle()
          .fill(
            LinearGradient(
              colors: [
                Color.neonCyan.opacity(0.15),
                Color.clear
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .frame(height: 60)
      }
      .offset(y: scanPosition * (geo.size.height - 64))
    }
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }

  // MARK: - Animation

  private func startScanAnimation() {
    withAnimation(
      .easeInOut(duration: 2.0)
      .repeatForever(autoreverses: true)
    ) {
      scanPosition = 1.0
    }
  }
}

#Preview {
  ZStack {
    MagicBackground()
    ScannerOverlayView(image: UIImage(systemName: "photo")!)
  }
}
