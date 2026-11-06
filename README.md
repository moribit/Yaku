# 役のノート

**公開URL:** https://yaku-mvp.mimoc-maker.workers.dev

牌姿を見て、成立している麻雀の役をすべて選び、解説から覚えるWeb教材です。麻雀ゲームではありません。対局・CPU・山・捨て牌・点数計算は実装しません。自由入力の役判定と、用語集も利用できます。

## 内容とルール

日本式の四人リーチ麻雀、喰いタンあり、ローカル役なし。赤牌とドラは出題しません。各問題は通常の和了を前提に、一発・ダブル立直・海底・河底・嶺上開花・槍槓・天和・地和を除外します。役牌は複数組成立しても選択肢1項目（翻数計算はしません）。場風・自風・門前／副露・ロン／ツモ・立直・和了牌・待ちは問題内に明示します。

Catalog: **38役**。一般的な形の役、入力条件による状況役、役満を収録。Quiz: **35問（初級15、中級10、上級10）**。各難易度10問セッション、各問4〜6候補。同一セッションに重複なし。

役の分類と喰い下がりは[Mリーグ公式ルール第9章](https://m-league.jp/about/)を参照しています。この教材は公式認定教材ではありません。

## 必要なツール

- Zig **0.17.0**（0.17.x）
- Akamata **v0.2.x CLI**。PATHの古い0.1系CLIではなく、現行リポジトリで `zig build cli -Doptimize=ReleaseSafe` して得たCLIを使います。
- Node.js 22以上（JS tests）
- Wrangler 4.x（2026-10-14以降のcompatibility dateに対応するworkerdを含む最新版推奨）

`build.zig.zon`はAkamata **0.2.1 / c332887a56065b70d4db6edb19b603715ccd7fa7**を固定しています。typed handler / application contractの現行ソースです。旧APIの互換分岐はありません。D1・認証・外部frontend frameworkは不要です。

## Native起動

```sh
zig build run
# http://localhost:8080
# PORT環境変数で変更可
```

## Workers local起動

```sh
zig build -Dbackend=workers -Doptimize=ReleaseSafe
cd deploy
wrangler dev --local
# http://localhost:8787
```

手元のWrangler 4.120.0に同梱されたworkerdは2026-08-08までしか対応しないため、検証時は `wrangler dev --local --compatibility-date 2026-08-08` を使用しました。公開構成のcompatibility_dateは2026-10-14です。最新版では通常コマンドを使用してください。

## Cloudflare deployment

```sh
akamata inspect capabilities --target=workers --strict
akamata check --quick --capabilities --target=workers --strict
akamata deploy --workers --optimize=ReleaseSafe --preflight
# 以後は akamata deploy --workers でもdeploy可能
```

Workers名は `yaku-mvp`。resource placeholder・D1 binding・migrationはありません。`deploy/worker/index.mjs` と `wasm_dispatch.mjs` はAkamata標準のmanaged bridgeです。アプリ固有の `entry.mjs` はそれを呼び、bridgeが `arrayBuffer()` を読む**前**に4 KiBのbody上限をstreamで検査します。routeはZigのcontractにのみ宣言します。

Managed filesの更新には現行CLIの `akamata sync --dry-run` で確認後 `akamata sync` を使います。アプリ独自のentryとWrangler mainを維持してください。

## テスト・API contract生成

```sh
zig build test
zig build test -Doptimize=ReleaseSafe
zig build -Dbackend=workers -Doptimize=ReleaseSafe
node tests/http-smoke.mjs http://localhost:8787
zig build run -- akamata-openapi > openapi.json
zig build run -- akamata-capabilities workers > capabilities.json
# Nativeサーバー起動中:
curl -fsS http://localhost:8080/client.ts > client.ts
# 任意: TypeScript strict検査
npx -p typescript tsc --strict --noEmit --target es2022 --lib es2022,dom client.ts
```

Zig testsはAkamata in-process clientを使用しlistener不要です。牌parsing／validation、役lookup、bank validation、難易度filter、seed再現性、choice shuffle、重複防止、集合採点・複合役、全35問の採点、API 4xx、回答前DTOの秘密field除外、OpenAPIとclient生成を検査します。公開ES modulesの構文検査も実行します。JS testsはlocalStorage破損・version差・quota failure・miss／extra統計・mistake履歴上限、およびWorkersのbody上限を検査します。

## 新しい問題を追加する方法

**問題データは人間によるルールレビューが必要**です。構造テストに合格したことと、麻雀上の正解が正しいことは別です。初期データは実装時の検討済みfixtureであり、麻雀に詳しい人による独立レビュー済みとは主張しません。レビュー状況は `docs/question-review.md` に記録してください。

すべての問題は `src/quiz/question_bank.zig` の `all` に集約します。牌姿・正解・副露・解説を隣接して記述します。Quizは静的なQuestion Bankを正解のsourceとして維持します。自由入力の役判定は `src/analysis/` に独立しており、出題用データを自動生成しません。

1. stable unique IDを付けます（例 `b-16`）。公開済み問題のIDを別問題へ再利用しないでください。
2. `difficulty` を選びます。`hand` は和了牌を含む**副露以外の牌**です。`tiles("1m 2m 3m ... east")` のcanonical notationで記述します。m=萬、p=筒、s=索、字牌=east/south/west/north/white/green/red。
3. `open_melds` をchi／pon／kanと実物の3／4枚で記述します。`hand.len + 各副露面子3枚相当 = 14` が必要です。槓子は枚数相当3でも同牌4枚をphysical countへ含めます。初期Quizに槓はありません。自由入力の暗槓は `analysis/model.zig` のankanで対応しています。Quizへ暗槓を追加する場合はQuestionモデル側にも門前を保つ表現を導入します。
4. `context` のclosed、win_method、round_wind、seat_wind、riichi、winning_tile、waitを確認します。和了牌はhandの一枚。待ちの呼び方を手牌から検証し、平和・三暗刻の条件を確認します。特殊な状況役はこのMVPでは除外。
5. `primary_yaku` には今回主に教える役、`correct_yaku` には**全成立役**を入れます。例えば三色同順＋断么九＋平和なら3役すべて。primaryはcorrectの部分集合です。
6. `distractors` に紛らわしい不成立役を追加し、correctと合わせて4〜6候補にします。catalogのstable IDだけ使用。重複・正解との重複は不可。
7. `decomposition` に人間が確認できる4面子＋雀頭／七対子の分解と、和了で完成する組を記録します。`explanation` には成立理由、複合役、紛らわしい不成立役の理由を記載します。どちらも回答前APIでは送信されません。
8. `zig build test` を通します。同牌5枚、14牌相当不成立、存在しない役ID、ID重複などを検出します。
9. 麻雀ルールに詳しい人が、別解の分解・和了牌・待ち・全複合役・食い下がり・役の排他関係を独立レビューします。記録を残してから教材として確定します。
10. 各難易度10問以上を維持します。UIは10問固定、APIは1〜10問です。

例（実在の初期問題と同じ構造）:

```zig
.{ .id = "b-16", .difficulty = .beginner,
   .hand = tiles("2m 3m 4m 4m 5m 6m 3p 4p 5p 6s 7s 8s 2p 2p"),
   .context = .{ .winning_tile = parse("8s") catch unreachable, .wait = .ryanmen },
   .primary_yaku = &.{"tanyao"},
   .correct_yaku = &.{"tanyao", "pinfu"},
   .distractors = &.{"riichi", "iipeikou", "yakuhai"},
   .decomposition = "234m / 456m / 345p / 678s / 22p。67sから8sロン。",
   .explanation = "全牌2〜8で断么九。門前4順子・非役牌雀頭・両面待ちで平和も成立。" },
```

## 新しい役を追加する方法

`src/mahjong/yaku_catalog.zig` の `all` に日本語名・読み・門前／副露翻数（副露不可はnull）・分類・成立条件・覚え方・代表牌姿を追加します。IDはstable snake_case。役満はis_yakuman=true、category=yakuman、han=null。人間によるルール確認後、必要ならQuestion Bankのprimary／correct／distractorに採用します。lookup、API、Catalog表示は同じデータを使用するため追加route不要です。

## Architecture

- `src/main.zig` / `src/worker.zig`: Native / WASMの入口と同じApplication。
- `src/app/contract.zig`: 全routeとcapability contract。OpenAPIとclientの単一source。
- `src/app/handlers.zig` / `dto.zig`: ordinary typed handlers、入力validation、正解を除いた公開DTO。
- `src/mahjong/`: Tile、Meld、YakuとCatalog。
- `src/quiz/`: 静的bank、random source注入generator、集合evaluator。
- `web/`: HTML/CSS/ES modules、独立TileRenderer、versioned stats。`web/assets.zig` moduleでembed、public assetにbankを含めません。
- `deploy/worker/`: 標準WASM glueとbody上限のapp boundary。
- `tests/`: JS tests。Zig unit/API testsは各moduleに併置。

Quiz作成DTOはID・手牌・副露・context・候補のID／名／読みのみ。解説・correct／primary・面子分解は採点後のみ。APIは未知のenum／ID／選択肢外の回答を4xxで拒否し、内部errorはgeneric 500へ変換します。回答の重複は集合として除去し、順序は無視します。

localStorageのkeyは `yaku-note.learning.v1`。schemaはversion、totalAnswered／totalCorrect、yakuStats（yakuId・shown・correct・wrong）、recentMistakes（直近100件）。shownは候補に現れた回数、correctは成立役の正選択または不成立役の正除外、wrongは選び忘れ／選びすぎ。苦手順はwrong/shown降順。保存不能時もメモリ内で継続します。将来のD1同期はこのDTOをmigration対象にできます。認証もD1も現時点では使用しません。

## 今後の改善候補

独立した問題レビュー、難易度ごとの問題拡充、苦手役に絞ったセッション、間隔反復、索子1の鳥柄など牌SVGの改善、必要になった時点で認証とD1同期。対局履歴・フリテン・点数計算・待ちやシャンテンの列挙は引き続き対象外です。

## 手牌を調べる

[自由入力画面](https://yaku-mvp.mimoc-maker.workers.dev/#analyze)で34種類の牌を選びます。副露や暗槓は「面子を追加」から別欄へ入力し、手牌との合計を14枚相当にします。和了牌を選択し、ロン／ツモ・場風・自風・立直・必要なら一発や海底などを指定します。通常は特別な和了状況を「通常の和了」のまま使います。

`POST /api/hand/analyze` はtyped DTOのhand・melds・winning_tileと和了条件を受け取り、status（winning / no_yaku / not_winning）、closed、patternsを返します。handは宣言済み面子以外の和了牌を含む牌。meldsのkindはchi / pon / kan / ankan。同じ牌は手牌・面子合わせて4枚まで。槓子は実物4枚・面子として3枚相当です。

`src/analysis/evaluator.zig` が雀頭候補と全4面子分解を探索し、和了牌をどの組に使うかも列挙します。七対子と国士無双は別形として処理します。ロンで完成した刻子は暗刻に数えず、暗槓は門前を保ちます。役牌は三元牌・場風・自風分を合計した翻数を返します。役満が成立する分け方では通常役を除き、役満同士は複合します。

複数の成立役セットがある場合は分け方別に表示します。同じ役セットの対称的な和了牌割当は1例にまとめます。翻数の多い順に表示しますが、**符・点数を計算せず、最も高い点数の分解を選ぶ機能ではありません**。役満の倍付け（四暗刻単騎・国士13面・大四喜など）は採用せず、各1役満として扱います。状況役は入力された状況を前提とし、対局履歴の実在や立直可否・フリテンを検証しません。流局時の流し満貫はこの和了手の判定対象外です。

Quizの35問を独立した期待値として一致を検査し、平和の待ち／雀頭、三暗刻と四暗刻のロン／ツモ差、七対子と二盃口の別解、槓の枚数、役満、喰い下がり、状況役、矛盾入力をunit/API testで検査します。手牌・副露入力の操作、和了牌未指定、5枚目防止はJS testsでも検査します。

## 用語集

[用語集](https://yaku-mvp.mimoc-maker.workers.dev/#glossary)は **49項目**。牌の基本・手の形・和了条件／鳴き・和了／待ち・役とルールの5分類です。用語・読み・別名・説明・例文で検索でき、関連語へ移動できます。役の解説や自由入力画面から用語へ直接参照できます（例 `#glossary/closed`）。

- `GET /api/glossary`: terms配列
- `GET /api/glossary/:id`: 用語詳細、未知のIDは404
- データ: `src/mahjong/glossary.zig`。stable ID、名前・読み・分類・定義・例・別名・関連IDを1箇所へ追加。unique IDと関連リンクをunit testで検査します。

追加ファイル: `src/analysis/model.zig` / `evaluator.zig` / `evaluator_test.zig`、`web/analyzer.js` / `hand-input.js`、`tests/hand-input.test.mjs`。各APIは既存の単一contractに登録し、4 KiB body limitと標準Workers deploy pathを使用します。


## モバイルUXとブラウザ回帰テスト

手牌入力のUndo・直接和了牌指定、モバイルの練習画面・用語補助・7役の図解を改善しました。[調査・設計・検証結果と画面比較](docs/mobile-ux.md)を参照してください。

```sh
npm ci
npx playwright install chromium webkit
npm run test:e2e
# Firefoxを実行できる環境での追加確認:
npx playwright install firefox
npm run test:e2e:firefox
```

E2EはNativeサーバーを自動起動します。8080番ポートを空けて実行してください。本番デプロイは行いません。
