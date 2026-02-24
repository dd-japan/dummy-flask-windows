# Datadog APM テストアプリケーション (Windows版)

Windows Server 2019 で Datadog APM 機能をテストするためのシンプルな Python Flask アプリケーションです。

## 機能

- **レイテンシテスト**: 設定可能な応答遅延エンドポイント（100ms〜5秒以上）
- **エラーテスト**: 各種HTTPエラー（400、404、500）と例外の生成
- **ネスト操作**: シンプルおよび複雑なネスト操作のテスト
- **データベースシミュレーション**: データベース操作のシミュレーション
- **Webインターフェース**: 全テストエンドポイントを実行できるユーザーフレンドリーなHTML画面

## 前提条件

- Windows Server 2019
- 管理者権限
- インターネット接続（インストール用）
- Datadog Agent（APM有効化済み）

## クイックスタート

### ステップ1: Python のインストール

**PowerShell（推奨）:**
```powershell
powershell -ExecutionPolicy Bypass -File .\install_python.ps1
```

**またはバッチファイル:**
```cmd
install_python.bat
```

### ステップ2: アプリケーションの実行

**PowerShell:**
```powershell
powershell -ExecutionPolicy Bypass -File .\run_app.ps1
```

**またはバッチファイル:**
```cmd
run_app.bat
```

## ファイル構成

| ファイル | 説明 |
|---------|------|
| `install_python.ps1` | Python 3.11 インストール用 PowerShell スクリプト |
| `install_python.bat` | Python 3.11 インストール用バッチスクリプト |
| `run_app.ps1` | アプリケーション実行用 PowerShell スクリプト |
| `run_app.bat` | アプリケーション実行用バッチスクリプト |
| `app.py` | Flask アプリケーション |
| `requirements.txt` | Python 依存パッケージ |

## スクリプトパラメータ（PowerShell）

**install_python.ps1:**
```powershell
.\install_python.ps1 [-PythonVersion "3.11.9"]
```

**run_app.ps1:**
```powershell
.\run_app.ps1 [-Port 5000] [-ServiceName "apm-test-python"] 
              [-Environment "windows-test"] [-AppVersion "1.0.0"] 
              [-RunInBackground]
```

## API エンドポイント

| エンドポイント | 説明 |
|---------------|------|
| `GET /` | Web インターフェース |
| `GET /health` | ヘルスチェック |
| `GET /latency/fast` | 100ms 遅延 |
| `GET /latency/medium` | 500ms 遅延 |
| `GET /latency/slow` | 2秒 遅延 |
| `GET /latency/very-slow` | 5秒 遅延 |
| `GET /latency/custom?delay=<ms>` | カスタム遅延 |
| `GET /error/500` | Internal Server Error |
| `GET /error/404` | Not Found Error |
| `GET /error/400` | Bad Request Error |
| `GET /error/exception` | 未処理例外 |
| `GET /error/random` | 50%の確率でエラー |
| `GET /nested/simple` | シンプルなネスト操作 |
| `GET /nested/complex` | 複雑なネスト操作 |
| `GET /nested/database` | DB操作シミュレーション |

## Web インターフェース機能

`http://localhost:5000` にアクセスすると、以下のテスト機能を持つ Web UI が表示されます：

### ヘルスチェック
アプリケーションの稼働状態を確認します。

### レイテンシテスト
- **Fast (100ms)** - 高速レスポンス
- **Medium (500ms)** - 中程度の遅延
- **Slow (2s)** - 遅いレスポンス
- **Very Slow (5s)** - 非常に遅いレスポンス
- **カスタム遅延** - 任意のミリ秒を指定可能

### エラーテスト
- **500 Internal Error** - サーバー内部エラー
- **404 Not Found** - リソース未検出エラー
- **400 Bad Request** - 不正リクエストエラー
- **Unhandled Exception** - 未処理例外
- **Random Error (50%)** - 50%の確率でエラー発生

### ネスト操作テスト
- **Simple Nested** - シンプルなネスト操作
- **Complex Nested** - 複雑な多層ネスト操作
- **Simulated DB Calls** - データベース操作シミュレーション

### 負荷テスト
複数のリクエストを同時に送信して APM の負荷時の挙動をテストします。

