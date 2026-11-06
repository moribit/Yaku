import assert from "node:assert/strict";
const base = process.argv[2] || "http://localhost:8787";
async function post(path, body) {
  return fetch(`${base}${path}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}
assert.equal((await fetch(`${base}/`)).status, 200);
const catalog = await fetch(`${base}/api/yaku`);
assert.equal(catalog.status, 200);
assert.equal((await catalog.json()).yaku.length, 38);
assert.equal((await fetch(`${base}/api/yaku/pinfu`)).status, 200);
assert.equal((await fetch(`${base}/api/yaku/nope`)).status, 404);
for (const difficulty of ["beginner", "intermediate", "advanced"]) {
  const response = await post("/api/quiz", { difficulty, count: 10 });
  assert.equal(response.status, 200);
  const text = await response.text();
  for (const field of [
    "correct_yaku",
    "primary_yaku",
    "explanation",
    "decomposition",
  ])
    assert.equal(text.includes(field), false);
  const { questions } = JSON.parse(text);
  assert.equal(questions.length, 10);
  assert.equal(new Set(questions.map((q) => q.id)).size, 10);
  for (const q of questions) {
    assert.ok(q.choices.length >= 4 && q.choices.length <= 6);
    assert.deepEqual(Object.keys(q.choices[0]).sort(), [
      "id",
      "name_ja",
      "reading",
    ]);
  }
  const first = questions[0];
  const wrong = await post("/api/quiz/check", {
    question_id: first.id,
    answers: [],
  });
  assert.equal(wrong.status, 200);
  const checked = await wrong.json();
  assert.equal(checked.correct, false);
  assert.ok(checked.correct_yaku.length > 0);
  const right = await post("/api/quiz/check", {
    question_id: first.id,
    answers: [...checked.correct_yaku].reverse(),
  });
  assert.equal(right.status, 200);
  assert.equal((await right.json()).correct, true);
}
assert.equal(
  (await post("/api/quiz", { difficulty: "invalid", count: 10 })).status,
  400,
);
assert.equal(
  (await post("/api/quiz", { difficulty: "beginner", count: 11 })).status,
  422,
);
assert.equal(
  (await post("/api/quiz/check", { question_id: "unknown", answers: [] }))
    .status,
  404,
);
assert.equal(
  (await post("/api/quiz/check", { question_id: "b-10", answers: ["unknown"] }))
    .status,
  400,
);
assert.equal(
  (await post("/api/quiz", { difficulty: "beginner", extra: "x".repeat(5000) }))
    .status,
  413,
);
const openapi = await fetch(`${base}/openapi.json`);
assert.equal(openapi.status, 200);
assert.ok((await openapi.json()).paths["/api/quiz"]);
const client = await fetch(`${base}/client.ts`);
assert.equal(client.status, 200);
assert.ok((await client.text()).includes("postApiQuiz"));
console.log(
  `HTTP smoke passed: ${base} — all 3 difficulties, privacy, grading, validation, body limit, OpenAPI/client`,
);

const glossary = await fetch(`${base}/api/glossary`);
assert.equal(glossary.status, 200);
const { terms } = await glossary.json();
assert.equal(terms.length, 49);
assert.equal(new Set(terms.map((t) => t.id)).size, 49);
for (const term of terms)
  for (const related of term.related)
    assert.ok(terms.some((t) => t.id === related));
assert.equal((await fetch(`${base}/api/glossary/ryanmen`)).status, 200);
assert.equal((await fetch(`${base}/api/glossary/nope`)).status, 404);
const parseTile = (text) =>
  text.length === 2
    ? {
        suit: { m: "man", p: "pin", s: "sou" }[text[1]],
        value: Number(text[0]),
      }
    : {
        suit: "honor",
        value:
          ["east", "south", "west", "north", "white", "green", "red"].indexOf(
            text,
          ) + 1,
      };
const input = {
  hand: "2m 3m 4m 4m 5m 6m 3p 4p 5p 6s 7s 8s 2p 2p".split(" ").map(parseTile),
  winning_tile: parseTile("8s"),
};
const analyzed = await post("/api/hand/analyze", input);
assert.equal(analyzed.status, 200);
const analysis = await analyzed.json();
assert.equal(analysis.status, "winning");
assert.deepEqual(analysis.patterns[0].yaku.map((y) => y.id).sort(), [
  "pinfu",
  "tanyao",
]);
const badHand = await post("/api/hand/analyze", {
  ...input,
  hand: input.hand.slice(0, 13),
});
assert.equal(badHand.status, 400);
assert.equal((await badHand.json()).error_kind, "invalid_tile_count");
const ambiguous = await post("/api/hand/analyze", {
  hand: "1m 1m 2m 2m 3m 3m 7p 7p 8p 8p 9p 9p 5s 5s".split(" ").map(parseTile),
  winning_tile: parseTile("9p"),
});
assert.equal(ambiguous.status, 200);
const interpretations = (await ambiguous.json()).patterns;
assert.ok(
  interpretations.some((p) => p.yaku.some((y) => y.id === "chiitoitsu")),
);
assert.ok(
  interpretations.some((p) => p.yaku.some((y) => y.id === "ryanpeikou")),
);
console.log(`Hand explorer and 49-term glossary smoke passed: ${base}`);
