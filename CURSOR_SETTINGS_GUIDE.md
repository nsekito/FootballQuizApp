# Cursor Git認証プロバイダー警告の解決方法

## 問題
Cursor起動時に「Git認証プロバイダーがターミナルの環境に変更を加えるため、ターミナルの再起動を要求しています」という警告が表示される。

## 解決方法

### 方法1: ユーザー設定に追加（推奨）

1. Cursorで `Ctrl+Shift+P` を押す
2. 「Preferences: Open User Settings (JSON)」を選択
3. 以下の設定を追加：

```json
{
  "git.terminalAuthentication": false,
  "git.enableSmartCommit": false,
  "git.autofetch": false,
  "terminal.integrated.enablePersistentSessions": false,
  "terminal.integrated.allowWorkspaceConfiguration": false
}
```

4. Cursorを完全に再起動

### 方法2: Git拡張機能を無効化（Git機能を使わない場合）

1. Cursorで拡張機能パネルを開く（`Ctrl+Shift+X`）
2. 検索ボックスに `@builtin` と入力
3. 「Git」拡張機能を見つける
4. 設定アイコンをクリック
5. 「拡張機能を無効にする」を選択
6. Cursorを再起動

### 方法3: コマンドパレットから設定

1. `Ctrl+Shift+P` を押す
2. 「Preferences: Open Settings (UI)」を選択
3. 検索ボックスに `git.terminalAuthentication` と入力
4. 「Git: Terminal Authentication」のチェックを外す
5. Cursorを再起動

## 注意事項

- ワークスペース設定（`.vscode/settings.json`）だけでは不十分な場合があります
- ユーザー設定に追加することで、すべてのプロジェクトで有効になります
- Git機能を使う場合は、方法1または方法3を推奨します
