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