| オプション | 説明 |
|-----------|------|
| Fast (100ms) | 高速エンドポイントへの負荷テスト |
| Medium (500ms) | 中程度の遅延エンドポイントへの負荷テスト |
| Slow (2s) | 遅延エンドポイントへの負荷テスト |
| Error 500 | エラーレスポンスの負荷テスト |
| Random Error (50%) | ランダムエラーの負荷テスト |
| Health Check | ヘルスチェックの負荷テスト |

リクエスト数は 1〜100 の範囲で指定できます。

## Datadog APM 連携

このアプリケーションは **ddtrace** ライブラリを使用して Datadog APM と連携します。
Windows 環境では Single Step Instrumentation (SSI) がサポートされていないため、コード内で直接 ddtrace を初期化します。

### APM の仕組み

1. `ddtrace` パッケージが `requirements.txt` に含まれています
2. アプリケーションコード内で `patch_all()` を呼び出して計装を有効化
3. `patch_all()` が自動的に Flask アプリケーションを計装します
4. トレースデータは Datadog Agent に送信されます

**注意**: Windows では `ddtrace-run` コマンドは「OSError: Exec format error」エラーが発生するため、コード内での初期化方式を採用しています。

### Datadog Agent のセットアップ

1. Windows に Datadog Agent をインストール
   - https://docs.datadoghq.com/ja/agent/basic_agent_usage/windows/

2. `datadog.yaml` で APM を有効化:
   ```yaml
   apm_config:
     enabled: true
   ```

3. Datadog Agent を再起動:
   ```powershell
   Restart-Service DatadogAgent
   ```

### 環境変数

アプリケーションは以下の環境変数を設定します：

| 変数 | デフォルト値 | 説明 |
|-----|------------|------|
| `DD_SERVICE` | apm-test-python | Datadog でのサービス名 |
| `DD_ENV` | windows-test | 環境名 |
| `DD_VERSION` | 1.0.0 | アプリケーションバージョン |
| `DD_LOGS_INJECTION` | true | ログにトレースIDを注入 |
| `DD_TRACE_SAMPLE_RATE` | 1 | サンプリングレート（1=100%） |

### 手動での実行

スクリプトを使用せずに手動で実行する場合：

```cmd
set DD_SERVICE=apm-test-python
set DD_ENV=windows-test
set DD_VERSION=1.0.0
python app.py
```

**注意**: Windows では `ddtrace-run` コマンドは「OSError: Exec format error」エラーが発生するため使用できません。代わりに、コード内で `patch_all()` を呼び出すことで APM 計装を行います。

## Datadog でトレースを確認

1. Datadog にログイン
2. APM > Traces に移動
3. サービスでフィルター: `apm-test-python`
4. 環境でフィルター: `windows-test`

## トラブルシューティング

### Python インストール後に見つからない
新しいコマンドプロンプト/PowerShell ウィンドウを開いて環境変数を更新してください。

### ポートが既に使用中
ポートを変更してください：
```powershell
.\run_app.ps1 -Port 8080
```

### ファイアウォールがアクセスをブロック
管理者として実行するか、手動でルールを作成してください：
```powershell
New-NetFirewallRule -DisplayName "APM Test App" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow
```

### トレースが Datadog に表示されない

1. Datadog Agent が実行中か確認:
   ```powershell
   Get-Service DatadogAgent
   ```

2. Agent のステータスを確認:
   ```cmd
   "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status
   ```

3. APM セクションを確認して、トレースが受信されているか確認

4. Agent 設定で APM が有効になっているか確認:
   ```yaml
   apm_config:
     enabled: true
   ```

### ddtrace のインストールエラー

Visual C++ Build Tools が必要な場合があります：
1. https://visualstudio.microsoft.com/visual-cpp-build-tools/ からダウンロード
2. "Desktop development with C++" ワークロードを選択してインストール
3. `pip install ddtrace` を再実行

## 参考リンク

- [Datadog APM Python ドキュメント](https://docs.datadoghq.com/ja/tracing/trace_collection/dd_libraries/python/)
- [ddtrace PyPI](https://pypi.org/project/ddtrace/)
- [Datadog Agent Windows インストール](https://docs.datadoghq.com/ja/agent/basic_agent_usage/windows/)
