// Pure input helpers, shared by the UI and unit tests. The backend is authoritative.
export const allTiles = ["man", "pin", "sou", "honor"].flatMap((suit) =>
  Array.from({ length: suit === "honor" ? 7 : 9 }, (_, i) => ({
    suit,
    value: i + 1,
  })),
);
export const tileKey = (tile) => `${tile.suit}-${tile.value}`;
export function countTiles(state, includeDraft = true) {
  const counts = new Map();
  for (const tile of [
    ...state.hand,
    ...state.melds.flatMap((m) => m.tiles),
    ...(includeDraft ? state.draft : []),
  ])
    counts.set(tileKey(tile), (counts.get(tileKey(tile)) || 0) + 1);
  return counts;
}
export function equivalentCount(state) {
  return state.hand.length + state.melds.length * 3;
}
export function addTile(state, tile) {
  if ((countTiles(state).get(tileKey(tile)) || 0) >= 4) return false;
  if (state.mode === "hand") {
    if (equivalentCount(state) >= 14) return false;
    state.hand.push({ ...tile });
  } else {
    const capacity = ["kan", "ankan"].includes(state.kind) ? 4 : 3;
    if (
      state.melds.length >= 4 ||
      state.draft.length >= capacity ||
      equivalentCount(state) > 11
    )
      return false;
    state.draft.push({ ...tile });
  }
  return true;
}
export function removeTile(state, index) {
  if (!Number.isInteger(index) || index < 0 || index >= state.hand.length)
    return;
  state.hand.splice(index, 1);
  if (!state.hand.some((t) => tileKey(t) === state.winningKey))
    state.winningKey = null;
}
export function validDraft(state) {
  const required = ["kan", "ankan"].includes(state.kind) ? 4 : 3;
  if (state.draft.length !== required) return false;
  const tiles = [...state.draft].sort((a, b) => a.value - b.value);
  const first = tiles[0];
  return tiles.every(
    (tile, i) =>
      tile.suit === first.suit &&
      (state.kind === "chi"
        ? first.suit !== "honor" && tile.value === first.value + i
        : tile.value === first.value),
  );
}
export function commitMeld(state) {
  if (
    !validDraft(state) ||
    state.melds.length >= 4 ||
    equivalentCount(state) > 11
  )
    return false;
  state.melds.push({
    kind: state.kind,
    tiles: [...state.draft].sort((a, b) => a.value - b.value),
  });
  state.draft = [];
  return true;
}
export function isClosed(state) {
  return state.melds.every((m) => m.kind === "ankan");
}
export function makeRequest(state) {
  const winning = state.hand.find((t) => tileKey(t) === state.winningKey);
  if (equivalentCount(state) !== 14 || !winning || state.draft.length)
    return null;
  return {
    hand: state.hand,
    melds: state.melds,
    winning_tile: winning,
    ...state.options,
  };
}
