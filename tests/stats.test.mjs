import { test } from "node:test";
import assert from "node:assert/strict";
import {
  emptyStats,
  parseStats,
  loadStats,
  recordAnswer,
  weakYaku,
  STORAGE_KEY,
} from "../web/stats.js";
const question = {
  id: "b-10",
  choices: [
    { id: "pinfu" },
    { id: "tanyao" },
    { id: "riichi" },
    { id: "menzen_tsumo" },
  ],
};
const result = {
  correct: false,
  correct_yaku: ["pinfu", "tanyao"],
  selected_yaku: ["tanyao", "riichi"],
  missed_yaku: ["pinfu"],
  extra_yaku: ["riichi"],
};
test("recognition stats track omissions and extras, survive reload, and prioritize error rate", () => {
  const values = new Map();
  const storage = {
    setItem: (k, v) => values.set(k, v),
    getItem: (k) => values.get(k),
  };
  const { stats, saved } = recordAnswer(
    emptyStats(),
    question,
    result,
    storage,
    "2026-10-14T00:00:00Z",
  );
  assert.equal(saved, true);
  assert.equal(stats.totalAnswered, 1);
  assert.equal(stats.totalCorrect, 0);
  assert.equal(stats.yakuStats.pinfu.wrong, 1);
  assert.equal(stats.yakuStats.riichi.wrong, 1);
  assert.equal(stats.yakuStats.tanyao.correct, 1);
  assert.equal(stats.yakuStats.menzen_tsumo.correct, 1);
  assert.deepEqual(loadStats(storage), stats);
  assert.deepEqual(
    weakYaku(stats).map((x) => x.yakuId),
    ["pinfu", "riichi"],
  );
  const correctResult = {
    correct: true,
    correct_yaku: ["pinfu", "tanyao"],
    selected_yaku: ["pinfu", "tanyao"],
    missed_yaku: [],
    extra_yaku: [],
  };
  const next = recordAnswer(stats, question, correctResult, storage).stats;
  assert.equal(next.totalCorrect, 1);
  assert.equal(next.totalAnswered, 2);
  assert.equal(next.recentMistakes.length, 1);
  assert.equal(stats.totalAnswered, 1);
  assert.ok(values.has(STORAGE_KEY));
});
test("corruption, unsupported versions and impossible counters reset safely", () => {
  for (const raw of [
    "{",
    "null",
    "[]",
    JSON.stringify({ ...emptyStats(), version: 2 }),
    JSON.stringify({ ...emptyStats(), totalCorrect: 1 }),
    JSON.stringify({ ...emptyStats(), totalAnswered: -1 }),
    JSON.stringify({
      ...emptyStats(),
      yakuStats: { pinfu: { yakuId: "pinfu", shown: 1, correct: 0, wrong: 1 } },
    }),
  ])
    assert.deepEqual(parseStats(raw), emptyStats());
  assert.deepEqual(
    loadStats({
      getItem() {
        throw new Error("blocked");
      },
    }),
    emptyStats(),
  );
});
test("quota failures retain progress and recent mistakes are bounded", () => {
  let stats = emptyStats();
  for (let i = 0; i < 105; i++)
    stats = recordAnswer(stats, question, result, null).stats;
  assert.equal(stats.recentMistakes.length, 100);
  const out = recordAnswer(stats, question, result, {
    setItem() {
      throw new Error("quota");
    },
  });
  assert.equal(out.saved, false);
  assert.equal(out.stats.totalAnswered, 106);
});
