const std = @import("std");
const main = @import("../main.zig");
const dto = @import("dto.zig");
const bank = @import("../quiz/question_bank.zig");
test "typed API catalog, quiz privacy, grading, errors, OpenAPI and client generation" {
    var app = try main.buildApplication(std.testing.allocator);
    defer app.deinit();
    var client = app.client(std.testing.allocator);
    defer client.deinit();
    var list = try client.get("/api/yaku").send();
    defer list.deinit();
    try list.expectStatus(.ok);
    try std.testing.expectEqual(@as(usize, @import("../mahjong/yaku_catalog.zig").all.len), (try list.json(dto.YakuList)).yaku.len);
    var found = try client.get("/api/yaku/pinfu").send();
    defer found.deinit();
    try found.expectStatus(.ok);
    var missing = try client.get("/api/yaku/nope").send();
    defer missing.deinit();
    try missing.expectStatus(.not_found);
    var quiz = try client.post("/api/quiz").json(.{ .difficulty = "beginner", .count = 10 }).send();
    defer quiz.deinit();
    try quiz.expectStatus(.ok);
    const public = try quiz.json(dto.QuizResponse);
    try std.testing.expectEqual(@as(usize, 10), public.questions.len);
    for ([_][]const u8{ "correct_yaku", "primary_yaku", "explanation", "decomposition" }) |secret| try std.testing.expect(std.mem.indexOf(u8, quiz.body, secret) == null);
    for ([_][]const u8{ "intermediate", "advanced" }) |difficulty| {
        var level = try client.post("/api/quiz").json(.{ .difficulty = difficulty, .count = 10 }).send();
        defer level.deinit();
        try level.expectStatus(.ok);
        try std.testing.expectEqual(@as(usize, 10), (try level.json(dto.QuizResponse)).questions.len);
    }
    const question = bank.find(public.questions[0].id).?;
    var right = try client.post("/api/quiz/check").json(.{ .question_id = question.id, .answers = question.correct_yaku }).send();
    defer right.deinit();
    try right.expectStatus(.ok);
    try std.testing.expect((try right.json(dto.CheckResponse)).correct);
    var wrong = try client.post("/api/quiz/check").json(.{ .question_id = "b-10", .answers = [_][]const u8{"tanyao"} }).send();
    defer wrong.deinit();
    try wrong.expectStatus(.ok);
    try std.testing.expect(!(try wrong.json(dto.CheckResponse)).correct);
    var order = try client.post("/api/quiz/check").json(.{ .question_id = "b-10", .answers = [_][]const u8{ "pinfu", "tanyao" } }).send();
    defer order.deinit();
    try std.testing.expect((try order.json(dto.CheckResponse)).correct);
    var bad = try client.post("/api/quiz").json(.{ .difficulty = "expert", .count = 10 }).send();
    defer bad.deinit();
    try bad.expectStatus(.bad_request);
    for ([_]u8{ 0, 11 }) |count| {
        var invalid = try client.post("/api/quiz").json(.{ .difficulty = "beginner", .count = count }).send();
        defer invalid.deinit();
        try invalid.expectStatus(.unprocessable_entity);
    }
    var unknown = try client.post("/api/quiz/check").json(.{ .question_id = "unknown", .answers = [_][]const u8{} }).send();
    defer unknown.deinit();
    try unknown.expectStatus(.not_found);
    var unknown_yaku = try client.post("/api/quiz/check").json(.{ .question_id = "b-10", .answers = [_][]const u8{"unknown"} }).send();
    defer unknown_yaku.deinit();
    try unknown_yaku.expectStatus(.bad_request);
    var not_offered = try client.post("/api/quiz/check").json(.{ .question_id = "b-10", .answers = [_][]const u8{"kokushi_musou"} }).send();
    defer not_offered.deinit();
    try not_offered.expectStatus(.bad_request);
    const many = [_][]const u8{ "pinfu", "pinfu", "pinfu", "pinfu", "pinfu", "pinfu", "pinfu" };
    var excessive = try client.post("/api/quiz/check").json(.{ .question_id = "b-10", .answers = many }).send();
    defer excessive.deinit();
    try excessive.expectStatus(.bad_request);
    const oversized: [5000]u8 = @splat('x');
    var large = try client.post("/api/quiz").json(.{ .difficulty = "beginner", .extra = oversized }).send();
    defer large.deinit();
    try large.expectStatus(.payload_too_large);
    var doc = try client.get("/openapi.json").send();
    defer doc.deinit();
    try doc.expectStatus(.ok);
    const parsed = try doc.json(std.json.Value);
    const paths = parsed.object.get("paths").?.object;
    try std.testing.expect(paths.get("/api/yaku/{id}") != null);
    try std.testing.expect(paths.get("/api/quiz").?.object.get("post") != null);
    var generated = try client.get("/client.ts").send();
    defer generated.deinit();
    try generated.expectStatus(.ok);
    try std.testing.expect(std.mem.indexOf(u8, generated.body, "postApiQuiz") != null);
    try std.testing.expect(std.mem.indexOf(u8, generated.body, "postApiQuizCheck") != null);
}

