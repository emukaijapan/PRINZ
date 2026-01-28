//
//  OCRService.swift
//  PRINZ
//
//  Created on 2026-01-11.
//

import UIKit
import Vision

class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    /// OCR結果（座標情報付き）
    struct OCRTextItem {
        let text: String
        let normalizedX: CGFloat  // 0.0 = 左端, 1.0 = 右端（中心のX座標）
        let normalizedY: CGFloat  // 0.0 = 下端, 1.0 = 上端
        
        /// 相手のメッセージかどうか（画面左側）
        var isFromPartner: Bool {
            return normalizedX < 0.5
        }
    }
    
    /// 画像からテキストを抽出（日本語対応）
    /// - Parameters:
    ///   - image: OCR対象の画像
    ///   - completion: 抽出されたテキストまたはエラー
    func recognizeText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        // メモリクラッシュ防止: 画像を2048pxにリサイズ
        guard let resizedImage = image.resized(to: 2048),
              let cgImage = resizedImage.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }
        
        // Vision Requestの作成
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(OCRError.noTextFound))
                return
            }
            
            // テキストを結合
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            let fullText = recognizedStrings.joined(separator: "\n")
            
            if fullText.isEmpty {
                completion(.failure(OCRError.noTextFound))
            } else {
                completion(.success(fullText))
            }
        }
        
        // 日本語認識の設定（CRITICAL）
        request.recognitionLanguages = ["ja-JP", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // リクエスト実行
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// 画像からテキストを抽出（座標情報付き）
    /// - Parameters:
    ///   - image: OCR対象の画像
    ///   - completion: 座標付きテキストアイテムの配列またはエラー
    func recognizeTextWithCoordinates(from image: UIImage, completion: @escaping (Result<[OCRTextItem], Error>) -> Void) {
        guard let resizedImage = image.resized(to: 2048),
              let cgImage = resizedImage.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(OCRError.noTextFound))
                return
            }
            
            // 座標情報付きでテキストを抽出
            let textItems: [OCRTextItem] = observations.compactMap { observation in
                guard let text = observation.topCandidates(1).first?.string else {
                    return nil
                }
                
                // boundingBoxの中心X座標を計算
                // Vision座標系: 左下が原点、右上が(1,1)
                let box = observation.boundingBox
                let centerX = box.midX
                let centerY = box.midY
                
                return OCRTextItem(
                    text: text,
                    normalizedX: centerX,
                    normalizedY: centerY
                )
            }
            
            if textItems.isEmpty {
                completion(.failure(OCRError.noTextFound))
            } else {
                // Y座標でソート（上から下へ = 1.0→0.0）
                let sorted = textItems.sorted { $0.normalizedY > $1.normalizedY }
                completion(.success(sorted))
            }
        }
        
        request.recognitionLanguages = ["ja-JP", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - OCR Error

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "画像の読み込みに失敗しました"
        case .noTextFound:
            return "テキストが見つかりませんでした"
        }
    }
}

// MARK: - UIImage Extension (Resize)

extension UIImage {
    /// 画像を指定した最大サイズにリサイズ
    func resized(to maxDimension: CGFloat) -> UIImage? {
        let size = self.size
        let aspectRatio = size.width / size.height
        
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // 既に小さい場合はリサイズ不要
        if size.width <= newSize.width && size.height <= newSize.height {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        self.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
