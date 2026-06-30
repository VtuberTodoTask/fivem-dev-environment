# FiveM 開発環境

Docker Compose を使用した FiveM (txAdmin) + MariaDB の開発環境です。
1コマンドで FiveM サーバーとデータベースを起動できます。

## 構成

| サービス | イメージ | 説明 | ポート |
|---------|---------|------|-------|
| `fivem` | カスタムビルド (Dockerfile) | FiveM サーバー + txAdmin (FXServer 最新版) | 30120 (ゲーム), 40120 (txAdmin UI) |
| `mariadb` | [mariadb:11](https://hub.docker.com/_/mariadb) | MariaDB データベース | 3306 |

## 前提条件

- [Docker](https://docs.docker.com/get-docker/) がインストール済み
- [Docker Compose](https://docs.docker.com/compose/install/) v2 以上
- FiveM ライセンスキー（[Cfx.re Keymaster](https://keymaster.fivem.net/) から無料で取得可能）
  - ライセンスキーは txAdmin の Web UI から設定します

## セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/VtuberTodoTask/fivem-dev-environment.git
cd fivem-dev-environment
```

### 2. 環境変数の設定

```bash
cp .env.example .env
```

必要に応じて `.env` ファイルを編集してください。デフォルト設定のままでも起動できます。

### 3. 起動

```bash
docker compose up -d --build
```

これだけで FiveM サーバー（txAdmin）と MariaDB が起動します。
初回は Docker イメージのビルドが行われるため、数分かかる場合があります。

### 4. txAdmin の初期設定

1. ブラウザで `http://localhost:40120` にアクセス
2. txAdmin の初期設定ウィザードに従って設定
3. サーバーの `server.cfg` にデータベース接続文字列を追加:

```cfg
set mysql_connection_string "mysql://fivem:fivem_pass@mariadb:3306/fivem?charset=utf8mb4"
```

> **注意:** ユーザー名・パスワード・データベース名は `.env` の設定に合わせてください。

## 使い方

### 基本コマンド

```bash
# 起動
docker compose up -d

# 停止
docker compose down

# ログ確認
docker compose logs -f

# FiveM サーバーのログのみ
docker compose logs -f fivem

# MariaDB のログのみ
docker compose logs -f mariadb

# 再起動
docker compose restart

# 完全にリセット（データも削除）
docker compose down -v
```

### リソースの追加

`resources/` ディレクトリにFiveM リソースを配置してください。
このディレクトリは FiveM サーバーの `/config/resources` に読み取り専用でマウントされます。

#### Qbox リソース一式を配置する場合

[fivem_resources](https://github.com/VtuberTodoTask/fivem_resources) リポジトリの内容を `resources/` に配置します:

```bash
# resources/ ディレクトリに直接クローン
git clone https://github.com/VtuberTodoTask/fivem_resources.git resources_tmp
cp -r resources_tmp/* resources/
rm -rf resources_tmp
```

配置後の `resources/` ディレクトリ構成:
```
resources/
├── [assets]/
├── [cfx-default]/
├── [jg]/
├── [npwd-apps]/
├── [npwd]/
├── [ox]/
├── [qbx]/
├── [standalone]/
├── [vehicles]/
├── [voice]/
└── [wasabi]/
```

#### 個別のリソースを追加する場合

```bash
# 例: renzu_garage を追加
cd resources
git clone https://github.com/VtuberTodoTask/renzu_garage.git
```

### データベースの初期化SQL

`init-sql/` ディレクトリに `.sql` ファイルを配置すると、
MariaDB コンテナの**初回起動時**に自動的に実行されます。

ファイル名のアルファベット順に実行されるため、番号プレフィックスの使用を推奨します:

```
init-sql/
├── 00_init.sql          # 基本設定
├── 01_qbcore.sql        # QBCore テーブル
└── 02_renzu_garage.sql  # renzu_garage テーブル
```

> **注意:** 初期化SQLは初回起動時のみ実行されます。
> データベースをリセットしたい場合は `docker compose down -v` でボリュームを削除してから再起動してください。

### MariaDB への直接接続

```bash
# コンテナ内のmysqlクライアントを使用
docker compose exec mariadb mariadb -u fivem -pfivem_pass fivem

# ホストからの接続（mysql クライアントが必要）
mysql -h 127.0.0.1 -P 3306 -u fivem -pfivem_pass fivem
```

## ディレクトリ構成

```
fivem-dev-environment/
├── Dockerfile            # FXServer カスタムビルド
├── entrypoint.sh         # コンテナエントリポイント
├── server.cfg            # FXServer デフォルト設定
├── docker-compose.yml    # Docker Compose 設定
├── .env.example          # 環境変数テンプレート
├── .env                  # 環境変数（gitignore対象）
├── init-sql/             # DB初期化SQL
│   └── 00_init.sql
├── resources/            # FiveM リソース配置先
│   └── .gitkeep
├── server-data/          # FXServerデータ（自動生成・gitignore対象）
├── txData/               # txAdmin設定・データ（自動生成・gitignore対象）
└── README.md
```

> `server-data/` と `txData/` は初回起動時に自動生成されます。
> これらのディレクトリはホストに直接マウントされるため、コンテナを削除してもデータは保持されます。

## トラブルシューティング

### Windows/WSL でファイルの権限エラーが出る

`txData/` や `server-data/` 内のファイルを変更・移動できない場合、コンテナ内プロセスのUID/GIDがホストユーザーと一致していない可能性があります。

`.env` で `PUID` / `PGID` をホストユーザーに合わせてください:

```bash
# WSL ターミナルで自分のUID/GIDを確認
id -u  # → 例: 1000
id -g  # → 例: 1000
```

`.env` に設定:
```bash
PUID=1000
PGID=1000
```

設定後、コンテナを再起動してください:
```bash
docker compose down
rm -rf server-data/ txData/   # 既存データを削除（権限修正のため）
docker compose up -d --build
```

### txAdmin にアクセスできない

- `docker compose ps` でコンテナが起動しているか確認
- `docker compose logs fivem` でエラーログを確認
- ファイアウォールでポート 40120 が開放されているか確認

### FXServer のバージョンを変更したい

`.env` に以下を追加して再ビルドしてください:

```bash
# バージョンは https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ で確認
FIVEM_VERSION=29586-3284e7bf7ac848fcf3ccd51432279fdc3a76245b
docker compose up -d --build
```

### MariaDB に接続できない

- `docker compose logs mariadb` でエラーログを確認
- MariaDB の起動完了を待ってから接続してください（ヘルスチェックで自動管理されます）

### データをリセットしたい

```bash
docker compose down -v            # コンテナとDBボリュームを削除
rm -rf server-data/ txData/       # FXServer・txAdminのデータを削除
docker compose up -d --build      # 再起動（全て初期化されます）
```

## ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。
