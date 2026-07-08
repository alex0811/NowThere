# NowThere

[English](README.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md)

<p align="center">
  <img src="docs/assets/nowthere-intro.png" alt="NowThere の紹介画像。macOS メニューバーに東京のタイムゾーン時計を表示している" width="900">
</p>

メニューバーはローカル時間を知っている。NowThere は「あちら」の時間も知らせます。

NowThere は、大切な 1 つのタイムゾーンを macOS のメニューバーでいつでも確認できるネイティブ時計アプリです。ローカライズされた、調整可能なメニューバータイトルを表示し、Dock には出ません。

`scripts/build-app-bundle.sh debug` | `open .build/debug/NowThere.app`

---

## なぜ NowThere？

リモートチーム、旅行、リリース、会議、友人との予定は、ローカル時間だけでは足りないことがあります。NowThere は選んだ 1 つの場所を macOS のメニューバーに置き、カレンダーや時計アプリ、ブラウザを開かずに素早く確認できる形式で表示します。

意図的に小さく作っています。選択するタイムゾーンは 1 つ、表示はコンパクト、システムのタイムゾーンを検索でき、英語、簡体字中国語、日本語の UI と必要な詳細をメニューから確認できます。

## 日常での使いどころ

- スタンドアップ、計画、引き継ぎの前に、リモートチームの都市の時刻をすぐ確認できます。
- リリース時間、クライアントとの通話、旅行、家族との予定を頭の中で換算せずに見られます。
- `仕事`、`自宅`、クライアント名などのカスタムラベルで、メニューバーを自分にとって読みやすくできます。

## ハイライト

### いつでも見える 1 つの時計

NowThere はメニューバーにコンパクトなテキスト時計を表示します。

```text
Tokyo Jul 08 Wed 12:34
```

表示は分単位の境界で更新されるため、秒ごとに動かず落ち着いて確認できます。

### システムのすべてのタイムゾーンを検索

macOS の完全なタイムゾーン一覧から選択できます。`Tokyo` のような都市名でも、`Asia/Tokyo` のような IANA 識別子でも検索できます。

### メニューバータイトルを調整

タイトルに表示する項目を個別に切り替えられます。

- City/Label
- Date
- Weekday
- Time

すべての項目を非表示にした場合は、空白にならないようアプリ名を表示します。

読み取りやすいタイトルスタイルを選べます。

- デフォルト
- 時刻を先頭
- 区切り表示
- 括弧付き

24 時間表示または 12 時間表示を選択でき、`仕事`、`自宅`、クライアント名などのカスタムラベルも追加できます。

### 自分の言語で使う

アプリの表示言語は、システム、英語、簡体字中国語、日本語から選べます。メニュー UI とメニューバータイトル内の日付/曜日は一緒に更新されます。

### クリックで詳細を確認

メニューを開くと、選択中のタイムゾーンの詳細を確認できます。

- 都市ラベル
- IANA タイムゾーン識別子
- 完全な日付
- 曜日
- 時刻
- UTC オフセット

### ネイティブ macOS

NowThere は小さな AppKit + SwiftUI メニューバーアプリです。ネイティブの `NSStatusItem` と一時的なポップオーバーを使い、設定は `UserDefaults` に保存します。ログイン時起動に対応し、`LSUIElement` アプリとしてパッケージされるため Dock には表示されません。

## インストール

署名済みのリリースビルドはまだありません。ローカルでビルドして実行してください。

```bash
scripts/build-app-bundle.sh debug
open .build/debug/NowThere.app
```

古いプロセスがすでに起動している場合：

```bash
pkill NowThere
open .build/debug/NowThere.app
```

## 動作要件

- macOS 13+
- Swift 6 ツールチェーンを含む Xcode

このプロジェクトは macOS 26.4.1 と Xcode 26.5 でビルドおよびテストされています。

## 開発者向け

実行ファイルをビルド：

```bash
swift build --product NowThere
```

テストを実行：

```bash
swift test
```

app bundle をビルド：

```bash
scripts/build-app-bundle.sh debug
```

メニューバーアプリのフラグを確認：

```bash
/usr/libexec/PlistBuddy -c "Print :LSUIElement" .build/debug/NowThere.app/Contents/Info.plist
```

期待される出力：

```text
true
```

## 現在の範囲

NowThere は現在、1 つの選択済みタイムゾーンに集中しています。複数時計、秒単位の更新、カスタム形式テンプレートにはまだ対応していません。

## License

NowThere は MIT License で公開されています。詳しくは [LICENSE](LICENSE) を参照してください。
