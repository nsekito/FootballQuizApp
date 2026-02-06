# extreme難易度の問題に関する特別な指示と警告表示の計画

## 目的
extreme難易度の問題について、Wikipedia情報をメインに身内や関係者しか知らない情報を問題にするようプロンプトを修正し、クイズ画面に不確定情報や噂レベルの情報も含む可能性がある旨の警告を表示します。

## 実装内容

### 1. プロンプトの修正
`scripts/utils/gemini_client.py`の`generate_question`関数内のプロンプトを修正します。

#### 修正箇所
- `difficulty == 'extreme'`の場合に特別な指示を追加
- プロンプト本文にextreme難易度専用のセクションを追加

```python
# difficulty_promptsの後に追加
if difficulty == 'extreme':
    extreme_note = """
【EXTREME難易度について（重要）】
EXTREME難易度の問題は、以下の特徴を持つ問題を作成してください：

1. **情報源について**
   - Wikipedia情報をメインに使用すること
   - 一般的なサッカーファンが知らない、非常にマニアックな情報を扱うこと
   - 身内や関係者しか知らないような情報を問題にすること

2. **情報の性質について**
   - 不確定情報や噂レベルの情報も含む可能性があることを理解した上で問題を作成すること
   - 公式に確認されていない情報でも、信頼できる情報源（Wikipedia等）に記載されている場合は使用可能
   - ただし、明らかに誤情報や根拠のない情報は避けること

3. **問題の難易度**
   - 一般的なサッカーファンでは知り得ない、非常に専門的でマニアックな知識を問う問題
   - 選手の私生活、チームの内部事情、歴史的な細かいエピソードなど、深い知識を要求する問題
"""
else:
    extreme_note = ""
```

プロンプト本文の最後（diversity_noteの後）に`{extreme_note}`を追加します。

### 2. クイズ画面への警告表示
`lib/screens/quiz_screen.dart`のクイズ画面に、extreme難易度の問題の場合に警告メッセージを表示します。

#### 修正箇所（273-312行目付近）
難易度表示の下に、extreme難易度の場合のみ警告メッセージを追加します。

```dart
// 難易度の表示（recap問題の場合のみ）
if (currentQuestion.category == AppConstants.categoryMatchRecap)
  Padding(
    padding: EdgeInsets.only(
      bottom: currentQuestion.referenceDate != null &&
              currentQuestion.referenceDate!.isNotEmpty
          ? 0
          : 16,
    ),
    child: Row(
      children: [
        Container(
          // 既存の難易度表示コード
        ),
      ],
    ),
  ),

// 追加: extreme難易度の場合の警告表示
if (currentQuestion.difficulty == AppConstants.difficultyExtreme)
  Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade700,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'この問題は不確定情報や噂レベルの情報も含む可能性があります',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
```

## 注意事項
- extreme難易度の問題は、すべてのカテゴリ（rules, history, teams）に適用される
- 警告メッセージはextreme難易度の問題のみに表示される
- プロンプトの修正により、今後生成されるextreme難易度の問題は新しい方針に従う
- 既存のextreme難易度の問題には警告が表示されるが、プロンプトの変更は影響しない
