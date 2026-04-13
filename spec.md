# Twist 仕様書

## 概要

### アプリの目的

Spotify のプレイリストを Apple Music のプレイリストに変換する iOS アプリを制作します。

将来的には Apple Music から Spotify など、任意の音楽サブスクリプションサービス間での相互変換にも対応することを目標としています。  
ただし、まずは **Spotify → Apple Music** の変換を優先して実現します。

### 開発の背景・原体験

X（旧 Twitter）などで音楽に詳しいユーザーが共有している Spotify のプレイリストを、Apple Music で「すぐに」聴けないことに強いフラストレーションを感じていることがきっかけです。

---

## 外部仕様

### アプリ名称

**Twist**（"translate your music" をもじった造語）

> 他により良い名称があれば提案を歓迎します。

### 差別化ポイント

類似サービスはすでに存在しますが、本アプリは以下の点で差別化を図ります。

- X などの外部アプリからタップした Spotify プレイリストの URL を本アプリで直接受け取り、Apple Music のプレイリストに変換します。
- **リンクをタップするだけで本アプリが起動する**（Universal Links / カスタム URL スキームによるディープリンク対応）ことが最大のポイントです。

### ユーザーフロー

1. ユーザーが Spotify のプレイリストリンクをタップする
2. 本アプリが起動し、Apple Music へのプレイリスト変換が自動的に開始される
3. 変換中はプログレスバーと広告エリアを表示する（広告実装は後フェーズ）
4. 変換完了後、以下の内容で Apple Music にプレイリストが作成される
   - **プレイリスト名**：Spotify のプレイリスト名をそのまま使用（重複時は `{名前}_2` のようにインクリメント）
   - **説明文（description）**：元のプレイリスト作成者の名前 + 本アプリ名（Twist）

### ホーム画面（直接起動時）

- **URL 入力フォーム**を表示し、Spotify プレイリスト URL を貼り付けて変換に進める
- ディープリンク経由での起動時は即変換を開始する

### 認証方針

| サービス | 認証 | 備考 |
|---|---|---|
| Apple Music | **必須**（MusicKit 認証） | プレイリスト作成に必要 |
| Spotify | **不要** | 公開プレイリストの読み取りのみ |

> 非公開 Spotify プレイリストは対応しない（Spotify OAuth は実装しない）

### 曲の検索・マッチング

- Apple Music に該当曲が見つからない場合は**スキップ**し、残りの曲で変換を続行する
- スキップされた曲はユーザーに通知する

### プレイリストの重複処理

- 同名のプレイリストが既に存在する場合は**別名で新規作成**する
- 命名規則：`{プレイリスト名}_2`、`{プレイリスト名}_3` … とインクリメント

### 対応環境

- **最小サポート iOS バージョン**：iOS 16 以上（MusicKit の `MusicLibrary` API が iOS 16 必須のため）
- **iPad 対応**：将来対応（初期リリースは iPhone のみ）

---

## 内部仕様

### アプリ設定

| 項目 | 値 |
|---|---|
| Bundle Identifier | `com.yourname.twist`（暫定） |
| 最小 iOS | iOS 16 |
| 表示言語 | 英語のみ（平易な単語を使用） |
| MusicKit Capability | App ID 作成後に有効化 |

### 技術スタック

| 領域 | 採用技術 |
|---|---|
| UI | SwiftUI |
| アーキテクチャ | MVVM |
| Apple Music 連携 | MusicKit（Apple 純正フレームワーク） |
| Spotify データ取得 | Spotify Web API（Client Credentials フロー） |
| 非同期処理 | Swift Concurrency（async/await） |
| 最小 iOS | iOS 16 |

---

### アーキテクチャ概要（MVVM）

```
View（SwiftUI）
  └── ViewModel（@ObservableObject / @Observable）
        ├── SpotifyService     // Spotify Web API クライアント
        ├── AppleMusicService  // MusicKit ラッパー
        └── ConversionUseCase  // 変換ロジックの統合
```

---

### 画面構成・遷移

```
HomeView（URL 入力フォーム）
  └── ConversionView（変換中：プログレスバー + 広告エリア）
        └── ResultView（変換完了：件数・スキップ曲一覧）
```

| 画面 | 役割 |
|---|---|
| `HomeView` | URL 入力フォームを表示。貼り付け後に「変換」ボタンで遷移 |
| `ConversionView` | 変換進捗をプログレスバーで表示。広告エリアを予約（初期は空） |
| `ResultView` | 成功数・スキップ曲数と曲名一覧を表示 |

> ディープリンク経由での起動時は `HomeView` をスキップし、直接 `ConversionView` に遷移する

---

### ディープリンク対応

- **方式**：カスタム URL スキーム（`twist://`）を初期実装とし、将来的に Universal Links へ移行
- iOS の「開く」アプリからのリンクタップ時、`twist://convert?url={encoded_spotify_url}` としてアプリを起動する
- `AppDelegate` / `SceneDelegate` または SwiftUI の `.onOpenURL` モディファイアで URL を受け取る

> **将来対応**：Universal Links（`https://twist.app/convert?url=...`）に移行する場合、サーバーに `apple-app-site-association` ファイルの設置が必要

---

### Spotify Web API 連携

#### 認証（Client Credentials フロー）

