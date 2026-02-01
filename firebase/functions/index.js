/**
 * PRINZ Firebase Cloud Functions
 * 
 * OpenAI APIへのセキュアなプロキシ
 * - APIキー秘匿
 * - Rate Limiting
 * - ユーザー認証（MVP段階では緩和）
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const OpenAI = require("openai");

admin.initializeApp();

// Secret定義
const openaiApiKey = defineSecret("OPENAI_API_KEY");

// Firestore参照
const db = admin.firestore();

// OpenAIクライアント（遅延初期化 - 実行時に環境変数からAPIキー取得）
let openai = null;

function getOpenAIClient() {
  if (!openai) {
    const apiKey = openaiApiKey.value().trim();
    console.log(`[getOpenAIClient] API Key check: exists=${!!apiKey}, length=${apiKey?.length || 0}`);

    if (!apiKey) {
      throw new Error("OPENAI_API_KEY is not configured");
    }

    openai = new OpenAI({
      apiKey: apiKey,
      timeout: 30000,  // 30秒タイムアウト
      maxRetries: 2,   // 最大2回リトライ
    });
  }
  return openai;
}

// Rate Limiting設定
const DAILY_FREE_LIMIT = 5;  // 無料ユーザーの1日の上限
const PREMIUM_LIMIT = 100;   // プレミアムユーザーの1日の上限

// MVP開発モード（本番リリース時はfalseに変更）
const DEV_MODE = true;

/**
 * AI返信生成 Cloud Function
 * 
 * リクエストボディ:
 * {
 *   "message": "相手のメッセージ",
 *   "personalType": "知的系",
 *   "gender": "男性",
 *   "ageGroup": "20代前半",
 *   "relationship": "マッチ直後"
 * }
 */
exports.generateReply = onCall(
  {
    region: "asia-northeast1",
    secrets: [openaiApiKey],
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    const { data, auth } = request;

    // 認証チェック（MVP開発モードでは緩和）
    let userId = "anonymous";

    if (DEV_MODE) {
      // 開発モード: 認証なしでも許可、デバイスIDまたはランダムIDを使用
      userId = auth?.uid || data.deviceId || `dev_${Date.now()}`;
      console.log(`[DEV MODE] User ID: ${userId}`);
      // DEV_MODEではRate Limitingをスキップ
    } else {
      // 本番モード: 認証必須
      if (!auth) {
        throw new HttpsError(
          "unauthenticated",
          "認証が必要です"
        );
      }
      userId = auth.uid;

      // Rate Limiting チェック（本番のみ）
      const allowed = DEV_MODE ? true : await checkRateLimit(userId);
      if (!allowed) {
        throw new HttpsError(
          "resource-exhausted",
          "本日の利用上限に達しました。プレミアムにアップグレードしてください。"
        );
      }
    }

    // 入力検証
    const {
      message,
      personalType,
      gender,
      ageGroup,
      relationship,
      partnerName,
      userMessage,
      replyLength = "short",
      selectedTone,
      mode = "chatReply",
      profileInfo
    } = data;

    if (!personalType || !gender || !ageGroup) {
      throw new HttpsError(
        "invalid-argument",
        "必須パラメータが不足しています"
      );
    }

    // モード別のバリデーション
    if (mode === "profileGreeting") {
      if (!profileInfo && !message) {
        throw new HttpsError(
          "invalid-argument",
          "プロフィール情報またはメッセージが必要です"
        );
      }
    } else {
      if (!message) {
        throw new HttpsError(
          "invalid-argument",
          "メッセージが必要です"
        );
      }
    }

    try {
      // APIキーの確認
      const apiKey = openaiApiKey.value().trim();
      if (!apiKey) {
        console.error("OPENAI_API_KEY is not set in environment variables");
        throw new Error("OpenAI API key not configured");
      }
      console.log(`[generateReply] Mode: ${mode}`);
      console.log(`[generateReply] API Key exists: ${apiKey ? 'YES' : 'NO'}, length: ${apiKey?.length || 0}`);
      console.log(`[generateReply] Message: ${(message || '').substring(0, 50)}...`);
      console.log(`[generateReply] PersonalType: ${personalType}, Gender: ${gender}, AgeGroup: ${ageGroup}`);
      console.log(`[generateReply] PartnerName: ${partnerName || 'なし'}, UserMessage: ${userMessage || 'なし'}`);
      console.log(`[generateReply] ReplyLength: ${replyLength}`);
      console.log(`[generateReply] SelectedTone: ${selectedTone || 'なし（従来の3カテゴリ）'}`);

      // プロンプト生成
      const systemPrompt = createSystemPrompt(personalType, gender, ageGroup, replyLength, selectedTone, mode);
      const userPrompt = mode === "profileGreeting"
        ? createProfileUserPrompt(message, profileInfo, userMessage, partnerName)
        : createUserPrompt(message, relationship, userMessage, partnerName);

      // OpenAI API呼び出し
      const completion = await getOpenAIClient().chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: systemPrompt,
          },
          {
            role: "user",
            content: userPrompt,
          },
        ],
        temperature: 0.8,
        max_tokens: 1000,
        response_format: { type: "json_object" },
      });

      // レスポンス解析
      const content = completion.choices[0].message.content;
      console.log(`[generateReply] OpenAI Response: ${content.substring(0, 100)}...`);
      const replies = JSON.parse(content);

      // 利用回数を記録（本番のみ）
      let remainingToday = 999;  // DEV_MODEではダミー値
      if (!DEV_MODE) {
        await incrementUsageCount(userId);
        remainingToday = await getRemainingCount(userId);
      }

      return {
        success: true,
        replies: replies.replies,
        remainingToday: remainingToday,
      };

    } catch (error) {
      console.error("=== OpenAI API Error Details ===");
      console.error("Error Name:", error.name);
      console.error("Error Message:", error.message);
      console.error("Error Stack:", error.stack);
      console.error("Error Code:", error.code);
      console.error("Error Cause:", error.cause);
      console.error("Full Error:", JSON.stringify(error, Object.getOwnPropertyNames(error)));
      if (error.response) {
        console.error("Response Status:", error.response.status);
        console.error("Response Data:", JSON.stringify(error.response.data));
      }
      throw new HttpsError(
        "internal",
        `AI回答の生成に失敗しました: ${error.message}`
      );
    }
  });

