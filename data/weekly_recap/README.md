# Weekly Recap データディレクトリ

このディレクトリには、Weekly Recap（月曜マッチリキャップ）用の問題データを保存します。

## ファイル命名規則

- ファイル名: `YYYY-MM-DD_{leagueType}.json`（例: `2025-01-13_j1.json`, `2025-01-13_europe.json`）
- 日付は月曜日の日付を使用します
- `leagueType`は`j1`（J1リーグ）または`europe`（ヨーロッパサッカー）のいずれか

## JSON形式

```json
{
  "version": "1.0",
  "generated_at": "2025-01-13T00:00:00Z",
  "category": "match_recap",
  "league_type": "j1",
  "date": "2025-01-13",
  "questions": [
    {
      "id": "match_recap_2025_01_13_001",
      "text": "2025年1月12日の大阪ダービー、制したのは？",
      "options": ["セレッソ大阪", "ガンバ大阪", "引き分け", "試合中止"],
      "answerIndex": 0,
      "explanation": "セレッソ大阪が2-1で勝利しました。...",
      "trivia": "この試合は...",
      "category": "match_recap",
      "difficulty": "normal",
      "tags": "japan,j1,2025"
    }
  ]
}
```

## GitHub Raw URL

このディレクトリのファイルは、以下のURL形式でアクセスできます：

```
https://raw.githubusercontent.com/{OWNER}/{REPO}/main/data/weekly_recap/YYYY-MM-DD_{leagueType}.json
```

例:
- J1リーグ: `https://raw.githubusercontent.com/{OWNER}/{REPO}/main/data/weekly_recap/2025-01-13_j1.json`
- ヨーロッパサッカー: `https://raw.githubusercontent.com/{OWNER}/{REPO}/main/data/weekly_recap/2025-01-13_europe.json`

## データ生成

`scripts/generate_weekly_recap.py` を使用して問題を生成します。
