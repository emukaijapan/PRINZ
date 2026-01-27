// UserAttributes.swift
// PRINZ
//
// Created on 2026-01-13.
//

import Foundation

/// ユーザーの性別
enum UserGender: String, Codable, CaseIterable {
    case male = "男性"
    case female = "女性"
    case other = "その他"
    
    var displayName: String { return self.rawValue }
}

/// ユーザーの年代
enum UserAgeGroup: String, Codable, CaseIterable {
    case teens = "10代"
    case early20s = "20代前半"
    case late20s = "20代後半"
    case thirties = "30代"
    case forties = "40代"
    case fifties = "50代以上"
    
    var displayName: String { return self.rawValue }
    
    /// 年齢からUserAgeGroupを取得
    static func from(age: Int) -> UserAgeGroup {
        switch age {
        case ..<20: return .teens
        case 20...24: return .early20s
        case 25...29: return .late20s
        case 30...39: return .thirties
        case 40...49: return .forties
        default: return .fifties
        }
    }
}
