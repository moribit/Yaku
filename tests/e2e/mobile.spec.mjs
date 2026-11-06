import { test, expect } from "@playwright/test";
const palette = (page, key) => page.locator(`[data-tile="${key}"]`);
const counter = (page) => page.locator(".tile-counter");
async function analyze(page) {
  await page.goto("/#analyze");
  await expect(palette(page, "man-1")).toBeVisible();
}
async function noOverflow(page) {
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    ),
  ).toBe(true);
}

test("continuous input retains DOM, focus and scroll; remove, win, Undo and clear", async ({
  page,
}) => {
  await analyze(page);
  const errors = [];
  page.on("pageerror", (e) => errors.push(e.message));
  let calls = 0;
  page.on("request", (r) => {
    if (r.url().includes("/api/hand/analyze")) calls++;
  });
  const tile = palette(page, "man-2");
  await tile.evaluate((n) => {
    const summary = document.querySelector(".input-summary");
    window.scrollBy(
      0,
      n.getBoundingClientRect().top -
        summary.getBoundingClientRect().height -
        32,
    );
    n.focus({ preventScroll: true });
  });
  await page.evaluate(() => {
    window.paletteNode = document.querySelector('[data-tile="man-2"]');
    window.conditionNode = document.querySelector('[data-focus="win-method"]');
  });
  const y = await page.evaluate(() => scrollY);
  for (let i = 0; i < 3; i++) {
    if (await page.evaluate(() => navigator.maxTouchPoints > 0))
      await tile.tap();
    else await tile.click();
  }
  await expect(counter(page)).toHaveText("3 / 14枚相当");
  expect(await page.evaluate(() => scrollY)).toBe(y);
  expect(
    await page.evaluate(
      () =>
        window.paletteNode === document.querySelector('[data-tile="man-2"]') &&
        window.conditionNode ===
          document.querySelector('[data-focus="win-method"]'),
    ),
  ).toBe(true);
  // Same element receives keyboard input after the update, without focus restoration.
  await tile.focus();
  await page.keyboard.press("Enter");
  await expect(counter(page)).toHaveText("4 / 14枚相当");
  await expect(tile).toBeDisabled();
  await page.getByRole("button", { name: "和了牌を選択", exact: true }).click();
  await page.locator(".selected-hand button").first().click();
  await expect(page.locator(".selected-hand .winning")).toHaveCount(1);
  await expect(page.locator('[data-focus="winning-tile"]')).toHaveValue(
    "man-2",
  );
  await page.locator(".selected-hand button").first().click();
  await expect(counter(page)).toHaveText("3 / 14枚相当");
  await page.getByRole("button", { name: "元に戻す", exact: true }).click();
  await expect(counter(page)).toHaveText("4 / 14枚相当");
  await page.getByRole("button", { name: "全クリア", exact: true }).click();
  await expect(counter(page)).toHaveText("0 / 14枚相当");
  await page.getByRole("button", { name: "元に戻す", exact: true }).click();
  await expect(counter(page)).toHaveText("4 / 14枚相当");
  await expect(page.locator(".selected-hand .winning")).toHaveCount(1);
  expect(calls).toBe(0);
  expect(errors).toEqual([]);
});

test("fourteen cap, last winning-copy removal, explicit submit and API result", async ({
  page,
}) => {
  await analyze(page);
  await page.locator(".analysis-examples summary").click();
  await page.getByRole("button", { name: "断么九＋平和", exact: true }).click();
  await expect(counter(page)).toHaveText("14 / 14枚相当");
  await expect(palette(page, "man-1")).toBeDisabled();
  await page
    .getByRole("button", { name: "8索（和了牌）を削除", exact: true })
    .click();
  await expect(page.locator('[data-focus="winning-tile"]')).toHaveValue("");
  await expect(
    page.getByRole("button", { name: "成立する役を調べる", exact: true }),
  ).toBeDisabled();
  await page.getByRole("button", { name: "元に戻す", exact: true }).click();
  const response = page.waitForResponse("**/api/hand/analyze");
  await page
    .getByRole("button", { name: "成立する役を調べる", exact: true })
    .click();
  const data = await (await response).json();
  expect(data.status).toBe("winning");
  expect(data.patterns[0].yaku.map((y) => y.id).sort()).toEqual([
    "pinfu",
    "tanyao",
  ]);
  await expect(
    page.getByRole("heading", {
      name: "成立する役が見つかりました",
      exact: true,
    }),
  ).toBeVisible();
  await noOverflow(page);
});

