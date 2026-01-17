# Vertex AI設定ガイド

## Vertex AIとは

Vertex AIはGoogle Cloud PlatformのマネージドAIサービスで、通常のGemini APIよりも高いクォータ制限とより柔軟な設定が可能です。

## 設定方法

### 1. 必要な情報の取得

Vertex AIを使用するには、以下の情報が必要です：

1. **プロジェクトID**: Google Cloud PlatformのプロジェクトID
2. **ロケーション**: リージョン（例: `us-central1`, `asia-northeast1`）
3. **認証情報**: サービスアカウントキー（JSONファイル）またはApplication Default Credentials

### 2. サービスアカウントキーの取得

1. [Google Cloud Console](https://console.cloud.google.com/)にアクセス
2. プロジェクトを選択
3. 「IAMと管理」→「サービスアカウント」に移動
4. サービスアカウントを作成または選択
5. 「キー」タブで「キーを追加」→「JSONを作成」を選択
6. ダウンロードしたJSONファイルを安全な場所に保存

### 3. 環境変数の設定

`.env`ファイルに以下の設定を追加：

```env
# APIタイプを選択（'gemini' または 'vertex'）
API_TYPE=vertex

# Vertex AI設定
VERTEX_AI_PROJECT_ID=your-project-id
VERTEX_AI_LOCATION=us-central1
VERTEX_AI_CREDENTIALS_PATH=/path/to/service-account-key.json

# または、Application Default Credentialsを使用する場合は
# VERTEX_AI_CREDENTIALS_PATHは設定不要（gcloud auth application-default loginを実行）
```

### 4. パッケージのインストール

```bash
cd scripts
.\venv\Scripts\Activate.ps1  # Windows PowerShellの場合
pip install google-cloud-aiplatform
```

### 5. 利用可能なモデル

Vertex AIで利用可能な主なモデル：

- `gemini-1.5-flash` - 高速でコスト効率が良い（推奨）
- `gemini-1.5-pro` - より高品質な生成が必要な場合
- `gemini-2.0-flash-exp` - 実験的なモデル

### 6. クォータ制限

Vertex AIのクォータ制限は通常のGemini APIよりも高く設定されています：

- **Tier 1（有料アカウント）**: 1分あたり15リクエスト、1日あたり1,500リクエスト以上
- **Tier 2以上**: さらに高いクォータが利用可能

詳細は[公式ドキュメント](https://ai.google.dev/gemini-api/docs/rate-limits?hl=ja)を参照してください。

## 使用方法

設定が完了したら、通常通り問題生成スクリプトを実行できます：

```bash
cd scripts
.\venv\Scripts\python.exe generate_static_questions.py --test --category rules --difficulty easy
```

## トラブルシューティング

### 認証エラーが発生する場合

1. サービスアカウントキーのパスが正しいか確認
2. サービスアカウントに必要な権限（Vertex AI User）が付与されているか確認
3. Application Default Credentialsを使用する場合は、`gcloud auth application-default login`を実行

### モデルが見つからないエラーが発生する場合

1. プロジェクトIDとロケーションが正しいか確認
2. Vertex AI APIが有効になっているか確認
3. モデル名が正しいか確認（`gemini-1.5-flash`など）
