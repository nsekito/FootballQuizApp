# 手動問題作成用ディレクトリ

このディレクトリには、gensparkのチャットを使用して手動で作成した問題のJSONファイルを保存します。

## ディレクトリ構造

```
manual_questions/
├── team/          # チームクイズ
│   ├── japan/     # 日本
│   │   ├── j1/    # J1リーグ
│   │   └── j2/    # J2リーグ
│   └── world/     # 海外
├── history/       # 歴史クイズ
│   ├── japan/     # 日本
│   └── world/     # 世界
├── rule/          # ルールクイズ
└── weekly/        # 週間マッチクイズ（既存のweekly_recapを使用）
```

## ファイル名規約

**形式:** `{quizType}_{difficulty}_{YYYYMMDD}.json`

**例:**
- チームクイズ: `team_easy_20260207.json`
- 歴史クイズ: `history_normal_20260207.json`
- ルールクイズ: `rule_hard_20260207.json`
- 週間マッチクイズ: `weekly_normal_20260207.json`

## 使用方法

1. gensparkのチャットで問題を生成
2. JSONファイルを適切なディレクトリに保存
3. ファイル名は `{quizType}_{difficulty}_{YYYYMMDD}.json` 形式で命名
4. `scripts/json_to_db.py` でデータベースに取り込む

詳細は `scripts/MANUAL_QUESTION_GUIDE.md` を参照してください。
