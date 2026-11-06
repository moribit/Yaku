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
  function changed() {
    state.result = null;
    state.error = null;
  }
  function refresh() {
    if (location.hash !== "#analyze") return;
    const focus = document.activeElement?.dataset.focus;
    draw();
    if (focus)
      main
        .querySelector(`[data-focus="${focus}"]`)
        ?.focus({ preventScroll: true });
  }
  function selectControl(label, key, choices, value, onChange) {
    const wrapper = el("label", "form-control");
    wrapper.append(el("span", "", label));
    const select = el("select");
    select.dataset.focus = key;
    select.setAttribute("aria-label", label);
    for (const [id, name] of choices) {
      const option = el("option", "", name);
      option.value = id;
      select.append(option);
    }
    select.value = value;
    select.addEventListener("change", () => {
      onChange(select.value);
      changed();
      refresh();
    });
    wrapper.append(select);
    return wrapper;
  }
  function draw() {
    main.replaceChildren(
      heading(
        "HAND EXPLORER",
        "手牌を調べる",
        "牌を自由に選んで、成立する役とその理由を確かめましょう。",
      ),
    );
    const steps = el(
      "p",
      "analyzer-guide",
      "① 牌を14枚相当選ぶ　② 和了牌と条件を指定　③ 役を調べる",
    );
    main.append(steps);
    const selected = el("section", "builder-card");
    const header = el("div", "builder-heading");
    header.append(
      el("h2", "", "選んだ牌"),
      el("strong", "tile-counter", `${equivalentCount(state)} / 14枚相当`),
    );
    selected.append(header);
    selected.append(
      el(
        "p",
        "muted",
        "和了牌を含めて選んでください。選択済みの牌を押すと1枚取り消せます。",
      ),
    );
    const hand = el("div", "hand selected-hand");
    state.hand.forEach((tile, i) => {
      const b = button("", "selected-tile", () => {
        removeTile(state, i);
        changed();
        refresh();
      });
      b.append(
        renderTile(tile, { winning: tileKey(tile) === state.winningKey }),
      );
      b.setAttribute("aria-label", `${tileLabel(tile)}を取り消す`);
      b.dataset.focus = `selected-${i}`;
      b.disabled = pending;
      hand.append(b);
    });
    if (!state.hand.length)
      hand.append(el("span", "empty-hand", "下の牌一覧から選択してください。"));
    selected.append(hand);
    if (state.melds.length) {
      const melds = el("div", "builder-melds");
      state.melds.forEach((meld, i) => {
        const row = el("div", "declared-meld");
        const tiles = el("div", "hand");
        renderHand(meld.tiles, tiles);
        row.append(
          el("span", "muted", meldNames[meld.kind]),
          tiles,
          button("取り消す", "text-button", () => {
            state.melds.splice(i, 1);
            changed();
            refresh();
          }),
        );
        melds.append(row);
      });
      selected.append(melds);
    }
    const controls = el("div", "builder-actions");
    controls.append(
      button("一枚戻す", "secondary", () => {
        removeTile(state, state.hand.length - 1);
        changed();
        refresh();
      }),
      button("すべてクリア", "text-button", () => {
        state = fresh();
        refresh();
      }),
    );
    for (const b of controls.querySelectorAll("button")) b.disabled = pending;
    selected.append(controls);
    main.append(selected);
    const palette = el("section", "builder-card tile-palette");
    palette.append(el("h2", "", "牌を選ぶ"));
    const modes = el("div", "mode-tabs");
    for (const [mode, label] of [
      ["hand", "手牌に追加"],
      ["meld", "面子を追加"],
    ]) {
      const b = button(
        label,
        `secondary${state.mode === mode ? " active" : ""}`,
        () => {
          state.mode = mode;
          refresh();
        },
      );
      b.setAttribute("aria-pressed", String(state.mode === mode));
      b.disabled = pending;
      modes.append(b);
    }
    palette.append(modes);
    if (state.mode === "meld") {
      palette.append(
        selectControl(
          "面子の種類",
          "meld-kind",
          Object.entries(meldNames),
          state.kind,
          (value) => {
            state.kind = value;
            state.draft = [];
          },
        ),
      );
      palette.append(
        el(
          "p",
          "muted",
          "チー・ポンは3枚、明槓・暗槓は4枚を選び「面子を追加」を押してください。暗槓は門前を保ちます。",
        ),
      );
      if (equivalentCount(state) > 11)
        palette.append(
          el(
            "p",
            "notice",
            "面子を追加するには、先に手牌から3枚分を取り消してください。",
          ),
        );
      const draft = el("div", "meld-draft");
      const chosen = el("div", "hand");
      state.draft.forEach((tile, i) => {
        const b = button("", "selected-tile", () => {
          state.draft.splice(i, 1);
          changed();
          refresh();
        });
        b.append(renderTile(tile));
        b.setAttribute(
          "aria-label",
          `${tileLabel(tile)}を面子候補から取り消す`,
        );
        b.disabled = pending;
        chosen.append(b);
      });
      draft.append(chosen);
      const add = button("面子を追加", "primary", () => {
        if (commitMeld(state)) {
          if (!isClosed(state)) {
            state.options.riichi = "none";
            state.options.ippatsu = false;
          }
          changed();
          refresh();
        }
      });
      add.disabled =
        pending || !validDraft(state) || equivalentCount(state) > 11;
      draft.append(
        add,
        button("候補をクリア", "text-button", () => {
          state.draft = [];
          refresh();
        }),
      );
      palette.append(draft);
    } else if (state.draft.length) {
      palette.append(
        el(
          "p",
          "notice",
          "入力中の面子があります。「面子を追加」に戻って確定するか、候補をクリアしてください。",
        ),
      );
    }
    const counts = countTiles(state);
    for (const [suit, label] of Object.entries(suitNames)) {
      const group = el("div", "palette-group");
      group.append(el("h3", "", label));
      const row = el("div", `palette-row ${suit === "honor" ? "honors" : ""}`);
      for (const tile of allTiles.filter((t) => t.suit === suit)) {
        const key = tileKey(tile),
          count = counts.get(key) || 0;
        const b = button("", "palette-tile", () => {
          if (addTile(state, tile)) {
            changed();
            refresh();
          }
        });
        b.dataset.focus = key;
        b.append(renderTile(tile), el("span", "copy-count", `${count} / 4`));
        b.setAttribute(
          "aria-label",
          `${tileLabel(tile)}を追加（${count}枚選択済み）`,
        );
        b.disabled =
          pending ||
          count >= 4 ||
          (state.mode === "hand"
            ? equivalentCount(state) >= 14
            : state.melds.length >= 4 ||
              equivalentCount(state) > 11 ||
              state.draft.length >=
                (["kan", "ankan"].includes(state.kind) ? 4 : 3));
        row.append(b);
      }
      group.append(row);
      palette.append(group);
    }
    main.append(palette);
    const context = el("section", "builder-card");
    context.append(
      el("h2", "", "和了の条件"),
      el(
        "p",
        "muted",
        "同じ牌姿でも、和了牌やロン／ツモによって役が変わります。",
      ),
    );
    const form = el("fieldset", "analysis-form");
    form.disabled = pending;
    const unique = [
      ...new Map(state.hand.map((t) => [tileKey(t), t])).values(),
    ];
    form.append(
      selectControl(
        "和了牌",
        "winning-tile",
        [
          ["", "最後の1枚を選択"],
          ...unique.map((t) => [tileKey(t), tileLabel(t)]),
        ],
        state.winningKey || "",
        (value) => {
          state.winningKey = value || null;
        },
      ),
    );
    form.append(
      selectControl(
        "和了方法",
        "win-method",
        [
          ["ron", "ロン"],
          ["tsumo", "ツモ"],
        ],
        state.options.win_method,
        (value) => {
          state.options.win_method = value;
          state.options.special = "none";
        },
      ),
    );
    form.append(
      selectControl(
        "場風",
        "round-wind",
        winds,
        state.options.round_wind,
        (value) => (state.options.round_wind = value),
      ),
      selectControl(
        "自風",
        "seat-wind",
        winds,
        state.options.seat_wind,
        (value) => {
          state.options.seat_wind = value;
          if (["tenhou", "chiihou"].includes(state.options.special))
            state.options.special = "none";
        },
      ),
    );
    const closed = isClosed(state);
    const declaration = selectControl(
      "立直",
      "riichi",
      [
        ["none", "立直なし"],
        ["riichi", "立直"],
        ["double_riichi", "ダブル立直"],
      ],
      state.options.riichi,
      (value) => {
        state.options.riichi = value;
        if (value === "none") state.options.ippatsu = false;
      },
    );
    declaration.querySelector("select").disabled = !closed || pending;
    form.append(declaration);
    const checkbox = el("label", "analysis-checkbox");
    const input = el("input");
    input.type = "checkbox";
    input.checked = state.options.ippatsu;
    input.disabled = !closed || state.options.riichi === "none" || pending;
    input.dataset.focus = "ippatsu";
    input.addEventListener("change", () => {
      state.options.ippatsu = input.checked;
      changed();
      refresh();
    });
    checkbox.append(input, el("span", "", "一発（立直後一巡以内・鳴きなし）"));
    form.append(checkbox);
    const special = [["none", "通常の和了"]];
    if (state.options.win_method === "tsumo") {
      special.push(["haitei", "海底牌でのツモ"]);
      if (state.melds.some((m) => ["kan", "ankan"].includes(m.kind)))
        special.push(["rinshan", "嶺上牌でのツモ"]);
      if (!state.melds.length && state.options.riichi === "none")
        special.push(
          state.options.seat_wind === "east"
            ? ["tenhou", "親の最初の配牌で和了（天和）"]
            : ["chiihou", "子の鳴きなし最初のツモ（地和）"],
        );
    } else
      special.push(
        ["houtei", "最後の打牌でのロン"],
        ["chankan", "加槓牌へのロン（槍槓）"],
      );
    if (!special.some(([id]) => id === state.options.special))
      state.options.special = "none";
    form.append(
      selectControl(
        "特別な和了状況",
        "special",
        special,
        state.options.special,
        (value) => {
          state.options.special = value;
          if (value === "rinshan") state.options.ippatsu = false;
        },
      ),
    );
    context.append(
      form,
      el(
        "p",
        "context-status",
        closed
          ? "門前の手です（暗槓を含む場合も門前）。"
          : "副露した手です。門前限定役は成立しません。",
      ),
    );
    main.append(context);
    const examples = el("details", "analysis-examples");
    examples.append(el("summary", "", "入力例を使う"));
    const exampleButtons = el("div", "builder-actions");
    for (const [id, label, winning] of [
      ["tanyao", "断么九＋平和", "sou-8"],
      ["chiitoitsu", "七対子", "honor-1"],
      ["kokushi_musou", "国士無双", "honor-1"],
    ])
      exampleButtons.append(
        button(label, "secondary", () => {
          state = fresh();
          state.hand = structuredClone(catalogExample(id));
          state.winningKey = winning;
          refresh();
        }),
      );
    examples.append(exampleButtons);
    main.append(examples);
    const submit = button(
      pending ? "判定しています…" : "成立する役を調べる",
      "primary full",
      async () => {
        const payload = makeRequest(state);
        if (!payload || pending) return;
        pending = true;
        state.error = null;
        refresh();
        try {
          state.result = await api("/api/hand/analyze", payload);
        } catch (error) {
          state.error = error.message;
        } finally {
          pending = false;
          refresh();
          if (location.hash === "#analyze")
            main
              .querySelector(".analysis-result,.notice")
              ?.scrollIntoView({ behavior: "smooth", block: "start" });
        }
      },
    );
    submit.disabled = pending || !makeRequest(state);
    main.append(submit);
    if (!makeRequest(state))
      main.append(
        el(
          "p",
          "muted centered",
          equivalentCount(state) !== 14
            ? "手牌と面子を合わせて14枚相当にしてください。"
            : state.draft.length
              ? "入力中の面子を確定またはクリアしてください。"
              : "和了牌を選んでください。",
        ),
      );
    if (state.error) {
      const warning = el("p", "notice", state.error);
      warning.setAttribute("role", "alert");
      main.append(warning);
    }
    if (state.result) drawResult(state.result);
    const scope = el(
      "p",
      "muted analysis-scope",
      "入力した和了条件に基づく学習用の役判定です。点数計算・フリテン・立直可否・対局履歴の確認は行いません。赤ドラ・ドラ・ローカル役は対象外です。",
    );
    main.append(
      scope,
      glossaryLinks("門前 副露 和了牌 順子 刻子 槓子 雀頭 翻"),
    );
    if (pending)
      main.querySelectorAll("button,input,select").forEach((control) => {
        control.disabled = true;
      });
  }
  function catalogExample(id) {
    return documentCatalog.find((y) => y.id === id).example;
  }
  const documentCatalog = catalog;
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
    main.append(section);
  }
  draw();
}
