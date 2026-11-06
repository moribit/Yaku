const std = @import("std");
const bank = @import("question_bank.zig");
const catalog = @import("../mahjong/yaku_catalog.zig");
const dto = @import("../app/dto.zig");
const Yaku = @import("../mahjong/yaku.zig").Yaku;
pub fn evaluate(allocator: std.mem.Allocator, question_id: []const u8, answers: []const []const u8) !dto.CheckResponse {
    const q = bank.find(question_id) orelse return error.NotFound;
    if (answers.len > 6) return error.InvalidAnswers;
    var selected: std.ArrayList([]const u8) = .empty;
    var matched: std.ArrayList([]const u8) = .empty;
    var missed: std.ArrayList([]const u8) = .empty;
    var extra: std.ArrayList([]const u8) = .empty;
    var details: std.ArrayList(Yaku) = .empty;
    for (answers) |id| {
        const yaku = catalog.find(id) orelse return error.InvalidAnswers;
        if (!bank.contains(q.correct_yaku, id) and !bank.contains(q.distractors, id)) return error.InvalidAnswers;
        if (!bank.contains(selected.items, id)) try selected.append(allocator, yaku.id);
    }
    for (q.correct_yaku) |id| {
        try details.append(allocator, catalog.find(id).?);
        if (bank.contains(selected.items, id)) try matched.append(allocator, id) else try missed.append(allocator, id);
    }
    for (selected.items) |id| if (!bank.contains(q.correct_yaku, id)) {
        try extra.append(allocator, id);
        try details.append(allocator, catalog.find(id).?);
    };
    return .{ .correct = missed.items.len == 0 and extra.items.len == 0, .correct_yaku = q.correct_yaku, .selected_yaku = selected.items, .matched_yaku = matched.items, .missed_yaku = missed.items, .extra_yaku = extra.items, .explanation = q.explanation, .decomposition = q.decomposition, .yaku = details.items };
}
test "set evaluation, multi-yaku, omissions, extras, duplicates and unknowns" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    try std.testing.expect((try evaluate(a, "b-10", &.{ "pinfu", "tanyao" })).correct);
    try std.testing.expect((try evaluate(a, "b-10", &.{ "pinfu", "tanyao", "pinfu" })).correct);
    const missing = try evaluate(a, "b-10", &.{"tanyao"});
    try std.testing.expect(!missing.correct);
    try std.testing.expectEqualStrings("pinfu", missing.missed_yaku[0]);
    const extra = try evaluate(a, "b-10", &.{ "pinfu", "tanyao", "riichi" });
    try std.testing.expect(!extra.correct);
    try std.testing.expectEqualStrings("riichi", extra.extra_yaku[0]);
    try std.testing.expect(!(try evaluate(a, "b-10", &.{})).correct);
    try std.testing.expectError(error.NotFound, evaluate(a, "nope", &.{}));
    try std.testing.expectError(error.InvalidAnswers, evaluate(a, "b-10", &.{"unknown"}));
    try std.testing.expectError(error.InvalidAnswers, evaluate(a, "b-10", &.{"kokushi_musou"}));
    const composite = bank.find("a-01").?;
    try std.testing.expect((try evaluate(a, composite.id, composite.correct_yaku)).correct);
}
