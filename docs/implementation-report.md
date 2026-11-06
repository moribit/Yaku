# MVP実装報告

後続機能: [自由入力の役判定・用語集 追加報告](hand-explorer-and-glossary.md)。本ファイル以下は初期MVP時点の記録です。

公開URL: https://yaku-mvp.mimoc-maker.workers.dev

## Architecture / 実装ファイル

Zig 0.17.0 + Akamata 0.2.1（c332887a56065b70d4db6edb19b603715ccd7fa7）。ordinary typed handlersを単一application contractへ登録し、NativeとWorkersで同じApplicationを使用。Akamata現行guestbook・typed handler docs・cloudflare docsを参照。scaffoldの旧dependency・旧API分岐を置き換えました。

- src/main.zig、src/worker.zig: entrypoints
- src/app/contract.zig: 単一route graphとcapability contract
- src/app/handlers.zig、dto.zig: typed input / response、正解を含まないQuiz DTO
- src/mahjong/tile.zig、meld.zig、yaku.zig、yaku_catalog.zig: domainと22役
- src/quiz/question.zig、question_bank.zig、generator.zig、evaluator.zig: 問題データ、seed注入、集合採点
- web/index.html、styles.css、app.js、tiles.js、stats.js: mobile-first UI、SVG/CSS牌、version付きlocalStorage
- deploy/worker/index.mjs、wasm_dispatch.mjs: Akamata managed bridge。entry.mjs、request_limit.mjsはアプリの4 KiB body guard
- src/app/integration_test.zig、各domain内test、tests/*.test.mjs、tests/http-smoke.mjs
- docs/openapi.json、docs/client.ts、docs/capabilities.json: 生成成果物

## 収録役とQuestion数

立直、門前清自摸和、断么九、平和、一盃口、役牌、七対子、対々和、三色同順、一気通貫、混全帯么九、純全帯么九、三色同刻、三暗刻、小三元、混一色、清一色、二盃口、混老頭、国士無双、大三元、四暗刻。

35問（beginner 15 / intermediate 10 / advanced 10）。役満はCatalogのみ。primary_yakuとcorrect_yakuを分離。副露・和了牌・待ち・立直・場風／自風を明記。自動役判定engine、対局、点数計算、D1、認証はありません。

## Tests / 検証

- Zig unit + in-process application: **14 tests passed**（Debug / ReleaseSafe）。全35問の既定正解をAPIで採点。
- JavaScript: **6 tests passed**（module構文、localStorage正常／破損／version／quota、苦手順、履歴上限、Workers body guard）。
- Workers ReleaseSafe WASM build: passed。
- OpenAPI生成、TypeScript client生成、TypeScript 5.9.3 strict noEmit: passed。
- Akamata strict capability / deployment validation: passed。外部resourceなし、placeholderなし。
- Wrangler dry run: passed。
- NativeとWorkers local: HTTPで全難易度10問、unique ID、答えの事前送信なし、空／正解回答、未知ID、invalid difficulty、上限4xxを確認。
- Safari Native: Home、複数選択の正解、余分な選択／選び忘れ、10問完了、最終結果、Catalog、苦手役、再読込後の履歴保持を確認。
- 公開Workers: Home表示、Quiz開始、牌姿表示、正解回答・成立役・解説表示をSafariで確認。全難易度のHTTP smoke検証も合格。実機スマートフォンでのタッチ／font QAは未実施。

## Cloudflare deployment

2026-10-14に `akamata deploy --workers --optimize=ReleaseSafe --preflight` を実行。Worker名yaku-mvp。version ID: 875f9e6d-c55e-4b89-b9f1-faee9a5d6bc4。startup 1 ms、upload 1780.76 KiB（gzip 527.68 KiB）。URLは上記。

再deployは現行v0.2 CLIの `akamata deploy --workers`。手元PATH上のv0.1.4ではなく、今回の検証では `/Users/mimoc/Akamata/zig-out/bin/akamata` を使用しました。

## Question Bankレビューと残る作業

**問題データは人間によるルールレビューが必要。** 初期35問は実装時に分解・和了context・複合役を検討しましたが、独立した人間のルールレビューは未実施です。MVPの機能と公開は実装済みですが「人間が正解を検証済み」という教材品質条件は、この独立レビュー完了まで未達です。詳細手順と記録先はREADMEとdocs/question-review.md。

構造validationは麻雀ルールの正しさを証明しません。UI確認の際に78→9の待ち表記を両面へ修正した3問（b-06、b-14、i-08）を含め、第三者レビューで全データを確定してください。

今後の改善候補: 独立レビュー、問題拡充、苦手役限定セッション、間隔反復、牌SVGの磨き込み、必要に応じた認証／D1同期。READMEには問題追加を10段階で記載しています。