test("meld drafts, kan equivalents, closed status and Undo", async ({
  page,
}) => {
  await analyze(page);
  await page.locator(".meld-editor summary").click();
  await page.getByLabel("組の種類", { exact: true }).selectOption("ankan");
  await page
    .getByRole("button", { name: "副露の牌を選ぶ", exact: true })
    .click();
  for (let i = 0; i < 4; i++) await palette(page, "honor-5").click();
  await expect(palette(page, "honor-5")).toBeDisabled();
  await page.getByRole("button", { name: "この組を追加", exact: true }).click();
  await expect(counter(page)).toHaveText("3 / 14枚相当");
  await expect(page.locator(".context-status")).toContainText("暗カンも門前");
  await expect(page.getByLabel("立直", { exact: true })).toBeEnabled();
  await page.getByRole("button", { name: "暗槓を削除", exact: true }).click();
  await expect(counter(page)).toHaveText("0 / 14枚相当");
  await page.getByRole("button", { name: "元に戻す", exact: true }).click();
  await expect(counter(page)).toHaveText("3 / 14枚相当");
  await page.getByLabel("組の種類", { exact: true }).selectOption("pon");
  await page
    .getByRole("button", { name: "副露の牌を選ぶ", exact: true })
    .click();
  for (let i = 0; i < 3; i++) await palette(page, "pin-2").click();
  await page.getByRole("button", { name: "この組を追加", exact: true }).click();
  await expect(counter(page)).toHaveText("6 / 14枚相当");
  await expect(page.getByLabel("立直", { exact: true })).toBeDisabled();
});

test("all widths and primary routes fit; pinned controls fit and rotation works", async ({
  page,
}, testInfo) => {
  for (const width of [320, 375, 390, 430, 768, 1280]) {
    await page.setViewportSize({ width, height: 844 });
    for (const hash of [
      "analyze",
      "home",
      "catalog",
      "quiz",
      "glossary",
      "weak",
    ]) {
      await page.goto(`/#${hash}`);
      await expect(page.locator(".loading")).toHaveCount(0);
      if (hash === "analyze") {
        await expect(palette(page, "man-1")).toBeVisible();
        const clear = page.getByRole("button", {
          name: "全クリア",
          exact: true,
        });
        if (await clear.isEnabled()) await clear.click();
        for (const key of ["man-1", "man-2", "man-3", "man-4"])
          await palette(page, key).click();
        const targets = await page
          .locator(".palette-tile,.selected-tile")
          .evaluateAll((nodes) =>
            nodes.map((n) => ({
              w: n.getBoundingClientRect().width,
              h: n.getBoundingClientRect().height,
            })),
          );
        expect(targets.every((r) => r.w >= 44 && r.h >= 44)).toBe(true);
        await page.locator(".analysis-examples summary").click();
        await page
          .getByRole("button", { name: "断么九＋平和", exact: true })
          .click();
        await noOverflow(page);
        if (width === 390 && testInfo.project.name === "mobile-chromium") {
          await page.evaluate(() => scrollTo(0, 0));
          await page.screenshot({
            path: "docs/screenshots/mobile-after-390.png",
          });
        }
      } else
        await expect(page.locator("main")).not.toContainText(
          "ノートを開いています",
        );
      await noOverflow(page);
    }
  }
  await page.setViewportSize({ width: 844, height: 390 });
  await analyze(page);
  expect(
    await page
      .locator(".input-summary")
      .evaluate((n) => getComputedStyle(n).position),
  ).toBe("static");
});

async function start(page) {
  await page.goto("/#quiz");
  const response = page.waitForResponse("**/api/quiz");
  await page
    .getByRole("button", { name: "初級で練習する", exact: true })
    .click();
  return (await (await response).json()).questions;
}

test("quiz multi-select, inline terms, correct/incorrect feedback and saved learning", async ({
  page,
  request,
}, testInfo) => {
  const questions = await start(page);
  await page.locator(".choices input").nth(0).check();
  await page.locator(".choices input").nth(1).check();
  await expect(page.locator(".choices input:checked")).toHaveCount(2);
  await page.getByRole("link", { name: "門前", exact: true }).click();
  await expect(page.getByRole("dialog")).toContainText("門前");
  await expect(page.getByRole("dialog")).not.toContainText("読み込んでいます");
  await page.keyboard.press("Escape");
  await expect(page.locator(".choices input:checked")).toHaveCount(2);
  await page.locator(".choices input").nth(0).uncheck();
  await page.locator(".choices input").nth(1).uncheck();
  await page.getByRole("button", { name: "答え合わせ", exact: true }).click();
  await expect(page.locator(".feedback h2")).toHaveText("解説で確かめましょう");
  await expect(page.locator(".answer-comparison")).toContainText(
    "選び忘れた役",
  );
  if (testInfo.project.name === "mobile-chromium")
    await page.screenshot({ path: "docs/screenshots/quiz-after-390.png" });
  await page.getByRole("button", { name: "次の問題 →", exact: true }).click();
  const checked = await (
    await request.post("/api/quiz/check", {
      data: { question_id: questions[1].id, answers: [] },
    })
  ).json();
  for (const id of checked.correct_yaku)
    await page.locator(`.choices input[value="${id}"]`).check();
  await page.getByRole("button", { name: "答え合わせ", exact: true }).click();
  await expect(page.locator(".feedback h2")).toHaveText("正解です");
  const stored = await page.evaluate(() =>
    JSON.parse(localStorage.getItem("yaku-note.learning.v1")),
  );
  expect(stored.totalAnswered).toBe(2);
  expect(stored.totalCorrect).toBe(1);
  await page.reload();
  await page.getByRole("link", { name: "ホーム", exact: true }).click();
  await expect(page.locator(".stat strong").first()).toHaveText("2");
});

