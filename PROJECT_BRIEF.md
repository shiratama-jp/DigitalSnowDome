# デジタルスノードーム PWA化プロジェクト仕様書

## プロジェクト概要

html製スノードームをPWA（Progressive Web App）としてまとめ、スマートフォン・タブレットのホーム画面からアプリとして起動できるようにする。

## 現状

- すべてHTML + JavaScript + CSSで構成（外部依存はGoogle Fontsのみ）
- フレームワーク未使用

## 技術方針

### PWA構成

- **フレームワーク**: React or Vue（要検討。既存HTMLをiframeで埋め込むか、コンポーネント化するか）
- **ホスト方式**: 静的ファイルホスティング（GitHub Pages, Vercel, Netlify等）
- **オフライン対応**: Service Workerでをキャッシュ
- **ホーム画面追加**: manifest.jsonでアプリアイコン・スプラッシュ画面を設定

### 最もシンプルなアプローチ（推奨）

## 開発環境

- **エディタ**: VSCode（Portable版）+ Claude Code拡張
- **言語**: HTML / CSS / JavaScript
- **テスト**: ブラウザで直接確認（Chrome DevToolsのモバイルエミュレーション活用）

## まず最初にやること

1. プロジェクトフォルダを作成し
2. manifest.json + service-worker.js を作成してPWA化
3. ローカルサーバーで動作確認（`npx serve` 等）
4. スマホでホーム画面に追加して動作確認