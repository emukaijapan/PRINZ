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
