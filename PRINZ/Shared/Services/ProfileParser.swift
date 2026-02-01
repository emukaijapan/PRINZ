//
//  ProfileParser.swift
//  PRINZ
//
//  Created on 2026-02-01.
//

import Foundation

/// プロフィール画面のOCR結果を構造化するパーサー
struct ParsedProfile {
  let name: String?
  let age: Int?
  let location: String?
  let hobbies: [String]
  let bio: String?
  let rawText: String

  /// API送信用のサマリー（抽出できた情報 + rawText）
  var summary: String {
    var parts: [String] = []
    if let name = name { parts.append("名前: \(name)") }
    if let age = age { parts.append("年齢: \(age)歳") }
    if let location = location { parts.append("居住地: \(location)") }
    if !hobbies.isEmpty { parts.append("趣味: \(hobbies.joined(separator: ", "))") }
    if let bio = bio { parts.append("自己紹介: \(bio)") }

    let structured = parts.isEmpty ? "" : parts.joined(separator: "\n") + "\n\n"
    return structured + "【プロフィール全文】\n\(rawText)"
  }

  /// API送信用の辞書
  var dictionary: [String: Any] {
    var dict: [String: Any] = ["rawText": rawText]
    if let name = name { dict["name"] = name }
    if let age = age { dict["age"] = age }
    if let location = location { dict["location"] = location }
    if !hobbies.isEmpty { dict["hobbies"] = hobbies }
    if let bio = bio { dict["bio"] = bio }
    return dict
  }
}

class ProfileParser {
  static let shared = ProfileParser()
  private init() {}

  // MARK: - 正規表現パターン

  private let agePattern = #"(\d{2})\s*[歳才]"#

  private let prefectures = [
    "北海道", "青森", "岩手", "宮城", "秋田", "山形", "福島",
    "茨城", "栃木", "群馬", "埼玉", "千葉", "東京", "神奈川",
    "新潟", "富山", "石川", "福井", "山梨", "長野",
    "岐阜", "静岡", "愛知", "三重",
    "滋賀", "京都", "大阪", "兵庫", "奈良", "和歌山",
    "鳥取", "島根", "岡山", "広島", "山口",
    "徳島", "香川", "愛媛", "高知",
    "福岡", "佐賀", "長崎", "熊本", "大分", "宮崎", "鹿児島", "沖縄"
  ]

  private let hobbyKeywords = [
    "旅行", "映画", "カフェ", "読書", "音楽", "スポーツ", "料理",
    "ゲーム", "アニメ", "漫画", "写真", "カメラ", "ランニング",
    "筋トレ", "ジム", "ヨガ", "サウナ", "温泉", "キャンプ",
    "登山", "ドライブ", "お酒", "ワイン", "グルメ", "食べ歩き",
    "ショッピング", "ファッション", "美容", "ネイル",
    "ペット", "犬", "猫", "ダンス", "サッカー", "野球",
    "テニス", "ゴルフ", "スノボ", "サーフィン", "釣り",
    "DIY", "園芸", "ボードゲーム", "カラオケ",
    "Netflix", "ディズニー", "海外ドラマ", "韓国ドラマ",
    "カフェ巡り", "美術館", "散歩", "ピアノ", "ギター"
  ]

  /// プロフィール画面のUIノイズ（除外するテキスト）
  private let noiseKeywords = [
    "いいね!", "いいね！", "ありがとう", "メッセージ付き",
    "プロフィール", "基本情報", "自己紹介", "趣味・好きなこと",
    "コミュニティ", "もっと見る", "通報する", "ブロック",
    "オンライン", "最終ログイン", "本人確認済", "年齢確認済",
    "タップして", "スワイプ", "マッチ", "LIKE", "NOPE", "SUPER",
    "距離", "km", "公開中", "非公開", "編集", "設定",
    "プレミアム", "ブースト", "残り", "無料",
    "写真を見る", "詳細を見る"
  ]

  // MARK: - パース

  /// OCRテキストからプロフィール情報を抽出
  func parse(_ ocrText: String) -> ParsedProfile {
    let lines = ocrText.components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }

    // ノイズ除去
    let filteredLines = lines.filter { line in
      !noiseKeywords.contains(where: { line.contains($0) })
    }

    let cleanText = filteredLines.joined(separator: "\n")

    let name = extractName(from: filteredLines)
    let age = extractAge(from: cleanText)
    let location = extractLocation(from: cleanText)
    let hobbies = extractHobbies(from: cleanText)
    let bio = extractBio(from: filteredLines)

    return ParsedProfile(
      name: name,
      age: age,
      location: location,
      hobbies: hobbies,
      bio: bio,
      rawText: ocrText
    )
  }

  // MARK: - 抽出ヘルパー

  private func extractName(from lines: [String]) -> String? {
    // 最初の数行から短いテキスト（名前らしいもの）を探す
    for line in lines.prefix(5) {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      // 1〜10文字で、数字のみでなく、都道府県でもないもの
      if (1...10).contains(trimmed.count),
         !trimmed.allSatisfy({ $0.isNumber }),
         !prefectures.contains(where: { trimmed.contains($0) }),
         trimmed.range(of: agePattern, options: .regularExpression) == nil {
        return trimmed
      }
    }
    return nil
  }

  private func extractAge(from text: String) -> Int? {
    guard let regex = try? NSRegularExpression(pattern: agePattern) else { return nil }
    let range = NSRange(text.startIndex..., in: text)
    if let match = regex.firstMatch(in: text, range: range),
       let ageRange = Range(match.range(at: 1), in: text),
       let age = Int(text[ageRange]),
       (15...80).contains(age) {
      return age
    }
    return nil
  }

  private func extractLocation(from text: String) -> String? {
    for pref in prefectures {
      if text.contains(pref) {
        return pref
      }
    }
    return nil
  }

  private func extractHobbies(from text: String) -> [String] {
    var found: [String] = []
    for keyword in hobbyKeywords {
      if text.contains(keyword) && !found.contains(keyword) {
        found.append(keyword)
      }
    }
    return found
  }

  private func extractBio(from lines: [String]) -> String? {
    // 30文字以上の連続テキストを自己紹介とみなす
    let longLines = lines.filter { $0.count >= 30 }
    if !longLines.isEmpty {
      return longLines.joined(separator: "\n")
    }
    return nil
  }
}