test "each bank fixture grades its complete role set through the application graph" {
    var app = try main.buildApplication(std.testing.allocator);
    defer app.deinit();
    var client = app.client(std.testing.allocator);
    defer client.deinit();
    for (bank.all) |q| {
        var response = try client.post("/api/quiz/check").json(.{ .question_id = q.id, .answers = q.correct_yaku }).send();
        defer response.deinit();
        try response.expectStatus(.ok);
        try std.testing.expect((try response.json(dto.CheckResponse)).correct);
    }
}

test "hand analysis and glossary share typed application contract" {
    var app = try main.buildApplication(std.testing.allocator);
    defer app.deinit();
    var client = app.client(std.testing.allocator);
    defer client.deinit();
    const tiles = @import("../mahjong/tile.zig");
    const input: @import("../analysis/model.zig").Request = .{ .hand = tiles.tiles("2m 3m 4m 4m 5m 6m 3p 4p 5p 6s 7s 8s 2p 2p"), .winning_tile = try tiles.parse("8s") };
    var result = try client.post("/api/hand/analyze").json(input).send();
    defer result.deinit();
    try result.expectStatus(.ok);
    const parsed = try result.json(@import("../analysis/model.zig").Response);
    try std.testing.expectEqual(.winning, parsed.status);
    try std.testing.expectEqual(@as(usize, 2), parsed.patterns[0].yaku.len);
    var bad = input;
    bad.hand = tiles.tiles("1m");
    var invalid = try client.post("/api/hand/analyze").json(bad).send();
    defer invalid.deinit();
    try invalid.expectStatus(.bad_request);
    var enum_error = try client.post("/api/hand/analyze").json(.{ .hand = input.hand, .winning_tile = input.winning_tile, .win_method = "invalid" }).send();
    defer enum_error.deinit();
    try enum_error.expectStatus(.bad_request);
    var glossary = try client.get("/api/glossary").send();
    defer glossary.deinit();
    try glossary.expectStatus(.ok);
    const terms = try glossary.json(struct { terms: []const @import("../mahjong/glossary.zig").Term });
    try std.testing.expect(terms.terms.len >= 40);
    var existing = try client.get("/api/glossary/ryanmen").send();
    defer existing.deinit();
    try existing.expectStatus(.ok);
    var unknown = try client.get("/api/glossary/unknown").send();
    defer unknown.deinit();
    try unknown.expectStatus(.not_found);
    var schema = try client.get("/openapi.json").send();
    defer schema.deinit();
    const document = try schema.json(std.json.Value);
    try std.testing.expect(document.object.get("paths").?.object.get("/api/hand/analyze") != null);
    try std.testing.expect(document.object.get("paths").?.object.get("/api/glossary/{id}") != null);
}