test("storage denied: quiz continues; back/forward keeps unsubmitted choices and hand", async ({
  page,
}) => {
  await page.addInitScript(() => {
    Object.defineProperty(window, "localStorage", {
      get() {
        throw new Error("unavailable");
      },
    });
  });
  await start(page);
  await page.locator(".choices input").first().check();
  await page.getByRole("link", { name: "役を覚える", exact: true }).click();
  await page.goBack();
  await expect(page.locator(".choices input:checked")).toHaveCount(1);
  await page.goForward();
  await expect(
    page.getByRole("heading", { name: "役を覚える", exact: true }),
  ).toBeVisible();
  await page.goBack();
  await page.getByRole("button", { name: "答え合わせ", exact: true }).click();
  await expect(page.locator(".feedback h2")).toBeVisible();
  await page.getByRole("link", { name: "ホーム", exact: true }).click();
  await expect(page.locator(".notice")).toContainText("保存ができません");
  await page
    .getByRole("link", { name: "手牌を調べる", exact: true })
    .first()
    .click();
  await palette(page, "man-2").click();
  await page.getByRole("link", { name: "用語集", exact: true }).click();
  await page.goBack();
  await expect(counter(page)).toHaveText("1 / 14枚相当");
});

test("judging survives navigation while its request is pending", async ({
  page,
}) => {
  await analyze(page);
  await page.locator(".analysis-examples summary").click();
  await page.getByRole("button", { name: "断么九＋平和", exact: true }).click();
  let release;
  const gate = new Promise((resolve) => {
    release = resolve;
  });
  await page.route("**/api/hand/analyze", async (route) => {
    await gate;
    await route.continue();
  });
  await page
    .getByRole("button", { name: "成立する役を調べる", exact: true })
    .click();
  await page.getByRole("link", { name: "用語集", exact: true }).click();
  await page.goBack();
  release();
  await expect(
    page.getByRole("heading", {
      name: "成立する役が見つかりました",
      exact: true,
    }),
  ).toBeVisible();
  await expect(
    page.getByRole("button", { name: "成立する役を調べる", exact: true }),
  ).toBeEnabled();
});

test("analysis error is actionable and reduced motion is respected", async ({
  page,
}) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await analyze(page);
  await page.locator(".analysis-examples summary").click();
  await page.getByRole("button", { name: "断么九＋平和", exact: true }).click();
  await page.route("**/api/hand/analyze", (route) =>
    route.fulfill({ status: 400, json: { error_kind: "invalid_context" } }),
  );
  await page
    .getByRole("button", { name: "成立する役を調べる", exact: true })
    .click();
  await expect(page.getByRole("alert")).toContainText("和了条件");
  await page
    .getByRole("button", { name: "和了条件を確認する", exact: true })
    .click();
  await expect(page.locator('[data-focus="winning-tile"]')).toBeFocused();
  expect(
    await page.evaluate(
      () => matchMedia("(prefers-reduced-motion: reduce)").matches,
    ),
  ).toBe(true);
});

test("catalog visual lessons are labeled examples and keyboard choices remain usable", async ({
  page,
}) => {
  await page.goto("/#catalog");
  await expect(page.locator(".visual-lesson")).toHaveCount(7);
  const pinfu = page
    .locator(".yaku-card")
    .filter({ has: page.locator("summary strong", { hasText: /^平和$/ }) });
  await pinfu.locator("summary").click();
  await expect(pinfu.locator(".visual-lesson")).toContainText("両面待ち");
  await expect(pinfu.locator(".visual-lesson .winning")).toHaveCount(1);
  await noOverflow(page);
  await start(page);
  const first = page.locator(".choices input").first();
  await first.focus();
  await page.keyboard.press("Space");
  await expect(first).toBeChecked();
  await page.keyboard.press("Space");
  await expect(first).not.toBeChecked();
  await page.getByRole("link", { name: "本文へ移動", exact: true }).focus();
  await page.keyboard.press("Enter");
  await expect(page.locator("main")).toBeFocused();
  await expect(page.locator(".quiz-top")).toBeVisible();
});
