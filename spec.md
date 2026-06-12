# Twist 仕様書

## 概要

### アプリの目的

Spotify のプレイリストのスクリーンショットを撮影・選択すると、OCR（文字認識）で楽曲名とアーティスト名を自動抽出し、Apple Music のプレイリストに変換する iOS アプリです。

将来的には Apple Music から Spotify など、任意の音楽サブスクリプションサービス間での相互変換にも対応することを目標としています。

### 開発の背景・原体験

X（旧 Twitter）などで音楽に詳しいユーザーが共有している Spotify のプレイリストを、Apple Music で「すぐに」聴けないことに強いフラストレーションを感じていることがきっかけです。

---

## 外部仕様

### アプリ名称

**Twist**

### 差別化ポイント

類似サービスはすでに存在しますが、本アプリは以下の点で差別化を図ります。

- **Spotify アカウント不要**：スクリーンショットを使うため、Spotify のログインや API 連携が一切不要
- Spotify のプレイリスト画面をスクショするだけで Apple Music に変換できる
- **シンプルな操作**：画像を選ぶ → タップ → 完了

### ユーザーフロー

1. ユーザーが Spotify アプリでプレイリスト画面をスクリーンショット撮影する
2. Twist を起動し、スクリーンショットを選択する
3. OCR が楽曲名・アーティスト名を自動抽出する
4. Apple Music で曲を検索し、プレイリストを作成する
5. 変換完了後、以下の内容で Apple Music にプレイリストが作成される
   - **プレイリスト名**：ユーザーが入力した名前（未入力時は "Converted Playlist"）
   - **説明文**：本アプリ名（Twist）経由で作成された旨

### ホーム画面

- **画像ピッカー**を表示し、フォトライブラリからスクリーンショットを選択する
- **プレイリスト名入力フォーム**（任意）
- 画像選択後に「変換」ボタンが有効になる

### 認証方針

| サービス | 認証 | 備考 |
|---|---|---|
| Apple Music | **必須**（MusicKit 認証） | プレイリスト作成に必要 |
| Spotify | **不要** | スクリーンショット OCR で対応 |

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
| Bundle Identifier | `com.n2o.twist` |
| 最小 iOS | iOS 16 |
| 表示言語 | 英語のみ（平易な単語を使用） |
| MusicKit Capability | App ID 作成後に有効化 |

### 技術スタック

| 領域 | 採用技術 |
|---|---|
| UI | SwiftUI |
| アーキテクチャ | MVVM |
| Apple Music 連携 | MusicKit（Apple 純正フレームワーク） |
| 画像テキスト認識 | Vision フレームワーク（`VNRecognizeTextRequest`） |
| 画像選択 | PhotosUI（`PhotosPicker`） |
| 非同期処理 | Swift Concurrency（async/await） |
| 最小 iOS | iOS 16 |

---

### アーキテクチャ概要（MVVM）

```
View（SwiftUI）
  └── ViewModel（@ObservableObject / @Observable）
        ├── OCRService         // Vision フレームワーク OCR
        ├── PlaylistParser     // OCR テキスト → トラックリスト変換
        ├── AppleMusicService  // MusicKit ラッパー
        └── ConversionUseCase  // 変換ロジックの統合
```

---

### 画面構成・遷移

```
HomeView（画像選択 + プレイリスト名入力）
  └── ConversionView（変換中：プログレスバー + 広告エリア）
        └── ResultView（変換完了：件数・スキップ曲一覧）
```

| 画面 | 役割 |
|---|---|
| `HomeView` | 画像ピッカーとプレイリスト名入力を表示。画像選択後に「変換」ボタンで遷移 |
| `ConversionView` | OCR処理 → Apple Music 検索の進捗をプログレスバーで表示 |
| `ResultView` | 成功数・スキップ曲数と曲名一覧を表示 |

---

### OCR（Vision フレームワーク）連携

#### テキスト認識

```swift
let request = VNRecognizeTextRequest { request, error in ... }
request.recognitionLevel = .accurate
request.usesLanguageCorrection = false
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])
```

#### Spotify スクリーンショットのパース

Spotify リスト表示の典型的な行構造：

```
楽曲名
アーティスト名 · アルバム名
再生時間
```

パース戦略：
- `·`（中点）を含む行を「アーティスト行」と判定
- その直前行を「楽曲名」として取得
- 数字のみ・時間形式（`3:45`）・メタデータ行（"songs", "min" 等）はスキップ

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

- マッチ戦略：`曲名 + アーティスト名` で検索 → ヒットしない場合 `曲名` のみで再試行 → それでもヒットしない場合はスキップ

#### プレイリストの作成

```swift
try await MusicLibrary.shared.createPlaylist(
    name: playlistName,
    description: "Created via Twist",
    items: matchedSongs
)
```

#### 既存プレイリスト名の重複チェック

1. `MusicLibraryRequest<Playlist>` で既存プレイリスト一覧を取得
2. 同名プレイリストが存在する場合、`{名前}_2`、`{名前}_3` … と空き番を探す

---

### 変換フロー詳細

```
1. ユーザーがスクリーンショット画像を選択
2. Vision OCR で楽曲名・アーティスト名を抽出
3. 認識されたトラック数が 0 の場合はエラー表示
4. MusicKit のユーザー認証（未認証の場合）
5. 各トラックを Apple Music のカタログで検索（逐次）
   ├── ヒット → 変換リストに追加
   └── ミス  → スキップリストに追加
6. 既存プレイリスト名チェック → 重複時はインクリメントした名前を使用
7. Apple Music にプレイリストを作成
8. ResultView に遷移（成功数・スキップ曲一覧を表示）
```

- プログレスバーの進捗値：`完了曲数 / 総曲数`

---

### エラーハンドリング

- エラーメッセージは**シンプルな英文 + エラーコード**の形式で表示する

| エラーコード | 状況 |
|---|---|
| `ERR_OCR_FAILED` | 画像からのテキスト認識に失敗 |
| `ERR_NO_TRACKS` | OCR は成功したが楽曲が1件も認識されなかった |
| `ERR_MUSIC_AUTH` | Apple Music の認証が拒否された |
| `ERR_MUSIC_CREATE` | Apple Music プレイリスト作成失敗 |
| `ERR_MUSIC_NET` | Apple Music API ネットワークエラー |

---

### プロジェクト構成

```
Twist/
├── App/
│   └── TwistApp.swift
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── HomeViewModel.swift
│   ├── Conversion/
│   │   ├── ConversionView.swift
│   │   └── ConversionViewModel.swift
│   └── Result/
│       └── ResultView.swift
├── Services/
│   ├── OCRService.swift        // Vision OCR
│   ├── PlaylistParser.swift    // OCR テキスト解析
│   └── AppleMusicService.swift // MusicKit ラッパー
├── UseCases/
│   └── ConversionUseCase.swift
└── Models/
    ├── RecognizedTrack.swift
    └── ConversionResult.swift
```

---

### 実装フェーズ

| フェーズ | 内容 |
|---|---|
| **Phase 1** | OCR・PlaylistParser 実装 |
| **Phase 2** | MusicKit 認証・プレイリスト作成 |
| **Phase 3** | HomeView 画像ピッカー実装 |
| **Phase 4** | ResultView・スキップ曲通知の実装 |
| **Phase 5** | 広告エリアの実装（AdMob 等） |
| **Phase 6** | iPad 対応 |

