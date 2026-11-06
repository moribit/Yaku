# 自由入力の役判定・用語集 追加報告

2026-10-14。初期MVPに続く、ユーザー依頼の機能追加です。

## 利用画面

- 手牌を調べる: https://yaku-mvp.mimoc-maker.workers.dev/#analyze
- 用語集: https://yaku-mvp.mimoc-maker.workers.dev/#glossary

34種類の牌を自由に選択し、和了牌・ロン／ツモ・場風／自風・立直・特別な和了状況を指定できます。チー・ポン・明槓・暗槓も別欄に追加可能。同牌5枚目、未完成面子、枚数不足をUIとbackendで検査します。

4面子＋雀頭、七対子、国士無双をbackendで分解し、成立役・翻数・成立理由・牌の分け方を返します。38役対応。役牌は三元牌・場風・自風の翻数を合計。役満の分け方では通常役を除き、役満同士は複合します。複数の成立役セットがある手は、別の分け方として分離表示します。

用語集は49項目、5分類。名前・読み・別名・定義・例で検索でき、関連語を参照できます。役Catalog、Quizの解説、自由入力画面から用語への直接リンクを追加しました。

## Architecture

- src/analysis/model.zig: typed入力・出力、chi/pon/kan/ankanと和了条件
- src/analysis/evaluator.zig: bounded面子探索、和了牌の割当、38役、特殊形
- src/analysis/evaluator_test.zig: independent期待値・全35問との比較・境界テスト
- src/mahjong/glossary.zig: 全49項目、関連語・unique ID検査
- src/mahjong/yaku_catalog.zig: 22→38役。槓子の代表例では実物4枚を表示
- src/app/contract.zig、handlers.zig: 単一contractのPOST /api/hand/analyze、GET /api/glossary、GET /api/glossary/:id
- web/analyzer.js、hand-input.js: palette、面子editor、和了条件、結果表示
- web/app.js、styles.css、index.html: 用語集検索／関連語／解説からの参照、navigation
- tests/hand-input.test.mjs、tests/http-smoke.mjs: 入力・HTTP回帰検査

既存Quizは静的Question Bankを正解sourceとして維持。自由入力判定は独立moduleです。localStorage schema versionと既存35問のIDは維持しています。

## 検証

- Debug / ReleaseSafeのunit・Akamata in-process application tests合格。
- 全35問について、既定の全成立役と自由入力判定の役セット一致を検査。
- 平和の両面／嵌張／辺張／役牌雀頭、三暗刻／四暗刻のロンとツモ、七対子と二盃口の排他・別解、役牌連風、槓の14枚相当とphysical count、状況役、役満、喰い下がり、invalid contextを検査。
- JavaScript 9 tests合格。構文・牌入力・コピー上限・面子・和了牌・既存学習履歴・body guard。
- Workers ReleaseSafe build、OpenAPI、TypeScript client strict noEmit合格。
- Workers local HTTP smokeで自由入力判定、別解、用語集と関連語、未知用語404、入力4xx、全難易度Quiz回帰、body上限を確認。
- Safari Nativeで牌を1枚ずつ14枚選ぶ操作、和了牌選択、断么九＋平和の判定・面子表示、用語集への移動、検索、定義・例・関連語の表示を確認。

## 判定範囲

四人リーチ麻雀・喰いタンあり。点数・符・フリテン・立直可否・実際の対局履歴・待ち／シャンテンの列挙は対象外です。状況役は指定された状況を前提とします。倍役満は採用せず各1役満。流し満貫は流局時の役であり和了手の判定対象外。赤牌・ドラ・ローカル役は除外。

翻数の多い順に表示しますが、点数計算をしないため最も高い点数の分解を選んだという意味ではありません。同じ役セットの対称的な割当は1例にまとめます。教材の独立した人間によるルールレビューは引き続き必要です。

## Deployment

`akamata deploy --workers --optimize=ReleaseSafe --preflight` で2026-10-14に公開。Worker名 `yaku-mvp`、version ID `990701d5-54b5-410e-b6c8-b1c1fe158104`。startup 2 ms、upload 2287.02 KiB（gzip 644.59 KiB）。placeholderや新規bindingなし。

公開後のHTTP smokeで新旧APIすべて合格。Safari公開版で49項目の用語集と特定用語の直接参照、入力例からの断么九＋平和のbackend判定・成立理由・分解表示を確認しました。特定用語リンクでは対象語だけを開き、一覧へ戻るリンクを表示します。
