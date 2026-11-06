import { renderTile, renderHand, tileLabel } from "./tiles.js";
import {
  allTiles,
  tileKey,
  countTiles,
  equivalentCount,
  addTile,
  removeTile,
  validDraft,
  commitMeld,
  isClosed,
  makeRequest,
  editInput,
  undoInput,
  setWinningTile,
  removeMeld,
  sortedHand,
  canAddTile,
} from "./hand-input.js";
const fresh = () => ({
  hand: [],
  melds: [],
  draft: [],
  mode: "hand",
  kind: "chi",
  winningKey: null,
  options: {
    win_method: "ron",
    round_wind: "east",
    seat_wind: "south",
    riichi: "none",
    ippatsu: false,
    special: "none",
  },
  result: null,
  error: null,
});
let state = fresh();
let pending = false;
const history = [];
let chooseWinning = false;
let pinned = true;
let activeUpdate = null;
const suitNames = { man: "萬子", pin: "筒子", sou: "索子", honor: "字牌" };
const meldNames = { chi: "チー", pon: "ポン", kan: "明槓", ankan: "暗槓" };
const groupNames = {
  sequence: "順子",
  triplet: "刻子",
  quad: "槓子",
  pair: "対子",
  orphan: "么九牌",
};
const winds = [
  ["east", "東"],
  ["south", "南"],
  ["west", "西"],
  ["north", "北"],
];
export function renderAnalyzer({
  main,
  el,
  button,
  heading,
  api,
  yakuCard,
  glossaryLinks,
  catalog,
}) {
  const documentCatalog = catalog;
  activeUpdate = update;
  main.replaceChildren(
    heading(
      "HAND EXPLORER",
      "手牌を調べる",
      "① 牌を選ぶ → ② 最後の1枚と条件を指定 → ③ 役を調べる",
    ),
  );
  main.classList.add("analyzer-page");
  const selected = el("section", "builder-card input-summary");
  selected.setAttribute("aria-label", "選択済み手牌");
  const header = el("div", "builder-heading");
  const counter = el("strong", "tile-counter");
  header.append(el("h2", "", "選んだ手牌"), counter);
  const hand = el("div", "hand selected-hand");
  const modeHint = el("p", "input-mode");
  modeHint.setAttribute("role", "status");
  const actions = el("div", "builder-actions");
  const choose = button("和了牌を選択", "secondary", () => {
    chooseWinning = !chooseWinning;
    update();
  });
  const undo = button("元に戻す", "secondary", () => {
    if (undoInput(state, history)) {
      chooseWinning = false;
      changed();
      update();
    }
  });
  const clear = button("全クリア", "text-button", () =>
    edit((s) => Object.assign(s, fresh())),
  );
  const pin = button("固定を解除", "text-button", () => {
    pinned = !pinned;
    update();
  });
  const summaryTools = el("div", "summary-tools");
  summaryTools.append(choose, undo);
  actions.append(clear, pin);
  selected.append(header, hand, modeHint, summaryTools);
  main.append(selected, actions);

  const palette = el("section", "builder-card tile-palette");
  const paletteTitle = el("h2", "", "手牌に追加");
  const paletteHint = el(
    "p",
    "muted",
    "同じ牌は4枚まで。タップするたびに1枚追加します。",
  );
  palette.append(paletteTitle, paletteHint);
  const paletteButtons = [];
  for (const [suit, name] of Object.entries(suitNames)) {
    const group = el("div", "palette-group");
    group.append(el("h3", "", name));
    const row = el("div", "palette-row");
    for (const tile of allTiles.filter((t) => t.suit === suit)) {
      const b = button("", "palette-tile", () => edit((s) => addTile(s, tile)));
      b.dataset.tile = tileKey(tile);
      const count = el("span", "copy-count");
      b.append(renderTile(tile), count);
      paletteButtons.push({ b, count, tile });
      row.append(b);
    }
    group.append(row);
    palette.append(group);
  }
  main.append(palette);

  const meldSection = el("details", "builder-card meld-editor");
  meldSection.append(
    el("summary", "", "副露・暗カンを追加する（必要なときだけ）"),
  );
  meldSection.append(
    el(
      "p",
      "muted",
      "チー：同じ種類の数字3つが連続。ポン：同じ牌3枚。明カン：鳴いて同じ牌4枚。暗カン：鳴かずに作った同じ牌4枚。",
    ),
  );
  const melds = el("div", "builder-melds");
  const modes = el("div", "mode-tabs");
  const handMode = button("手牌に追加", "secondary", () =>
    edit((s) => {
      s.mode = "hand";
    }),
  );
  const meldMode = button("副露の牌を選ぶ", "secondary", () => {
    edit((s) => {
      s.mode = "meld";
    });
    palette.scrollIntoView({ block: "start", behavior: motion() });
  });
  modes.append(handMode, meldMode);
  const kind = selectControl(
    "組の種類",
    "meld-kind",
    Object.entries(meldNames),
    (value) => {
      state.kind = value;
      state.draft = [];
    },
  );
  const draft = el("div", "hand");
  const commit = button("この組を追加", "primary", () =>
    edit((s) => {
      if (commitMeld(s)) {
        if (!isClosed(s)) {
          s.options.riichi = "none";
          s.options.ippatsu = false;
        }
        s.mode = "hand";
      }
    }),
  );
  const cancelDraft = button("候補をクリア", "text-button", () =>
    edit((s) => {
      s.draft = [];
      s.mode = "hand";
    }),
  );
  const draftActions = el("div", "builder-actions");
  draftActions.append(commit, cancelDraft);
  const meldStatus = el("p", "muted");
  meldSection.append(melds, modes, kind, meldStatus);
  const draftPanel = el("div", "palette-draft");
  draftPanel.append(
    el("p", "muted", "選んだ組の候補（押すと削除）"),
    draft,
    draftActions,
  );
  palette.insertBefore(draftPanel, paletteHint.nextSibling);
  main.append(meldSection);

  const context = el("section", "builder-card");
  context.append(
    el("h2", "", "和了の条件"),
    el(
      "p",
      "muted",
      "和了牌は、手を完成させた最後の1枚です。手牌から直接選ぶか、下の一覧で指定してください。",
    ),
  );
  const form = el("fieldset", "analysis-form");
  form.setAttribute("aria-label", "和了の条件");
  const winning = selectControl(
    "和了牌（最後の1枚）",
    "winning-tile",
    [],
    (value) => setWinningTile(state, value || null),
  );
  const method = selectControl(
    "和了方法",
    "win-method",
    [
      ["ron", "ロン（他の人の捨て牌）"],
      ["tsumo", "ツモ（自分で引いた牌）"],
    ],
    (value) => {
      state.options.win_method = value;
      state.options.special = "none";
    },
  );
  const round = selectControl("場風", "round-wind", winds, (value) => {
    state.options.round_wind = value;
  });
  const seat = selectControl("自風", "seat-wind", winds, (value) => {
    state.options.seat_wind = value;
    if (["tenhou", "chiihou"].includes(state.options.special))
      state.options.special = "none";
  });
  const riichi = selectControl(
    "立直",
    "riichi",
    [
      ["none", "立直なし"],
      ["riichi", "立直"],
      ["double_riichi", "ダブル立直"],
    ],
    (value) => {
      state.options.riichi = value;
      if (value === "none") state.options.ippatsu = false;
    },
  );
  const checkbox = el("label", "analysis-checkbox");
  const ippatsu = el("input");
  ippatsu.type = "checkbox";
  ippatsu.addEventListener("change", () =>
    edit((s) => {
      s.options.ippatsu = ippatsu.checked;
    }),
  );
  checkbox.append(ippatsu, el("span", "", "一発（立直後一巡以内・鳴きなし）"));
  const special = selectControl("特別な和了状況", "special", [], (value) => {
    state.options.special = value;
    if (value === "rinshan") state.options.ippatsu = false;
  });
  form.append(winning, method, round, seat, riichi, checkbox, special);
  const contextStatus = el("p", "context-status");
  context.append(form, contextStatus);
  main.append(context);
  const examples = el("details", "analysis-examples");
  examples.append(el("summary", "", "入力例を使う（元に戻せます）"));
  const exampleButtons = el("div", "builder-actions");
  for (const [id, label, key] of [
    ["tanyao", "断么九＋平和", "sou-8"],
    ["chiitoitsu", "七対子", "honor-1"],
    ["kokushi_musou", "国士無双", "honor-1"],
  ]) {
    exampleButtons.append(
      button(label, "secondary", () =>
        edit((s) => {
          Object.assign(s, fresh());
          s.hand = structuredClone(catalog.find((y) => y.id === id).example);
          s.winningKey = key;
        }),
      ),
    );
  }
  examples.append(exampleButtons);
  main.append(examples);
  const submit = button("成立する役を調べる", "primary full", async () => {
    const payload = makeRequest(state);
    if (!payload || pending) return;
    pending = true;
    state.error = null;
    update();
    try {
      state.result = await api("/api/hand/analyze", payload);
    } catch (error) {
      state.error = error.message;
    } finally {
      pending = false;
      if (location.hash === "#analyze" && !main.contains(selected))
        activeUpdate?.();
      if (location.hash === "#analyze" && main.contains(selected)) {
        update();
        const target = results.querySelector(".analysis-result,.notice");
        if (target) {
          target.tabIndex = -1;
          target.focus({ preventScroll: true });
          target.scrollIntoView({ behavior: motion(), block: "start" });
        }
      }
    }
  });
  const validation = el("p", "muted centered");
  validation.setAttribute("role", "status");
  const results = el("div", "analysis-results");
  main.append(
    submit,
    validation,
    results,
    el(
      "p",
      "muted analysis-scope",
      "入力した和了条件に基づく学習用の判定です。点数・フリテン・立直可否・対局履歴は確認しません。ドラ・ローカル役は対象外です。",
    ),
    glossaryLinks("門前 副露 和了牌 順子 刻子 槓子 雀頭 翻"),
  );

  function motion() {
    return matchMedia("(prefers-reduced-motion: reduce)").matches
      ? "auto"
      : "smooth";
  }
  function changed() {
    state.result = null;
    state.error = null;
  }
  function edit(operation) {
    if (pending) return;
    if (editInput(state, history, operation)) changed();
    chooseWinning = false;
    update();
  }
  function selectControl(label, key, choices, change) {
    const wrapper = el("label", "form-control");
    wrapper.append(el("span", "", label));
    const select = el("select");
    select.dataset.focus = key;
    select.setAttribute("aria-label", label);
    options(select, choices);
    select.addEventListener("change", () => edit(() => change(select.value)));
    wrapper.append(select);
    return wrapper;
  }
  function options(select, choices) {
    const signature = JSON.stringify(choices);
    if (select.dataset.choices === signature) return;
    select.replaceChildren(
      ...choices.map(([id, name]) => {
        const o = el("option", "", name);
        o.value = id;
        return o;
      }),
    );
    select.dataset.choices = signature;
  }
  let handSignature, meldSignature, draftSignature, resultSignature;
  function update() {
    const active = document.activeElement;
    const focusKey = active?.dataset.focus;
    selected.classList.toggle("pinned", pinned);
    pin.textContent = pinned ? "固定を解除" : "手牌を固定";
    choose.textContent = chooseWinning
      ? "和了牌の選択をやめる"
      : "和了牌を選択";
    choose.setAttribute("aria-pressed", String(chooseWinning));
    choose.disabled = pending || !state.hand.length;
    undo.disabled = pending || !history.length;
    clear.disabled =
      pending ||
      !(
        state.hand.length ||
        state.melds.length ||
        state.draft.length ||
        state.winningKey
      );
    pin.disabled = pending;
    counter.textContent = `${equivalentCount(state)} / 14枚相当`;
    modeHint.textContent = chooseWinning
      ? "和了牌の選択中：手牌を押して指定（削除なし）"
      : `手牌を押すと1枚削除。${state.winningKey ? ` 和了牌：${tileLabel(state.hand.find((t) => tileKey(t) === state.winningKey))}` : " 最後の1枚も指定してください。"}`;
    selected.classList.toggle("choosing-winning", chooseWinning);
    const handKey = JSON.stringify([
      state.hand,
      state.winningKey,
      chooseWinning,
      pending,
    ]);
    if (handKey !== handSignature) {
      handSignature = handKey;
      hand.replaceChildren();
      let highlighted = false;
      for (const { tile, index } of sortedHand(state)) {
        const winningTile = !highlighted && tileKey(tile) === state.winningKey;
        if (winningTile) highlighted = true;
        const b = button("", "selected-tile", () => {
          if (chooseWinning) {
            edit((s) => setWinningTile(s, tileKey(tile)));
            chooseWinning = false;
            update();
          } else edit((s) => removeTile(s, index));
        });
        b.dataset.focus = `selected-${index}`;
        b.setAttribute(
          "aria-label",
          `${tileLabel(tile)}${winningTile ? "（和了牌）" : ""}を${chooseWinning ? "和了牌に指定" : "削除"}`,
        );
        b.disabled = pending;
        b.append(renderTile(tile, { winning: winningTile }));
        hand.append(b);
      }
      if (!state.hand.length)
        hand.append(el("span", "empty-hand", "下の牌をタップして追加"));
    }
    const counts = countTiles(state);
    paletteTitle.textContent =
      state.mode === "hand"
        ? "手牌に追加"
        : `${meldNames[state.kind]}の牌を選択中`;
    paletteHint.textContent =
      state.mode === "hand"
        ? "タップで1枚追加。同じ牌は副露も合わせて4枚まで。"
        : "下の牌から組を作り、パレット上部の「この組を追加」で確定してください。";
    for (const { b, count, tile } of paletteButtons) {
      const n = counts.get(tileKey(tile)) || 0;
      count.textContent = `${n} / 4`;
      b.setAttribute(
        "aria-label",
        `${tileLabel(tile)}を追加（${n}枚選択済み）`,
      );
      b.disabled = pending || !canAddTile(state, tile);
      b.classList.toggle("has-copies", n > 0);
    }
    const meldKey = JSON.stringify([state.melds, pending]);
    if (meldKey !== meldSignature) {
      meldSignature = meldKey;
      melds.replaceChildren();
      state.melds.forEach((meld, index) => {
        const row = el("div", "declared-meld");
        const tiles = el("div", "hand compact");
        renderHand(meld.tiles, tiles);
        const remove = button(
          `${meldNames[meld.kind]}を削除`,
          "text-button",
          () => edit((s) => removeMeld(s, index)),
        );
        remove.disabled = pending;
        row.append(el("strong", "", meldNames[meld.kind]), tiles, remove);
        melds.append(row);
      });
    }
    draftPanel.hidden = state.mode !== "meld" && !state.draft.length;
    const draftKey = JSON.stringify([state.draft, pending]);
    if (draftKey !== draftSignature) {
      draftSignature = draftKey;
      draft.replaceChildren();
      state.draft.forEach((tile, index) => {
        const b = button("", "selected-tile", () =>
          edit((s) => s.draft.splice(index, 1)),
        );
        b.append(renderTile(tile));
        b.disabled = pending;
        b.setAttribute("aria-label", `${tileLabel(tile)}を候補から削除`);
        b.dataset.focus = `draft-${index}`;
        draft.append(b);
      });
    }
    for (const [b, mode] of [
      [handMode, "hand"],
      [meldMode, "meld"],
    ]) {
      b.setAttribute("aria-pressed", String(state.mode === mode));
      b.classList.toggle("active", state.mode === mode);
      b.disabled = pending;
    }
    kind.querySelector("select").value = state.kind;
    kind.querySelector("select").disabled = pending;
    commit.disabled =
      pending || !validDraft(state) || equivalentCount(state) > 11;
    cancelDraft.disabled = pending || !state.draft.length;
    meldStatus.textContent =
      equivalentCount(state) > 11
        ? "組を追加するには手牌から3枚分を削除してください。"
        : state.draft.length
          ? "候補を確定またはクリアすると判定できます。カンも3枚相当で数えます。"
          : "カンは実物4枚・手の構成では3枚相当。暗カンは門前を保ちます。";
    const unique = [
      ...new Map(
        sortedHand(state).map(({ tile }) => [tileKey(tile), tile]),
      ).values(),
    ];
    const winSelect = winning.querySelector("select");
    options(winSelect, [
      ["", "最後の1枚を選択"],
      ...unique.map((t) => [tileKey(t), tileLabel(t)]),
    ]);
    winSelect.value = state.winningKey || "";
    const closed = isClosed(state);
    for (const [wrapper, value] of [
      [method, state.options.win_method],
      [round, state.options.round_wind],
      [seat, state.options.seat_wind],
      [riichi, state.options.riichi],
    ])
      wrapper.querySelector("select").value = value;
    form.disabled = pending;
    riichi.querySelector("select").disabled = !closed;
    ippatsu.checked = state.options.ippatsu;
    ippatsu.disabled = !closed || state.options.riichi === "none";
    const choices = [["none", "通常の和了"]];
    if (state.options.win_method === "tsumo") {
      choices.push(["haitei", "海底牌でのツモ"]);
      if (state.melds.some((m) => ["kan", "ankan"].includes(m.kind)))
        choices.push(["rinshan", "嶺上牌でのツモ"]);
      if (!state.melds.length && state.options.riichi === "none")
        choices.push(
          state.options.seat_wind === "east"
            ? ["tenhou", "親の最初の配牌で和了（天和）"]
            : ["chiihou", "子の鳴きなし最初のツモ（地和）"],
        );
    } else
      choices.push(
        ["houtei", "最後の打牌でのロン"],
        ["chankan", "加槓牌へのロン（槍槓）"],
      );
    if (!choices.some(([id]) => id === state.options.special))
      state.options.special = "none";
    const specialSelect = special.querySelector("select");
    options(specialSelect, choices);
    specialSelect.value = state.options.special;
    contextStatus.textContent = closed
      ? "門前：他の人の牌で組を作っていない手です（暗カンも門前）。"
      : "副露あり：門前だけの役・立直は成立しません。";
    submit.disabled = pending || !makeRequest(state);
    submit.textContent = pending ? "判定しています…" : "成立する役を調べる";
    validation.textContent = makeRequest(state)
      ? "入力できました。ボタンを押すと判定します。"
      : equivalentCount(state) !== 14
        ? `あと${14 - equivalentCount(state)}枚相当を追加してください（和了牌を含む）。`
        : state.draft.length
          ? "入力中の副露候補を確定またはクリアしてください。"
          : "和了牌を手牌か一覧から指定してください。";
    const resultKey = JSON.stringify([state.result, state.error]);
    if (resultKey !== resultSignature) {
      resultSignature = resultKey;
      results.replaceChildren();
      if (state.error) {
        const warning = el("div", "notice", state.error);
        warning.setAttribute("role", "alert");
        warning.append(
          button("和了条件を確認する", "text-button", () => {
            winSelect.focus();
            context.scrollIntoView({ behavior: motion(), block: "start" });
          }),
        );
        results.append(warning);
      }
      if (state.result) drawResult(state.result);
    }
    exampleButtons.querySelectorAll("button").forEach((b) => {
      b.disabled = pending;
    });
    if (active && !active.isConnected && focusKey) {
      const target =
        main.querySelector(`[data-focus="${focusKey}"]`) ||
        (focusKey.startsWith("selected-")
          ? hand.querySelector("button") || choose
          : cancelDraft);
      (target.disabled ? undo : target).focus({ preventScroll: true });
    }
  }
  function drawResult(result) {
    const section = el("section", "analysis-result feedback");
    section.setAttribute("aria-live", "polite");
    section.append(
      el("p", "eyebrow", "ANALYSIS RESULT"),
      el(
        "h2",
        "",
        result.status === "winning"
          ? "成立する役が見つかりました"
          : result.status === "no_yaku"
            ? "和了の形ですが、役がありません"
            : "和了の形になっていません",
      ),
      el("p", "", result.message),
    );
    if (result.patterns.length > 1)
      section.append(
        el(
          "p",
          "notice",
          "複数の分け方があります。それぞれの成立役を分けて表示します。翻数の多い順に並べていますが、最終的な点数の比較は行いません。",
        ),
      );
    result.patterns.forEach((pattern, i) => {
      const card = el("section", "analysis-pattern");
      card.append(
        el(
          "h3",
          "",
          `${result.patterns.length > 1 ? `分け方 ${i + 1} · ` : ""}${pattern.form === "seven_pairs" ? "七対子の形" : pattern.form === "thirteen_orphans" ? "国士無双の形" : "4面子＋雀頭"} · ${pattern.yakuman_count ? `${pattern.yakuman_count}役満` : `${pattern.total_han}翻`}`,
        ),
      );
      const groups = el("div", "pattern-groups");
      for (const group of pattern.groups) {
        const box = el("div", "pattern-group");
        const hand = el("div", "hand compact");
        renderHand(group.tiles, hand);
        box.append(
          hand,
          el(
            "small",
            "muted",
            `${groupNames[group.kind]}${group.kind === "quad" ? (group.concealed ? "（暗槓）" : "（明槓）") : group.kind === "triplet" ? (group.concealed ? "（暗刻）" : "（明刻）") : ""}${group.winning_group ? " · 和了牌の組" : ""}`,
          ),
        );
        groups.append(box);
      }
      card.append(groups);
      for (const match of pattern.yaku) {
        const role = el("div", "analysis-role");
        role.append(
          el(
            "h3",
            "",
            `${match.name_ja} · ${match.is_yakuman ? "役満" : `${match.han}翻`}`,
          ),
          el("p", "", match.reason),
        );
        const y = documentCatalog.find((y) => y.id === match.id);
        if (y) role.append(yakuCard(y));
        card.append(role);
      }
      section.append(card);
    });
    results.append(section);
  }
  update();
}