- Spotify Developer Dashboard でアプリ登録し、`client_id` / `client_secret` を取得
- アクセストークンの取得：

```
POST https://accounts.spotify.com/api/token
Authorization: Basic base64({client_id}:{client_secret})
Body: grant_type=client_credentials
```

- 取得したトークンは `UserDefaults` または在メモリキャッシュで管理し、有効期限（3600 秒）で自動更新する

> **注意**：MVP では `client_secret` をアプリに埋め込むが、将来的にはサーバーサイドのトークン発行エンドポイントに切り出すことを推奨

#### プレイリスト情報の取得

```
GET https://api.spotify.com/v1/playlists/{playlist_id}
Authorization: Bearer {access_token}
```

- 対応する Spotify URL フォーマット（どちらも受け付ける）：
  - `https://open.spotify.com/playlist/{playlist_id}`
  - `spotify:playlist:{playlist_id}`
- `playlist_id` の抽出：
  - https 形式 → URL パスの末尾コンポーネントを使用（クエリパラメータは除去）
  - URI 形式 → `:` で分割した 3 番目の要素を使用
- 取得するフィールド：`name`、`description`、`owner.display_name`、`tracks.items[].track`（`name`、`artists`、`album.name`）
- トラック数が 100 件を超える場合は `tracks.next` を再帰的に取得（ページネーション対応）

---

### Apple Music（MusicKit）連携

#### ユーザー認証

```swift
let status = await MusicAuthorization.request()
```

- 初回変換時に認証を要求し、拒否された場合は設定アプリへの誘導メッセージを表示する

#### 曲の検索（マッチング）

```swift
var req = MusicCatalogSearchRequest(term: "{曲名} {アーティスト名}", types: [Song.self])
req.limit = 1
let res = try await req.response()
```

- マッチ戦略：`曲名 + アーティスト名` で検索 → ヒットしない場合 `曲名 + アルバム名` で再試行 → それでもヒットしない場合はスキップ

#### プレイリストの作成

```swift
try await MusicLibrary.shared.createPlaylist(
    name: playlistName,
    description: "Created by {owner} via Twist",
    items: matchedSongs
)
```

#### 既存プレイリスト名の重複チェック

1. `MusicLibraryRequest<Playlist>` で既存プレイリスト一覧を取得
2. 同名プレイリストが存在する場合、`{名前}_2`、`{名前}_3` … と空き番を探す

---

### 変換フロー詳細

```
1. Spotify URL のバリデーション（playlist URL かチェック）
2. Spotify API でプレイリスト情報・トラック一覧を取得
3. MusicKit のユーザー認証（未認証の場合）
4. 各トラックを Apple Music のカタログで検索（**逐次**：レート制限対策のため）
   ├── ヒット → 変換リストに追加
   └── ミス  → スキップリストに追加
5. 既存プレイリスト名チェック → 重複時はインクリメントした名前を使用
6. Apple Music にプレイリストを作成
7. ResultView に遷移（成功数・スキップ曲一覧を表示）
```

- プログレスバーの進捗値：`完了曲数 / 総曲数`

---

### エラーハンドリング

- エラーメッセージは**シンプルな英文 + エラーコード**の形式で表示する
- 表示例：`Something went wrong. (ERR_SPOTIFY_401)`

| エラーコード | 状況 |
|---|---|
| `ERR_INVALID_URL` | 入力 URL が Spotify プレイリスト形式でない |
| `ERR_SPOTIFY_401` | Spotify API トークン取得失敗 |
| `ERR_SPOTIFY_404` | プレイリストが見つからない |
| `ERR_SPOTIFY_429` | Spotify API レート制限超過 |
| `ERR_SPOTIFY_NET` | Spotify API ネットワークエラー |
| `ERR_MUSIC_AUTH` | Apple Music の認証が拒否された |
| `ERR_MUSIC_CREATE` | Apple Music プレイリスト作成失敗 |
| `ERR_MUSIC_NET` | Apple Music API ネットワークエラー |

---

### プロジェクト構成

```
Twist/
├── App/
│   ├── TwistApp.swift       // エントリポイント・URL ハンドリング
│   └── ContentView.swift
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── HomeViewModel.swift
│   ├── Conversion/
│   │   ├── ConversionView.swift
│   │   └── ConversionViewModel.swift
│   └── Result/
│       ├── ResultView.swift
│       └── ResultViewModel.swift
├── Services/
│   ├── SpotifyService.swift   // Spotify Web API クライアント
│   └── AppleMusicService.swift // MusicKit ラッパー
├── UseCases/
│   └── ConversionUseCase.swift // 変換ロジック統合
└── Models/
    ├── SpotifyPlaylist.swift
    ├── SpotifyTrack.swift
    └── ConversionResult.swift
```

---

### 実装フェーズ

| フェーズ | 内容 |
|---|---|
| **Phase 1** | Spotify Web API 連携・曲情報取得 |
| **Phase 2** | MusicKit 認証・プレイリスト作成 |
| **Phase 3** | ディープリンク対応（カスタム URL スキーム） |
| **Phase 4** | HomeView の URL 入力フォーム実装 |
| **Phase 5** | ResultView・スキップ曲通知の実装 |
| **Phase 6** | 広告エリアの実装（AdMob 等） |
| **Phase 7** | Universal Links への移行・iPad 対応 |

