// Versioned, portable learning record. No DOM dependency; future D1 sync can use this DTO.
export const STORAGE_KEY = "yaku-note.learning.v1";
export const emptyStats = () => ({
  version: 1,
  totalAnswered: 0,
  totalCorrect: 0,
  yakuStats: {},
  recentMistakes: [],
});
const validCount = (n) => Number.isSafeInteger(n) && n >= 0;
const validId = (id) =>
  typeof id === "string" && /^[a-z][a-z0-9_]{0,63}$/.test(id);
function defaultStorage() {
  try {
    return globalThis.localStorage;
  } catch {
    return null;
  }
}
export function parseStats(raw) {
  if (!raw) return emptyStats();
  try {
    const data = JSON.parse(raw);
    if (
      data.version !== 1 ||
      !validCount(data.totalAnswered) ||
      !validCount(data.totalCorrect) ||
      data.totalCorrect > data.totalAnswered ||
      !data.yakuStats ||
      typeof data.yakuStats !== "object" ||
      Array.isArray(data.yakuStats) ||
      !Array.isArray(data.recentMistakes)
    )
      return emptyStats();
    const stats = emptyStats();
    stats.totalAnswered = data.totalAnswered;
    stats.totalCorrect = data.totalCorrect;
    for (const [id, s] of Object.entries(data.yakuStats)) {
      if (
        !validId(id) ||
        !s ||
        s.yakuId !== id ||
        !validCount(s.shown) ||
        !validCount(s.correct) ||
        !validCount(s.wrong) ||
        s.correct + s.wrong !== s.shown ||
        s.shown > data.totalAnswered
      )
        return emptyStats();
      Object.defineProperty(stats.yakuStats, id, {
        value: {
          yakuId: id,
          shown: s.shown,
          correct: s.correct,
          wrong: s.wrong,
        },
        enumerable: true,
        writable: true,
        configurable: true,
      });
    }
    stats.recentMistakes = data.recentMistakes
      .filter(
        (m) =>
          m &&
          typeof m.questionId === "string" &&
          m.questionId.length <= 32 &&
          typeof m.at === "string" &&
          Array.isArray(m.missed) &&
          Array.isArray(m.extra) &&
          m.missed.every(validId) &&
          m.extra.every(validId),
      )
      .slice(-100)
      .map((m) => ({
        questionId: m.questionId,
        at: m.at,
        missed: [...m.missed],
        extra: [...m.extra],
      }));
    return stats;
  } catch {
    return emptyStats();
  }
}
export function loadStats(storage = defaultStorage()) {
  try {
    return parseStats(storage?.getItem(STORAGE_KEY));
  } catch {
    return emptyStats();
  }
}
export function recordAnswer(
  previous,
  question,
  result,
  storage = defaultStorage(),
  now = new Date().toISOString(),
) {
  const stats = structuredClone(previous);
  stats.totalAnswered++;
  if (result.correct) stats.totalCorrect++;
  const correct = new Set(result.correct_yaku),
    selected = new Set(result.selected_yaku);
  // Each candidate is one recognition opportunity, including correct rejection of a distractor.
  for (const { id } of question.choices) {
    if (!validId(id)) continue;
    const existing = Object.hasOwn(stats.yakuStats, id)
      ? stats.yakuStats[id]
      : null;
    const s = existing || { yakuId: id, shown: 0, correct: 0, wrong: 0 };
    s.shown++;
    if (correct.has(id) === selected.has(id)) s.correct++;
    else s.wrong++;
    Object.defineProperty(stats.yakuStats, id, {
      value: s,
      enumerable: true,
      writable: true,
      configurable: true,
    });
  }
  if (!result.correct)
    stats.recentMistakes.push({
      questionId: question.id,
      at: now,
      missed: [...result.missed_yaku],
      extra: [...result.extra_yaku],
    });
  stats.recentMistakes = stats.recentMistakes.slice(-100);
  let saved = false;
  try {
    if (storage) {
      storage.setItem(STORAGE_KEY, JSON.stringify(stats));
      saved = true;
    }
  } catch {}
  return { stats, saved };
}
export function weakYaku(stats) {
  return Object.values(stats.yakuStats)
    .filter((s) => s.shown > 0 && s.wrong > 0)
    .sort(
      (a, b) =>
        b.wrong / b.shown - a.wrong / a.shown ||
        b.wrong - a.wrong ||
        b.shown - a.shown ||
        a.yakuId.localeCompare(b.yakuId),
    );
}
