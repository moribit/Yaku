import { test } from "node:test";
import assert from "node:assert/strict";
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
  HISTORY_LIMIT,
} from "../web/hand-input.js";
const fresh = () => ({
  hand: [],
  melds: [],
  draft: [],
  mode: "hand",
  kind: "chi",
  winningKey: null,
  options: {
    win_method: "ron",
    seat_wind: "south",
    round_wind: "east",
    riichi: "none",
    ippatsu: false,
    special: "none",
  },
});
const t = (suit, value) => ({ suit, value });
test("34 types, fifth physical copy prevention, and explicit winning tile", () => {
  assert.equal(allTiles.length, 34);
  assert.equal(new Set(allTiles.map(tileKey)).size, 34);
  const state = fresh();
  for (let i = 0; i < 4; i++) assert.equal(addTile(state, t("man", 1)), true);
  assert.equal(addTile(state, t("man", 1)), false);
  assert.equal(state.winningKey, null);
  state.winningKey = "man-1";
  removeTile(state, 0);
  assert.equal(state.winningKey, "man-1");
  for (let i = 0; i < 3; i++) removeTile(state, 0);
  assert.equal(state.winningKey, null);
});
test("melds require legal combinations and ankan preserves closed state", () => {
  const state = fresh();
  state.mode = "meld";
  state.kind = "ankan";
  for (let i = 0; i < 4; i++) assert.equal(addTile(state, t("honor", 5)), true);
  assert.equal(validDraft(state), true);
  assert.equal(commitMeld(state), true);
  assert.equal(equivalentCount(state), 3);
  assert.equal(isClosed(state), true);
  state.mode = "hand";
  assert.equal(addTile(state, t("honor", 5)), false);
  state.mode = "meld";
  state.kind = "chi";
  for (const value of [4, 2, 3]) addTile(state, t("man", value));
  assert.equal(commitMeld(state), true);
  assert.equal(isClosed(state), false);
  state.kind = "pon";
  for (const value of [2, 3, 4]) addTile(state, t("pin", value));
  assert.equal(validDraft(state), false);
  assert.equal(commitMeld(state), false);
});
test("14 equivalents, full meld slots and pending drafts gate requests", () => {
  const state = fresh();
  for (const tile of allTiles.slice(0, 14))
    assert.equal(addTile(state, tile), true);
  assert.equal(addTile(state, allTiles[20]), false);
  assert.equal(makeRequest(state), null);
  state.winningKey = tileKey(state.hand[13]);
  const request = makeRequest(state);
  assert.equal(request.hand.length, 14);
  assert.deepEqual(request.winning_tile, state.hand[13]);
  state.draft = [t("sou", 1)];
  assert.equal(makeRequest(state), null);
  const meld = fresh();
  meld.mode = "meld";
  meld.kind = "pon";
  for (const tile of allTiles.slice(0, 4)) {
    for (let i = 0; i < 3; i++) addTile(meld, tile);
    assert.equal(commitMeld(meld), true);
  }
  assert.equal(addTile(meld, t("sou", 1)), false);
  meld.mode = "hand";
  addTile(meld, t("sou", 1));
  addTile(meld, t("sou", 1));
  meld.winningKey = "sou-1";
  assert.equal(makeRequest(meld).hand.length, 2);
});

test("Undo restores additions, removals, winning tile, options and clear without aliasing", () => {
  const state = fresh(),
    history = [];
  for (const tile of [t("sou", 8), t("man", 2), t("sou", 8)])
    editInput(state, history, (s) => addTile(s, tile));
  assert.deepEqual(
    sortedHand(state).map(({ tile }) => tileKey(tile)),
    ["man-2", "sou-8", "sou-8"],
  );
  assert.equal(tileKey(state.hand[0]), "sou-8"); // presentation never reorders DTO
  editInput(state, history, (s) => setWinningTile(s, "sou-8"));
  const before = structuredClone(state);
  editInput(state, history, (s) => removeTile(s, 0));
  assert.equal(state.winningKey, "sou-8");
  editInput(state, history, (s) => removeTile(s, 1));
  assert.equal(state.winningKey, null);
  undoInput(state, history);
  undoInput(state, history);
  assert.deepEqual(state, before);
  editInput(state, history, (s) => Object.assign(s, fresh()));
  assert.equal(state.hand.length, 0);
  undoInput(state, history);
  assert.deepEqual(state, before);
  undoInput(state, history);
  assert.equal(state.winningKey, null);
  assert.equal(setWinningTile(state, "honor-7"), false);
});
test("history bounds, failed edits and availability checks do not mutate input", () => {
  const state = fresh(),
    history = [];
  for (let i = 0; i < 4; i++)
    editInput(state, history, (s) => addTile(s, t("man", 2)));
  assert.equal(
    editInput(state, history, (s) => addTile(s, t("man", 2))),
    false,
  );
  assert.equal(history.length, 4);
  const before = structuredClone(state);
  assert.equal(canAddTile(state, t("pin", 2)), true);
  assert.equal(canAddTile(state, t("man", 2)), false);
  assert.deepEqual(state, before);
  for (let i = 0; i < 80; i++)
    editInput(state, history, (s) => {
      s.options.win_method = i % 2 ? "tsumo" : "ron";
    });
  assert.equal(history.length, HISTORY_LIMIT);
  for (let i = 0; i < HISTORY_LIMIT; i++)
    assert.equal(undoInput(state, history), true);
  assert.equal(undoInput(state, history), false);
});
test("meld commits and removals can be undone, including drafts and closed status", () => {
  for (const kind of ["chi", "pon", "kan", "ankan"]) {
    const state = fresh(),
      history = [];
    state.mode = "meld";
    state.kind = kind;
    for (const value of kind === "chi"
      ? [2, 3, 4]
      : Array(kind === "pon" ? 3 : 4).fill(2))
      editInput(state, history, (s) => addTile(s, t("man", value)));
    const draft = structuredClone(state);
    editInput(state, history, commitMeld);
    assert.equal(equivalentCount(state), 3);
    assert.equal(isClosed(state), kind === "ankan");
    editInput(state, history, (s) => removeMeld(s, 0));
    assert.equal(equivalentCount(state), 0);
    undoInput(state, history);
    assert.equal(state.melds.length, 1);
    undoInput(state, history);
    assert.deepEqual(state, draft);
  }
});
