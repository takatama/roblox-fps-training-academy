# FPS Training Academy

PCゲーム初心者が、Robloxの中でFPS風の操作を練習するための小さな練習ゲームです。

## 今入っているもの

- Rojo用の基本構成
- 一人称視点
- 画面中央の照準
- チュートリアルUI
- Stage 1: 歩く練習
- Stage 2: 的クリック練習
- Stage 3: ジャンプ練習
- Stage 4: 動く的の練習
- Stage 5: 危険を避ける練習
- Stage 6: ダッシュ練習
- Stage 7: しゃがみ練習
- Stage 8: 走って止まって狙う練習
- 的クリック時のSE
- 的命中時のSEとVFX
- XP、Coins、Levelの仮管理
- leaderstats表示

## 起動手順

1. Roblox Studioを開きます。
2. Rojoを使って、このプロジェクトをStudioに同期します。
3. StudioでPlayを押します。
4. まず黄色いゴールへ進みます。
5. 次に、壁の的を10個クリックします。
6. Stage 3では、Spaceでジャンプして段差と小さな穴を越えます。
7. Stage 6では、Shiftを押しながらWでダッシュします。
8. Stage 7では、Ctrlを1回押してしゃがみ、低いトンネルを通ります。
9. Stage 8では、Shiftで走り、青い停止エリアで止まって的をクリックします。
10. `M`キーでステージ選択を開き、好きなステージへ移動できます。
11. ステージ選択を閉じるとFPS操作に戻ります。

## ファイルの見方

- `src/ReplicatedStorage/Shared`
  - ゲームの設定やステージ定義があります。
- `src/ServerScriptService/Services`
  - ステージ生成、報酬、進捗、leaderstatsを担当します。
- `src/StarterPlayer/StarterPlayerScripts/Controllers`
  - 一人称視点、照準、UI表示を担当します。
- `src/StarterGui/TrainingGui`
  - 画面UIの起動用スクリプトがあります。

## 注意

今のDataServiceは、まだ本格的な保存をしていません。
StudioのPlay確認で止まりにくいように、まずは安全な仮データで動く形にしています。

## 多言語対応

ゲーム内UIは、`src/ReplicatedStorage/Shared/Localization.lua` を通して表示しています。
RobloxのLocalizationTableが使える公開環境では、`Translator:FormatByKey()` を優先して使い、取得できない場合だけ内蔵の英語/日本語テーブルに戻ります。

翻訳データは `localization/game-localization.csv` にまとめています。
公開後はCreator DashboardのLocalization画面で、このCSVをアップロードして翻訳を管理してください。

運用の流れ:

1. Creator Dashboardで対象Experienceを開きます。
2. Localizationを開きます。
3. Source languageは英語にします。
4. `localization/game-localization.csv` をアップロードします。
5. 日本語や他言語の翻訳をDashboard側で調整します。
6. コード側では新しい文を追加するとき、`Localization.lua` とCSVの両方に同じKeyを追加します。

## 次に作るIssue案

1. DataStore保存を安全に追加する
2. Stage 9: 移動しながらクリックする練習を追加する
3. Stage 10: 左右移動しながら狙う練習を追加する
5. スタンプカードUIを追加する
6. 今日の練習ボーナスを追加する

## 見直し後のおすすめ順

ジャンプはダッシュやしゃがみより先に覚えたい基本操作なので、今後はこの順番に並べ替える予定です。

1. 歩く練習
2. 見る・狙う練習
3. ジャンプ練習
4. 動く的の練習
5. 危険を避ける練習
6. ダッシュ練習
7. しゃがみ練習
8. 走って止まって狙う練習
9. 移動しながらクリックする練習
10. 総合ミニ試験
