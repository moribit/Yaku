import { test } from "node:test";
import assert from "node:assert/strict";
import {
  boundedRequest,
  MAX_BODY_BYTES,
} from "../deploy/worker/request_limit.mjs";
test("stream is bounded without trusting content-length", async () => {
  const request = new Request("https://example.test/api/quiz", {
    method: "POST",
    body: new Uint8Array(MAX_BODY_BYTES + 1),
  });
  assert.equal(await boundedRequest(request), null);
});
test("small JSON is preserved and exaggerated content-length rejected", async () => {
  const payload = JSON.stringify({ difficulty: "beginner", count: 10 });
  const small = await boundedRequest(
    new Request("https://example.test/api/quiz", {
      method: "POST",
      body: payload,
      headers: { "content-type": "application/json" },
    }),
  );
  assert.equal(await small.text(), payload);
  assert.equal(small.headers.get("content-type"), "application/json");
  const bad = new Request("https://example.test/api/quiz", {
    method: "POST",
    body: "{}",
    headers: { "content-length": String(MAX_BODY_BYTES + 1) },
  });
  assert.equal(await boundedRequest(bad), null);
  const get = new Request("https://example.test/");
  assert.equal(await boundedRequest(get), get);
});
