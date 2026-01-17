//
//  SharedImageManager.swift
//  PRINZ
//
//  Created on 2026-01-17.
//

import Foundation
import UIKit

/// ShareExtensionとメインアプリ間で画像を共有するマネージャー
class SharedImageManager {
    static let shared = SharedImageManager()
    
    private let appGroupIdentifier = "group.com.prinz.app"
    private let sharedImageFileName = "shared_image.jpg"
    private let sharedContextFileName = "shared_context.json"
    
    private init() {}
    
    // MARK: - App Group Container
    
    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    private var sharedImageURL: URL? {
        containerURL?.appendingPathComponent(sharedImageFileName)
    }
    
    private var sharedContextURL: URL? {
        containerURL?.appendingPathComponent(sharedContextFileName)
    }
    
    // MARK: - Save (ShareExtension側)
    
    /// 画像とコンテキストをApp Groupに保存
    func saveSharedData(image: UIImage, context: Context) -> Bool {
        guard let imageURL = sharedImageURL,
              let contextURL = sharedContextURL else {
            print("❌ SharedImageManager: App Group container not found")
            return false
        }
        
        // 画像をJPEGとして保存
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ SharedImageManager: Failed to convert image to JPEG")
            return false
        }
        
        do {
            try imageData.write(to: imageURL)
            print("✅ SharedImageManager: Image saved to \(imageURL.path)")
        } catch {
            print("❌ SharedImageManager: Failed to save image: \(error)")
            return false
        }
        
        // コンテキストをJSONとして保存
        let contextData: [String: String] = [
            "context": context.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            let jsonData = try JSONEncoder().encode(contextData)
            try jsonData.write(to: contextURL)
            print("✅ SharedImageManager: Context saved")
        } catch {
            print("❌ SharedImageManager: Failed to save context: \(error)")
            return false
        }
        
        return true
    }
    
    // MARK: - Load (メインアプリ側)
    
    /// App Groupから共有データを読み込み
    func loadSharedData() -> (image: UIImage, context: Context)? {
        guard let imageURL = sharedImageURL,
              let contextURL = sharedContextURL else {
            print("❌ SharedImageManager: App Group container not found")
            return nil
        }
        
        // 画像を読み込み
        guard FileManager.default.fileExists(atPath: imageURL.path),
              let imageData = try? Data(contentsOf: imageURL),
              let image = UIImage(data: imageData) else {
            print("❌ SharedImageManager: No shared image found")
            return nil
        }
        
        // コンテキストを読み込み
        guard FileManager.default.fileExists(atPath: contextURL.path),
              let contextData = try? Data(contentsOf: contextURL),
              let contextDict = try? JSONDecoder().decode([String: String].self, from: contextData),
              let contextRaw = contextDict["context"],
              let context = Context(rawValue: contextRaw) else {
            print("❌ SharedImageManager: No shared context found")
            return nil
        }
        
        print("✅ SharedImageManager: Loaded shared data successfully")
        return (image, context)
    }
    
    // MARK: - Clear
    
    /// 共有データをクリア
    func clearSharedData() {
        if let imageURL = sharedImageURL {
            try? FileManager.default.removeItem(at: imageURL)
        }
        if let contextURL = sharedContextURL {
            try? FileManager.default.removeItem(at: contextURL)
        }
        print("🗑️ SharedImageManager: Shared data cleared")
    }
    
    /// 共有データが存在するかチェック
    var hasSharedData: Bool {
        guard let imageURL = sharedImageURL else { return false }
        return FileManager.default.fileExists(atPath: imageURL.path)
    }
}
