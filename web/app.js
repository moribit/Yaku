import { renderAnalyzer } from "./analyzer.js";
import { renderHand, renderTile, tileLabel } from "./tiles.js";
import { loadStats, recordAnswer, weakYaku } from "./stats.js";
const main = document.querySelector("main");
let glossaryTerms = null;
let glossaryRenderId = 0;
let glossaryQuery = "";
let glossaryCategory = "all";
let catalog = [],
  stats = loadStats(),
  session = null,
  busy = false,
  storageWarning = false;
const difficultyNames = {
  beginner: "初級",
  intermediate: "中級",
  advanced: "上級",
};
const windNames = { east: "東", south: "南", west: "西", north: "北" };
const waitNames = {
  ryanmen: "両面",
  kanchan: "嵌張",
  penchan: "辺張",
  shanpon: "シャンポン",
  tanki: "単騎",
};
function el(tag, cls, text) {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  if (text !== undefined) e.textContent = text;
  return e;
}
function button(text, cls, fn) {
  const b = el("button", cls, text);
  b.type = "button";
  b.addEventListener("click", fn);
  return b;
}
function yakuName(id) {
  return catalog.find((y) => y.id === id)?.name_ja || id;
}
function heading(kicker, title, description) {
  const section = el("section", "page-intro");
  section.append(el("p", "eyebrow", kicker), el("h1", "", title));
  if (description) section.append(el("p", "intro-copy", description));
  return section;
}
function focusMain() {
  main.focus({ preventScroll: true });
  window.scrollTo({ top: 0, behavior: "instant" });
}
function notice(text) {
  const n = el("p", "notice", text);
  n.setAttribute("role", "alert");
  return n;
}
async function api(path, body) {
  const response = await fetch(path, {
    method: body ? "POST" : "GET",
    headers: body ? { "Content-Type": "application/json" } : {},
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!response.ok) {
    const errorBody = await response.json().catch(() => ({}));
    const messages = {
      invalid_tile_count: "手牌と面子を合わせて14枚相当にしてください。",
      invalid_tile: "使えない牌が含まれています。牌を選び直してください。",
      missing_winning_tile: "和了牌は手牌の中から選んでください。",
      invalid_meld:
        "面子の組み合わせを確認してください。チーは連続する同色3枚、ポン・槓は同じ牌です。",
      too_many_copies: "同じ牌は、手牌と面子を合わせて4枚までです。",
      invalid_context:
        "和了条件の組み合わせを確認してください。副露した手では立直できず、特別な和了状況にはロン／ツモなどの条件があります。",
    };
    throw new Error(
      messages[errorBody.error_kind] ||
        (response.status >= 500
          ? "いま結果を確認できません。少し待ってもう一度お試しください。"
          : "入力を確認できませんでした。もう一度お試しください。"),
    );
  }
  return response.json();
}
function showStats() {
  const row = el("div", "stats-row");
  for (const [value, label] of [
    [stats.totalAnswered, "これまでの回答"],
    [
      stats.totalAnswered
        ? `${Math.round((stats.totalCorrect / stats.totalAnswered) * 100)}%`
        : "—",
      "正答率",
    ],
    [weakYaku(stats).length, "復習したい役"],
  ]) {
    const s = el("div", "stat");
    s.append(el("strong", "", String(value)), el("span", "", label));
    row.append(s);
  }
  return row;
}
function home() {
  main.replaceChildren();
  const hero = el("section", "hero");
  const copy = el("div", "hero-copy");
  copy.append(
    el("p", "eyebrow", "MAHJONG · LEARNING NOTE"),
    el("h1", "", "牌を見て、\n役がわかる。"),
    el(
      "p",
      "intro-copy",
      "一手の形から、役をひとつずつ。\n選んで、確かめて、また覚える。",
    ),
  );
  hero.append(copy);
  const illustration = el("div", "hero-illustration");
  illustration.append(el("span", "note-number", "NOTE 01 / 牌姿から学ぶ"));
  const tiles = el("div", "hand hero-hand");
  renderHand(catalog.find((y) => y.id === "tanyao").example, tiles);
  illustration.append(tiles, el("p", "", "この形に、どんな役が見えますか？"));
  hero.append(illustration);
  main.append(hero);
  const practice = el("section", "practice-card");
  practice.append(
    el("div", "practice-title", "今日の10問"),
    el("p", "", "すべての成立役を選ぶ、短い練習。"),
  );
  const select = el("select");
  select.id = "difficulty";
  select.setAttribute("aria-label", "練習の難易度");
  for (const [value, name] of Object.entries(difficultyNames)) {
    const o = el(
      "option",
      "",
      `${name} — ${value === "beginner" ? "基本の役" : value === "intermediate" ? "形の特徴をつかむ" : "複合役に挑戦"}`,
    );
    o.value = value;
    select.append(o);
  }
  practice.append(
    select,
    button(
      session && !session.done ? "練習を再開する →" : "練習する →",
      "primary",
      () =>
        session && !session.done
          ? (location.hash = "quiz")
          : startQuiz(select.value),
    ),
  );
  main.append(practice);
  const links = el("div", "home-links");
  for (const [hash, title, desc] of [
    ["catalog", "役を覚える", `${catalog.length}役の条件・覚え方・代表牌姿`],
    ["analyze", "手牌を調べる", "自由に牌を選んで、成立役を調べる"],
    ["glossary", "用語集", "牌・手の形・待ちの言葉を調べる"],
    ["weak", "苦手な役", "選び忘れた役を、もう一度"],
  ]) {
    const a = el("a", "link-card");
    a.href = `#${hash}`;
    a.append(el("h2", "", title), el("p", "", desc), el("span", "arrow", "↗"));
    links.append(a);
  }
  main.append(links);
  const learning = el("section", "learning");
  learning.append(
    el("h2", "", "あなたの学習ノート"),
    showStats(),
    el("p", "muted", "学習履歴はこのブラウザに保存されます。"),
  );
  if (storageWarning)
    learning.append(
      notice(
        "ブラウザへの保存ができません。今回の結果は画面内に保持しています。",
      ),
    );
  main.append(learning);
}
function yakuCard(y, expanded = false) {
  const details = el("details", "yaku-card");
  details.open = expanded;
  const summary = el("summary");
  const title = el("span", "");
  title.append(el("strong", "", y.name_ja), el("small", "", y.reading));
  summary.append(
    title,
    el("span", "han-badge", y.is_yakuman ? "役満" : `${y.closed_han}翻`),
  );
  details.append(summary);
  const body = el("div", "yaku-body");
  const tags = el(
    "p",
    "muted",
    y.is_yakuman
      ? `役満 · ${["kokushi_musou", "suuankou", "chuurenpoutou", "tenhou", "chiihou"].includes(y.id) ? "門前のみ" : "副露可"}`
      : `門前 ${y.closed_han}翻 / ${y.open_han === null ? "副露不可" : `副露 ${y.open_han}翻`}`,
  );
  body.append(
    tags,
    el("h3", "", "成立条件"),
    el("p", "", y.condition),
    el("p", "", y.description),
    el("div", "mnemonic", `覚え方：${y.mnemonic}`),
    el("h3", "", "代表的な牌姿"),
  );
  const hand = el("div", "hand compact");
  renderHand(y.example, hand);
  body.append(
    hand,
    el(
      "p",
      "muted",
      "形の例です。実際の成立には門前・和了方法・場風・自風・待ちなどの条件も必要です。",
    ),
  );
  body.append(glossaryLinks(`${y.condition} ${y.description}`));
  details.append(body);
  return details;
}
function catalogPage() {
  main.replaceChildren(
    heading(
      "YAKU CATALOG",
      "役を覚える",
      "条件を知って、牌姿に目を慣らす。役名を押すとノートが開きます。",
    ),
  );
  const search = el("input", "search");
  search.type = "search";
  search.placeholder = "役名・読み・覚え方で探す";
  search.setAttribute("aria-label", "役を検索");
  const list = el("div", "catalog");
  main.append(search, list);
  function draw() {
    list.replaceChildren();
    let count = 0;
    for (const [category, title] of [
      ["one_han", "1翻"],
      ["two_han", "2翻"],
      ["three_plus", "3翻以上"],
      ["yakuman", "役満"],
    ]) {
      const ys = catalog.filter(
        (y) =>
          y.category === category &&
          `${y.name_ja}${y.reading}${y.mnemonic}`
            .toLowerCase()
            .includes(search.value.toLowerCase()),
      );
      if (!ys.length) continue;
      count += ys.length;
      const group = el("section", "catalog-group");
      group.append(el("h2", "group-title", title));
      ys.forEach((y) => group.append(yakuCard(y)));
      list.append(group);
    }
    if (!count)
      list.append(
        el("p", "muted", "該当する役がありません。別の言葉で探してください。"),
      );
  }
  search.addEventListener("input", draw);
  draw();
}
function weakPage() {
  main.replaceChildren(
    heading(
      "REVIEW NOTE",
      "苦手な役",
      "選び忘れ・選びすぎの割合が高い役から、もう一度。",
    ),
  );
  const weak = weakYaku(stats);
  if (!weak.length) {
    const empty = el("section", "empty-state");
    empty.append(
      el("h2", "", "復習ノートは、ここから。"),
      el(
        "p",
        "",
        "練習で迷った役がここに集まります。まずは10問、牌を見てみましょう。",
      ),
      button("練習する →", "primary", () => startQuiz("beginner")),
    );
    main.append(empty);
    return;
  }
  for (const item of weak) {
    const y = catalog.find((y) => y.id === item.yakuId);
    if (!y) continue;
    const row = el("section", "weak-card");
    row.append(
      el(
        "p",
        "eyebrow",
        `${item.wrong} / ${item.shown} 回で迷いました · ${Math.round((item.wrong / item.shown) * 100)}%`,
      ),
      yakuCard(y),
    );
    main.append(row);
  }
  main.append(button("練習する →", "primary", () => startQuiz("beginner")));
}
async function startQuiz(difficulty) {
  if (busy) return;
  busy = true;
  main.replaceChildren(heading("PRACTICE", "10問のノートを準備しています…"));
  try {
    const data = await api("/api/quiz", { difficulty, count: 10 });
    session = {
      questions: data.questions,
      difficulty,
      index: 0,
      selected: new Set(),
      results: [],
      feedback: null,
      done: false,
    };
    location.hash = "quiz";
    quizPage();
    focusMain();
  } catch (error) {
    main.replaceChildren(
      notice(error.message),
      button("ホームへ", "secondary", () => {
        location.hash = "home";
        home();
      }),
    );
  } finally {
    busy = false;
  }
}
function handPanel(q) {
  const panel = el("section", "hand-panel");
  panel.append(
    el("p", "eyebrow", "この手に成立している役をすべて選択してください"),
  );
  const context = el("div", "context");
  for (const label of [
    q.context.closed ? "門前" : "副露あり",
    q.context.win_method === "tsumo" ? "ツモ" : "ロン",
    `場風 ${windNames[q.context.round_wind]}`,
    `自風 ${windNames[q.context.seat_wind]}`,
    q.context.riichi ? "立直宣言あり" : "立直なし",
  ])
    context.append(el("span", "context-tag", label));
  panel.append(context);
  const hand = el("div", "hand quiz-hand");
  renderHand(q.hand, hand, q.context.winning_tile);
  panel.append(hand);
  if (q.open_melds.length) {
    const melds = el("div", "melds");
    melds.append(el("span", "muted", "副露"));
    for (const m of q.open_melds) {
      const group = el("div", "hand meld");
      renderHand(m.tiles, group);
      group.append(
        el(
          "small",
          "",
          m.kind === "chi" ? "チー" : m.kind === "pon" ? "ポン" : "明槓",
        ),
      );
      melds.append(group);
    }
    panel.append(melds);
  }
  const win = el("div", "winning-info");
  win.append(
    el(
      "span",
      "",
      `和了牌：${tileLabel(q.context.winning_tile)} / ${waitNames[q.context.wait]}待ち`,
    ),
  );
  panel.append(win, el("p", "circumstances", q.context.circumstances));
  return panel;
}
function names(ids) {
  return ids.length ? ids.map(yakuName).join("・") : "選択なし";
}
function feedbackPanel(result) {
  const panel = el(
    "section",
    `feedback ${result.correct ? "success" : "review"}`,
  );
  panel.setAttribute("aria-live", "polite");
  panel.append(
    el(
      "p",
      "eyebrow",
      result.correct ? "よく見つけられました" : "この形を、もう一度覚えよう",
    ),
    el("h2", "", result.correct ? "正解です" : "解説で確かめましょう"),
  );
  const compare = el("div", "answer-comparison");
  for (const [label, ids] of [
    ["成立している役", result.correct_yaku],
    ["あなたの回答", result.selected_yaku],
    ["正しく選んだ役", result.matched_yaku],
    ["選び忘れた役", result.missed_yaku],
    ["今回成立しない役", result.extra_yaku],
  ]) {
    if (
      (label === "選び忘れた役" || label === "今回成立しない役") &&
      !ids.length
    )
      continue;
    const row = el("div");
    row.append(el("span", "muted", label), el("strong", "", names(ids)));
    compare.append(row);
  }
  panel.append(
    compare,
    el("h3", "", "この牌姿のポイント"),
    el("p", "explanation", result.explanation),
  );
  const audit = el("details", "decomposition");
  audit.append(
    el("summary", "", "面子の分け方を見る"),
    el("p", "", result.decomposition),
  );
  panel.append(audit, glossaryLinks(result.explanation));
  for (const y of result.yaku) panel.append(yakuCard(y));
  return panel;
}
function quizPage() {
  if (!session) {
    home();
    return;
  }
  if (session.done) {
    resultPage();
    return;
  }
  main.replaceChildren();
  const q = session.questions[session.index];
  const top = el("div", "quiz-top");
  top.append(
    el("p", "eyebrow", `${difficultyNames[session.difficulty]} / PRACTICE`),
    el(
      "span",
      "question-count",
      `${session.index + 1} / ${session.questions.length}`,
    ),
  );
  const progress = el("progress");
  progress.max = session.questions.length;
  progress.value = session.index;
  progress.setAttribute("aria-label", "練習の進捗");
  main.append(top, progress, handPanel(q));
  const fieldset = el("fieldset", "choices");
  const legend = el("legend", "", "成立する役をすべて選ぶ");
  fieldset.append(legend);
  fieldset.disabled = Boolean(session.feedback);
  for (const y of q.choices) {
    const label = el("label", "choice");
    const input = el("input");
    input.type = "checkbox";
    input.value = y.id;
    input.checked = session.selected.has(y.id);
    const copy = el("span");
    copy.append(el("strong", "", y.name_ja), el("small", "", y.reading));
    label.append(input, copy);
    input.addEventListener("change", () => {
      if (input.checked) session.selected.add(y.id);
      else session.selected.delete(y.id);
    });
    fieldset.append(label);
  }
  main.append(fieldset);
  if (!session.feedback) {
    const submit = button("答え合わせ", "primary full", async () => {
      if (busy) return;
      busy = true;
      submit.disabled = true;
      submit.textContent = "確認しています…";
      main.querySelector(".notice")?.remove();
      try {
        const result = await api("/api/quiz/check", {
          question_id: q.id,
          answers: [...session.selected],
        });
        session.feedback = result;
        session.results.push({ question: q, result });
        const recorded = recordAnswer(stats, q, result);
        stats = recorded.stats;
        if (!recorded.saved) storageWarning = true;
        quizPage();
        main
          .querySelector(".feedback")
          .scrollIntoView({ behavior: "smooth", block: "start" });
      } catch (error) {
        submit.before(notice(error.message));
        submit.disabled = false;
        submit.textContent = "答え合わせ";
      } finally {
        busy = false;
      }
    });
    main.append(
      submit,
      el(
        "p",
        "muted centered",
        "迷ったままでも大丈夫。解説から覚えていきましょう。",
      ),
    );
  } else {
    main.append(
      feedbackPanel(session.feedback),
      button(
        session.index === session.questions.length - 1
          ? "結果を見る →"
          : "次の問題 →",
        "primary full",
        () => {
          if (session.index === session.questions.length - 1) {
            session.done = true;
            resultPage();
          } else {
            session.index++;
            session.feedback = null;
            session.selected = new Set();
            quizPage();
          }
          focusMain();
        },
      ),
    );
  }
}
function resultPage() {
  const results = session.results;
  const correct = results.filter((r) => r.result.correct).length;
  main.replaceChildren(
    heading(
      "SESSION COMPLETE",
      "10問、おつかれさまでした。",
      "覚えた形は、次の一手につながります。",
    ),
  );
  const summary = el("section", "result-summary");
  summary.append(
    el(
      "strong",
      "result-score",
      `${Math.round((correct / results.length) * 100)}%`,
    ),
    el("p", "", `${results.length}問中 ${correct}問正解`),
  );
  main.append(summary);
  const misses = {};
  for (const { result } of results)
    for (const id of [...result.missed_yaku, ...result.extra_yaku])
      misses[id] = (misses[id] || 0) + 1;
  const weak = el("section", "session-weak");
  weak.append(
    el("h2", "", "今回、復習したい役"),
    el(
      "p",
      "",
      Object.keys(misses).length
        ? Object.entries(misses)
            .sort((a, b) => b[1] - a[1])
            .map(([id, count]) => `${yakuName(id)}（${count}回）`)
            .join("・")
        : "すべての成立役を見つけられました。",
    ),
  );
  main.append(weak);
  if (storageWarning)
    main.append(
      notice("学習履歴を保存できませんでした。この画面の結果は確認できます。"),
    );
  main.append(
    button("もう10問、練習する →", "primary full", () =>
      startQuiz(session.difficulty),
    ),
  );
  const links = el("div", "result-links");
  for (const [hash, text] of [
    ["weak", "苦手な役を復習する"],
    ["home", "ホームへ"],
  ]) {
    const a = el("a", "", text);
    a.href = `#${hash}`;
    links.append(a);
  }
  main.append(links, el("h2", "review-title", "一問ずつ振り返る"));
  results.forEach(({ question, result }, i) => {
    const detail = el("details", "result-question");
    detail.append(
      el(
        "summary",
        "",
        `${String(i + 1).padStart(2, "0")}　${result.correct ? "正解" : "復習"}　${names(result.correct_yaku)}`,
      ),
      handPanel(question),
      feedbackPanel(result),
    );
    main.append(detail);
  });
}
const commonTerms = [
  ["closed", "門前"],
  ["open", "副露"],
  ["sequence", "順子"],
  ["triplet", "刻子"],
  ["concealed_triplet", "暗刻"],
  ["quad", "槓子"],
  ["head", "雀頭"],
  ["pair", "対子"],
  ["winning_tile", "和了牌"],
  ["ryanmen", "両面"],
  ["shanpon", "シャンポン"],
  ["tanki", "単騎"],
  ["round_wind", "場風"],
  ["seat_wind", "自風"],
  ["han", "翻"],
];
function glossaryLinks(text) {
  const links = el("div", "term-links");
  const label = el("span", "muted", "言葉を調べる：");
  links.append(label);
  const matches = commonTerms
    .filter(([, word]) => text.includes(word))
    .slice(0, 8);
  for (const [id, word] of matches) {
    const a = el("a", "", word);
    a.href = `#glossary/${id}`;
    links.append(a);
  }
  if (!matches.length) {
    const a = el("a", "", "用語集を開く");
    a.href = "#glossary";
    links.append(a);
  }
  return links;
}
async function glossaryPage() {
  const renderId = ++glossaryRenderId;
  const requested = location.hash.split("/")[1] || null;
  main.replaceChildren(
    heading(
      "MAHJONG GLOSSARY",
      "用語集",
      "知らない言葉を、その場で確かめる。関連する言葉もたどれます。",
    ),
  );
  if (!glossaryTerms) {
    const loading = el("p", "loading", "用語を読み込んでいます…");
    main.append(loading);
    try {
      glossaryTerms = (await api("/api/glossary")).terms;
    } catch (error) {
      if (location.hash.startsWith("#glossary"))
        main.replaceChildren(
          notice(error.message),
          button("もう一度開く", "primary", glossaryPage),
        );
      return;
    }
    if (!location.hash.startsWith("#glossary") || renderId !== glossaryRenderId)
      return;
    loading.remove();
  }
  const categories = {
    basics: "牌の基本",
    hand: "手の形",
    context: "和了の条件・鳴き",
    winning: "和了・待ち",
    rules: "役とルール",
  };
  const toolbar = el("div", "glossary-toolbar");
  const search = el("input", "search");
  search.type = "search";
  search.placeholder = "用語・読み・説明で探す（例：両面、鳴き）";
  search.setAttribute("aria-label", "用語を検索");
  search.value = glossaryQuery;
  const select = el("select");
  select.setAttribute("aria-label", "用語の分類");
  for (const [id, name] of [
    ["all", "すべての用語"],
    ...Object.entries(categories),
  ]) {
    const o = el("option", "", name);
    o.value = id;
    select.append(o);
  }
  select.value = glossaryCategory;
  toolbar.append(search, select);
  const count = el("p", "muted");
  count.setAttribute("role", "status");
  const list = el("div", "glossary-list");
  main.append(toolbar, count, list);
  if (requested) {
    const back = el("a", "glossary-back", "← すべての用語を見る");
    back.href = "#glossary";
    main.append(back);
  }
  if (requested) {
    glossaryQuery = "";
    glossaryCategory = "all";
    search.value = "";
    select.value = "all";
  }
  function draw() {
    list.replaceChildren();
    const query = glossaryQuery.trim().toLocaleLowerCase().normalize("NFKC");
    const terms = glossaryTerms.filter(
      (term) =>
        (glossaryCategory === "all" || term.category === glossaryCategory) &&
        (!requested ||
          query !== "" ||
          glossaryCategory !== "all" ||
          term.id === requested) &&
        [
          term.name_ja,
          term.reading,
          term.definition,
          term.example,
          ...term.aliases,
        ]
          .join(" ")
          .toLocaleLowerCase()
          .normalize("NFKC")
          .includes(query),
    );
    count.textContent = `${terms.length} / ${glossaryTerms.length}項目`;
    if (!terms.length) {
      list.append(
        el(
          "p",
          "empty-state",
          "該当する用語がありません。別の言葉や分類で探してください。",
        ),
      );
      return;
    }
    for (const [id, name] of Object.entries(categories)) {
      const filtered = terms.filter((term) => term.category === id);
      if (!filtered.length) continue;
      const group = el("section", "glossary-group");
      group.append(el("h2", "group-title", name));
      for (const term of filtered) {
        const details = el("details", "glossary-term");
        details.id = `term-${term.id}`;
        details.open = term.id === requested;
        const summary = el("summary");
        const copy = el("span");
        copy.append(
          el("strong", "", term.name_ja),
          el("small", "", term.reading),
        );
        summary.append(copy, el("span", "term-toggle", "＋"));
        details.append(summary);
        const body = el("div", "term-body");
        body.append(
          el("p", "", term.definition),
          el("div", "mnemonic", `例：${term.example}`),
        );
        if (term.aliases.length)
          body.append(
            el("p", "muted", `別の呼び方：${term.aliases.join("・")}`),
          );
        const related = el("div", "term-links");
        related.append(el("span", "muted", "関連する言葉："));
        for (const id of term.related) {
          const other = glossaryTerms.find((t) => t.id === id);
          if (!other) continue;
          const a = el("a", "", other.name_ja);
          a.href = `#glossary/${id}`;
          related.append(a);
        }
        body.append(related);
        details.append(body);
        group.append(details);
      }
      list.append(group);
    }
  }
  search.addEventListener("input", () => {
    glossaryQuery = search.value;
    draw();
  });
  select.addEventListener("change", () => {
    glossaryCategory = select.value;
    draw();
  });
  draw();
  if (requested && !glossaryTerms.some((term) => term.id === requested))
    main.append(
      notice("この用語は見つかりませんでした。検索で探してください。"),
    );
}
function route() {
  if (!catalog.length) return;
  const pageHash = location.hash.startsWith("#glossary")
    ? "#glossary"
    : location.hash || "#home";
  document.querySelectorAll("nav a").forEach((a) => {
    if (a.hash === pageHash) a.setAttribute("aria-current", "page");
    else a.removeAttribute("aria-current");
  });
  switch (pageHash) {
    case "#analyze":
      renderAnalyzer({
        main,
        el,
        button,
        heading,
        api,
        yakuCard,
        glossaryLinks,
        catalog,
      });
      break;
    case "#glossary":
      glossaryPage();
      break;
    case "#catalog":
      catalogPage();
      break;
    case "#weak":
      weakPage();
      break;
    case "#quiz":
      quizPage();
      break;
    default:
      home();
  }
  focusMain();
}
window.addEventListener("hashchange", route);
async function boot() {
  try {
    catalog = (await api("/api/yaku")).yaku;
    route();
  } catch (error) {
    main.replaceChildren(
      notice(error.message),
      button("もう一度開く", "primary", boot),
    );
  }
}
boot();