/**
 * Rate Limitチェック
 */
async function checkRateLimit(userId) {
  const today = getTodayString();
  const usageRef = db.collection("usage").doc(`${userId}_${today}`);
  const usageDoc = await usageRef.get();

  if (!usageDoc.exists) {
    return true;
  }

  const usage = usageDoc.data();
  const isPremium = await checkPremiumStatus(userId);
  const limit = isPremium ? PREMIUM_LIMIT : DAILY_FREE_LIMIT;

  return usage.count < limit;
}

/**
 * 利用回数をインクリメント
 */
async function incrementUsageCount(userId) {
  const today = getTodayString();
  const usageRef = db.collection("usage").doc(`${userId}_${today}`);

  await usageRef.set({
    count: admin.firestore.FieldValue.increment(1),
    lastUsed: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

/**
 * 残り利用回数を取得
 */
async function getRemainingCount(userId) {
  const today = getTodayString();
  const usageRef = db.collection("usage").doc(`${userId}_${today}`);
  const usageDoc = await usageRef.get();

  const isPremium = await checkPremiumStatus(userId);
  const limit = isPremium ? PREMIUM_LIMIT : DAILY_FREE_LIMIT;

  if (!usageDoc.exists) {
    return limit;
  }

  return Math.max(0, limit - usageDoc.data().count);
}

/**
 * プレミアムステータスチェック
 */
async function checkPremiumStatus(userId) {
  // DEV_MODEでは Firestore 参照をスキップ（NOT_FOUND 対策）
  if (DEV_MODE) {
    console.log(`[DEV MODE] Skipping premium status check for: ${userId}`);
    return false;
  }

  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    return false;
  }

  return userDoc.data().isPremium === true;
}

/**
 * 今日の日付文字列を取得（YYYY-MM-DD）
 */
function getTodayString() {
  const now = new Date();
  return now.toISOString().split("T")[0];
}

/**
 * システムプロンプト生成
 */
function createSystemPrompt(personalType, gender, ageGroup, replyLength = "short", selectedTone = null, mode = "chatReply") {
  const personalDescriptions = {
    "知的系": "博識で論理的。知的な語彙を使い、スマートな会話を展開する。",
    "熱血系": "情熱的でエネルギーに溢れている。ストレートな表現を好み、相手を引っ張る。",
    "優しい系": "とにかく優しく、包容力がある。相手を肯定し、安心感を与える言葉を選ぶ。",
    "おもしろ系": "ユーモアセンス抜群。ボケやツッコミを交え、相手を笑わせることを最優先する。",
    "クール系": "感情を表に出しすぎず、余裕がある。短文で核心を突く、ミステリアスな色気を持つ。",
    "誠実系": "嘘をつかない誠実さ。丁寧な言葉遣いで、真剣に向き合う姿勢を見せる。",
    "アクティブ系": "フットワークが軽く、ノリが良い。絵文字も適度に使い、明るくテンポ良い会話をする。",
    "シャイ系": "少し奥手で謙虚。丁寧すぎるくらい丁寧だが、そこが可愛げに見えるように。",
    "ミステリアス系": "生活感を見せない。詩的な表現や、意味深な言葉で相手の興味を惹く。",
    "ナチュラル系": "飾らない等身大。親しみやすく、友達のような距離感でリラックスして話す。",
  };

  const lengthInstruction = replyLength === "long"
    ? "長文モード：各返信は3行程度（50〜80文字）で作成すること"
    : "短文モード：各返信は1行（30文字以内）で作成すること。絶対に30文字を超えないこと";

  const toneLabels = {
    "safe": "安牌",
    "aggressive": "ちょい攻め",
    "unique": "変化球"
  };

  const toneDefinitions = {
    "safe": "無難で失敗しない。相手に共感し、会話を維持する。",
    "aggressive": "好意を匂わせる。デートに誘う。距離を一歩縮める。",
    "unique": "相手の予想を裏切る。笑いを取る。鋭い視点やツッコミ。"
  };

  // selectedTone指定時: 同一カテゴリ3バリエーション
  // 未指定時: 従来の3カテゴリ各1案（後方互換性）
  const outputRule = selectedTone
    ? `【出力ルール】
- 指定カテゴリ「${toneLabels[selectedTone] || selectedTone}」の返信を3つのバリエーションで作成すること。
- カテゴリの定義: ${toneDefinitions[selectedTone] || ""}
- バリエーションの軸: A=王道アプローチ, B=語調や雰囲気を変えたアプローチ, C=異なる切り口のアプローチ
- 3案それぞれが明確に異なるアプローチであること。似た表現の使い回しは禁止。
- 長さは「${lengthInstruction}」とし、LINEやチャットとして自然なテンポにすること。
- 必ず以下のJSON形式のみを出力すること。前置きや挨拶は一切不要。

【JSONフォーマット】
{
  "replies": [
    {"type": "${selectedTone}", "text": "（バリエーションA）", "reasoning": "（解説）"},
    {"type": "${selectedTone}", "text": "（バリエーションB）", "reasoning": "（解説）"},
    {"type": "${selectedTone}", "text": "（バリエーションC）", "reasoning": "（解説）"}
  ]
}`
    : `【出力ルール】
- 以下の3つのカテゴリ（安牌、ちょい攻め、変化球）の返信案を作成すること。
- 長さは「${lengthInstruction}」とし、LINEやチャットとして自然なテンポにすること。
- 必ず以下のJSON形式のみを出力すること。前置きや挨拶は一切不要。

【カテゴリ定義】
1. safe (安牌): 無難で失敗しない。相手に共感し、会話を維持する。
2. aggressive (ちょい攻め): 好意を匂わせる。デートに誘う。距離を一歩縮める。
3. unique (変化球): 相手の予想を裏切る。笑いを取る。鋭い視点やツッコミ。

【JSONフォーマット】
{
  "replies": [
    {"type": "safe", "text": "（安牌な返信）", "reasoning": "（解説）"},
    {"type": "aggressive", "text": "（攻めた返信）", "reasoning": "（解説）"},
    {"type": "unique", "text": "（変化球な返信）", "reasoning": "（解説）"}
  ]
}`;

  // プロフィール挨拶モード
  if (mode === "profileGreeting") {
    return `あなたは恋愛戦略のプロフェッショナルであり、マッチングアプリのファーストメッセージの達人です。
以下の「ユーザー属性」と「性格設定」を持つ人物になりきって、相手のプロフィールに基づく魅力的な初回メッセージを作成してください。

【ユーザー属性】
- 性別: ${gender}
- 年代: ${ageGroup}

【性格設定: ${personalType}】
${personalDescriptions[personalType] || "自然体でありのまま"}

【初回メッセージの構成】
1. 自然な挨拶（「はじめまして！」等）
2. プロフィールの具体的な内容に触れる（趣味・自己紹介等）
3. 相手が答えやすい質問で締める

【重要事項】
- ユーザーの「年代」と「性別」に完全に同調した言葉遣いをすること。
- テンプレ感のない、相手のプロフィールに特化したメッセージにすること。
- 「いいね返しありがとう」のような定型句は使わないこと。
- 相手の名前がわかる場合は自然に使うこと（頻度は控えめに）。
- 文脈に合わせて、絵文字や記号を適切に使用すること。

${outputRule}`;
  }

  // チャット返信モード（既存）
  return `あなたは恋愛戦略のプロフェッショナルであり、優秀なゴーストライターです。
以下の「ユーザー属性」と「性格設定」を持つ人物になりきって、相手の心を動かす返信を考えてください。

【ユーザー属性】
- 性別: ${gender}
- 年代: ${ageGroup}

【性格設定: ${personalType}】
${personalDescriptions[personalType] || "自然体でありのまま"}

【会話分析の手順】
1. 相手のメッセージに含まれる「キーワード」を抽出
2. そのキーワードを活かした返信を心がける
3. 相手が質問している場合は、まず質問に答える
4. 話題を急に変えない

【重要事項】
- ユーザーの「年代」と「性別」に完全に同調した言葉遣いをすること。
- 若いユーザーなら若者言葉や自然な崩し方を、年配のユーザーなら落ち着いた表現を選ぶこと。
- 違和感のある「おじさん/おばさん構文」や、逆に年齢にそぐわない無理な若作りは避けること。
- 文脈に合わせて、絵文字や記号を適切に使用すること。

${outputRule}`;
}

/**
 * プロフィール挨拶用ユーザープロンプト生成
 */
function createProfileUserPrompt(message, profileInfo, userMessage, partnerName) {
  const profileText = profileInfo
    ? `【相手のプロフィール情報】
名前: ${profileInfo.name || "不明"}
年齢: ${profileInfo.age ? `${profileInfo.age}歳` : "不明"}
居住地: ${profileInfo.location || "不明"}
趣味・興味: ${profileInfo.hobbies?.join(", ") || "不明"}
自己紹介: ${profileInfo.bio || "なし"}

【プロフィール全文（OCR）】
${profileInfo.rawText || message || ""}`
    : `【プロフィール全文（OCR）】\n${message || ""}`;

  const intentContext = userMessage
    ? `\n【ユーザーの希望】\n${userMessage}\n`
    : "";

  return `${profileText}
${intentContext}
【あなたのタスク】
1. プロフィールから「話題にできるポイント」を見つけてください（趣味、自己紹介、共通点など）
2. ${partnerName ? `${partnerName}さんに向けた` : ""}初回メッセージを作成してください
3. 「挨拶 + 具体的な話題への言及 + 質問」の3段構成にしてください
4. テンプレ感がなく、このプロフィールだからこそ書ける内容にしてください

指定されたJSONフォーマットで、3パターンの初回メッセージを作成してください。`;
}

/**
 * ユーザープロンプト生成
 */
function createUserPrompt(message, relationship, userMessage, partnerName) {
  const nameContext = partnerName
    ? `相手の名前: ${partnerName}
【名前の使用ルール】
- 名前（${partnerName}）は文末の同意や誘い出しの呼びかけにのみ使用
- 頻度は3回に1回程度に抑えること
- 名前を起点にした展開や検索的な思考は禁止
`
    : "";

  const intentContext = userMessage
    ? `ユーザーの意図: ${userMessage}\n`
    : "";

  return `${nameContext}${intentContext}【会話の状況分析】
相手からのメッセージ: "${message}"
現在の関係性: ${relationship || "マッチング中"}

【あなたのタスク】
1. まず、相手のメッセージの「感情」と「真意」を分析してください
2. 相手が求めている反応を推測してください
3. ${partnerName ? `${partnerName}さんに向けた` : ""}返信を作成してください

【重要】
- 相手のメッセージに含まれるキーワードや話題を活かすこと
- 一方的に話を変えず、相手の話の流れに乗ること
- 相手が質問している場合は、まず質問に答えること

指定されたJSONフォーマットで、3パターンの返信を作成してください。`;
}
