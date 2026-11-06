const assets = @import("../web/assets.zig").files;
const std = @import("std");
const ak = @import("akamata");
const Ctx = ak.Context(@import("../main.zig").State);
const dto = @import("dto.zig");
const catalog = @import("../mahjong/yaku_catalog.zig");
const generator = @import("../quiz/generator.zig");
const evaluator = @import("../quiz/evaluator.zig");
const Yaku = @import("../mahjong/yaku.zig").Yaku;
pub fn listYaku() dto.YakuList {
    return .{ .yaku = &catalog.all };
}
pub fn showYaku(id: ak.Path([]const u8, "id")) error{not_found}!Yaku {
    return catalog.find(id.value) orelse error.not_found;
}
pub fn quiz(c: *Ctx, body: ak.Json(dto.QuizRequest)) !dto.QuizResponse {
    var seed: u64 = undefined;
    ak.crypto.randomBytes(std.mem.asBytes(&seed));
    var prng: std.Random.DefaultPrng = .init(seed);
    return generator.generate(c.arena, body.value.difficulty, body.value.count, prng.random());
}
pub fn check(c: *Ctx, body: ak.Json(dto.CheckRequest)) !dto.CheckResponse {
    return evaluator.evaluate(c.arena, body.value.question_id, body.value.answers) catch |err| switch (err) {
        error.NotFound => error.not_found,
        error.InvalidAnswers => error.invalid_answers,
        else => err,
    };
}
pub fn index(c: *Ctx) !void {
    try c.html(assets.index);
}
pub fn javascript(c: *Ctx) !void {
    try c.header("content-type", "text/javascript; charset=utf-8");
    try c.body(assets.javascript);
}
pub fn tilescript(c: *Ctx) !void {
    try c.header("content-type", "text/javascript; charset=utf-8");
    try c.body(assets.tiles);
}
pub fn statsScript(c: *Ctx) !void {
    try c.header("content-type", "text/javascript; charset=utf-8");
    try c.body(assets.stats);
}
pub fn css(c: *Ctx) !void {
    try c.header("content-type", "text/css; charset=utf-8");
    try c.body(assets.styles);
}
pub fn openapi(c: *Ctx) anyerror!void {
    var metadata: @import("../main.zig").Application.Metadata = .{};
    const bytes = try ak.openapi.generate(@TypeOf(metadata), &metadata, c.arena, .{ .title = "役のノート", .version = "1.0.0" });
    try c.header("content-type", "application/json");
    try c.body(bytes);
}
pub fn client(c: *Ctx) anyerror!void {
    var metadata: @import("../main.zig").Application.Metadata = .{};
    const bytes = try ak.client_gen.generate(@TypeOf(metadata), &metadata, c.arena, .{ .target = .typescript });
    try c.header("content-type", "application/typescript");
    try c.body(bytes);
}

pub fn analyze(c: *Ctx, body: ak.Json(@import("../analysis/model.zig").Request)) !@import("../analysis/model.zig").Response {
    return @import("../analysis/evaluator.zig").evaluate(c.arena, body.value);
}
pub fn glossary() struct { terms: []const @import("../mahjong/glossary.zig").Term } {
    return .{ .terms = &@import("../mahjong/glossary.zig").all };
}
pub fn glossaryTerm(id: ak.Path([]const u8, "id")) error{not_found}!@import("../mahjong/glossary.zig").Term {
    return @import("../mahjong/glossary.zig").find(id.value) orelse error.not_found;
}
pub fn analyzerScript(c: *Ctx) !void {
    try c.header("content-type", "text/javascript; charset=utf-8");
    try c.body(assets.analyzer);
}
pub fn handInputScript(c: *Ctx) !void {
    try c.header("content-type", "text/javascript; charset=utf-8");
    try c.body(assets.hand_input);
}
