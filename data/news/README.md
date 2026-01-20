# ニュースクイズ データディレクトリ

このディレクトリには、ニュースクイズ用の問題データを保存します。

## ディレクトリ構造

```
data/news/
  ├── 2025/
  │   ├── domestic.json  (国内ニュース)
  │   ├── world.json     (世界ニュース)
  │   └── all.json       (すべて)
  ├── 2026/
  │   └── ...
```

## JSON形式

```json
{
  "version": "1.0",
  "generated_at": "2025-01-13T00:00:00Z",
  "category": "news",
  "year": "2025",
  "region": "domestic",
  "questions": [
    {
      "id": "news_2025_domestic_001",
      "text": "2025年のJリーグ開幕戦で初得点を決めたのは？",
      "options": ["選手A", "選手B", "選手C", "選手D"],
      "answerIndex": 0,
      "explanation": "選手Aが...",
      "trivia": "...",
      "category": "news",
      "difficulty": "normal",
      "tags": "japan,j1,2025"
    }
  ]
}
```

## GitHub Raw URL

このディレクトリのファイルは、以下のURL形式でアクセスできます：

```
https://raw.githubusercontent.com/{OWNER}/{REPO}/main/data/news/{YEAR}/{REGION}.json
```

## データ生成

`scripts/generate_news_questions.py` を使用して問題を生成します。
