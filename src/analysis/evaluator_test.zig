const std = @import("std");
const engine = @import("evaluator.zig");
const model = @import("model.zig");
const tile = @import("../mahjong/tile.zig");
const bank = @import("../quiz/question_bank.zig");
fn request(comptime text: []const u8, comptime winning: []const u8) model.Request {
    return .{ .hand = tile.tiles(text), .winning_tile = tile.parse(winning) catch unreachable };
}
fn has(pattern: model.Pattern, id: []const u8) bool {
    for (pattern.yaku) |y| if (std.mem.eql(u8, y.id, id)) return true;
    return false;
}
fn any(result: model.Response, id: []const u8) bool {
    for (result.patterns) |p| if (has(p, id)) return true;
    return false;
}

test "free-hand engine matches every manually specified Question Bank answer set" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();
    for (bank.all) |q| {
        const melds = try arena.allocator().alloc(model.DeclaredMeld, q.open_melds.len);
        for (q.open_melds, melds) |m, *out| out.* = .{ .kind = switch (m.kind) {
            .chi => .chi,
            .pon => .pon,
            .kan => .kan,
        }, .tiles = m.tiles };
        const r = try engine.evaluate(arena.allocator(), .{ .hand = q.hand, .melds = melds, .winning_tile = q.context.winning_tile, .win_method = if (q.context.win_method == .ron) .ron else .tsumo, .round_wind = q.context.round_wind, .seat_wind = q.context.seat_wind, .riichi = if (q.context.riichi) .riichi else .none });
        var matches = false;
        for (r.patterns) |p| {
            if (p.yaku.len != q.correct_yaku.len) continue;
            var equal = true;
            for (q.correct_yaku) |id| if (!has(p, id)) {
                equal = false;
            };
            if (equal) matches = true;
        }
        if (!matches) std.debug.print("Bank mismatch: {s}\n", .{q.id});
        try std.testing.expect(matches);
    }
}
test "pinfu requires winning-tile assignment and excludes value heads and edge waits" {
    var a: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer a.deinit();
    const input = request("1m 2m 3m 4m 5m 6m 7p 8p 9p 2s 3s 4s 5p 5p", "4s");
    try std.testing.expect(any(try engine.evaluate(a.allocator(), input), "pinfu"));
    var middle = input;
    middle.winning_tile = try tile.parse("3s");
    try std.testing.expect(!any(try engine.evaluate(a.allocator(), middle), "pinfu"));
    const edge = request("1m 2m 3m 4m 5m 6m 7p 8p 9p 2s 3s 4s 5p 5p", "3m");
    try std.testing.expect(!any(try engine.evaluate(a.allocator(), edge), "pinfu"));
    const head = request("1m 2m 3m 4m 5m 6m 7p 8p 9p 2s 3s 4s white white", "4s");
    try std.testing.expect(!any(try engine.evaluate(a.allocator(), head), "pinfu"));
    const value = request("1m 2m 3m 4m 5m 6m 7p 8p 9p 2s 3s 4s south south", "4s");
    try std.testing.expect(!any(try engine.evaluate(a.allocator(), value), "pinfu"));
}
test "ron triplet is not concealed; suuankou requires tsumo or pair ron" {
    var a: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer a.deinit();
    var r = request("2m 2m 2m 4p 4p 4p 6s 6s 6s 9m 9m 9m east east", "9m");
    const ron = try engine.evaluate(a.allocator(), r);
    try std.testing.expect(any(ron, "sanankou") and any(ron, "toitoi") and !any(ron, "suuankou"));
    r.win_method = .tsumo;
    const tsumo = try engine.evaluate(a.allocator(), r);
    try std.testing.expect(any(tsumo, "suuankou") and !any(tsumo, "sanankou") and !any(tsumo, "menzen_tsumo"));
    r.win_method = .ron;
    r.winning_tile = try tile.parse("east");
    try std.testing.expect(any(try engine.evaluate(a.allocator(), r), "suuankou"));
}
test "seven pairs, ryanpeikou and ambiguity remain separate interpretations" {
    var a: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer a.deinit();
    const ambiguous = request("1m 1m 2m 2m 3m 3m 7p 7p 8p 8p 9p 9p 5s 5s", "9p");
    const result = try engine.evaluate(a.allocator(), ambiguous);
    try std.testing.expect(any(result, "chiitoitsu") and any(result, "ryanpeikou"));
    for (result.patterns) |p| try std.testing.expect(!(has(p, "chiitoitsu") and has(p, "ryanpeikou")) and !has(p, "iipeikou"));
    const four_copies = request("1m 1m 1m 1m 3m 3m 5p 5p 7p 7p 2s 2s east east", "east");
    try std.testing.expect(!any(try engine.evaluate(a.allocator(), four_copies), "chiitoitsu"));
}
test "kokushi and tile-based yakuman including seven-pairs honors" {
    var a: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer a.deinit();
    const k = request("1m 9m 1p 9p 1s 9s east south west north white green red east", "east");
    try std.testing.expect(any(try engine.evaluate(a.allocator(), k), "kokushi_musou"));
    const honors = request("east east south south west west north north white white green green red red", "red");
    const h = try engine.evaluate(a.allocator(), honors);
    try std.testing.expect(any(h, "tsuuiisou") and !any(h, "chiitoitsu"));
    const g = request("2s 3s 4s 2s 3s 4s 6s 6s 6s 8s 8s 8s green green", "4s");
    try std.testing.expect(any(try engine.evaluate(a.allocator(), g), "ryuuiisou"));
    const nine = request("1m 1m 1m 2m 3m 4m 5m 6m 7m 8m 9m 9m 9m 5m", "5m");
    try std.testing.expect(any(try engine.evaluate(a.allocator(), nine), "chuurenpoutou"));
}
test "kan equivalents, closed kan, and double-wind role value" {
    var a: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer a.deinit();
    var r = request("1m 2m 3m 4p 5p 6p 7s 8s 9s 5m 5m", "9s");
    r.melds = &.{.{ .kind = .ankan, .tiles = tile.tiles("east east east east") }};
    r.win_method = .tsumo;
    r.seat_wind = .east;
    const result = try engine.evaluate(a.allocator(), r);
    try std.testing.expect(result.closed and any(result, "menzen_tsumo"));
    var value: u8 = 0;
    for (result.patterns) |p| for (p.yaku) |y| if (std.mem.eql(u8, y.id, "yakuhai")) {
        value = y.han.?;
    };
    try std.testing.expectEqual(@as(u8, 2), value);
    r.melds = &.{.{ .kind = .kan, .tiles = tile.tiles("east east east east") }};
    try std.testing.expect(!(try engine.evaluate(a.allocator(), r)).closed);
}
test "invalid tiles, five copies, invalid melds and impossible context reject safely" {
    var a: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer a.deinit();
    var r = request("1m 2m 3m 4p 5p 6p 7s 8s 9s 5m 5m 5m east east", "5m");
    var bad = r;
    bad.hand = tile.tiles("1m");
    try std.testing.expectError(error.invalid_tile_count, engine.evaluate(a.allocator(), bad));
    bad = r;
    bad.winning_tile = try tile.parse("red");
    try std.testing.expectError(error.missing_winning_tile, engine.evaluate(a.allocator(), bad));
    bad = r;
    bad.winning_tile = .{ .suit = .honor, .value = 8 };
    try std.testing.expectError(error.invalid_tile, engine.evaluate(a.allocator(), bad));
    bad = request("1m 1m 1m 1m 1m 2m 3m 4p 5p 6p 7s 8s 9s east", "1m");
    try std.testing.expectError(error.too_many_copies, engine.evaluate(a.allocator(), bad));
    r = request("1m 2m 3m 4p 5p 6p 7s 8s 9s 5m 5m", "9s");
    r.melds = &.{.{ .kind = .chi, .tiles = tile.tiles("white white white") }};
    try std.testing.expectError(error.invalid_meld, engine.evaluate(a.allocator(), r));
    r.melds = &.{.{ .kind = .pon, .tiles = tile.tiles("white white white") }};
    r.riichi = .riichi;
    try std.testing.expectError(error.invalid_context, engine.evaluate(a.allocator(), r));
    r.riichi = .none;
    r.special = .haitei;
    try std.testing.expectError(error.invalid_context, engine.evaluate(a.allocator(), r));
}
test "valid shape without role and incomplete shape are different results" {
    var a: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer a.deinit();
    const none = request("1m 2m 3m 4p 5p 6p 7s 8s 9s 5m 5m 5m east east", "5m");
    try std.testing.expectEqual(.no_yaku, (try engine.evaluate(a.allocator(), none)).status);
    const incomplete = request("1m 2m 4m 4p 5p 6p 7s 8s 9s 5m 5m 5m east east", "4m");
    try std.testing.expectEqual(.not_winning, (try engine.evaluate(a.allocator(), incomplete)).status);
}

test "remaining structural roles and yakuman suppress ordinary roles" {
    var a: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer a.deinit();
    const fixtures = .{
        .{ "white white white green green green red red red 1m 2m 3m east east", "3m", "daisangen" },
        .{ "east east east south south south west west west north north 1m 2m 3m", "3m", "shousuushii" },
        .{ "east east east south south south west west west north north north 5m 5m", "north", "daisuushii" },
        .{ "1m 1m 1m 9m 9m 9m 1p 1p 1p 9p 9p 9p 1s 1s", "9p", "chinroutou" },
        .{ "1m 1m 1m 9p 9p 9p east east east white white white 9s 9s", "1m", "honroutou" },
    };
    inline for (fixtures) |fixture| {
        const result = try engine.evaluate(a.allocator(), request(fixture[0], fixture[1]));
        try std.testing.expect(any(result, fixture[2]));
        for (result.patterns) |pattern| if (pattern.yakuman_count > 0) {
            for (pattern.yaku) |role| try std.testing.expect(role.is_yakuman);
        };
    }
    var kan = request("7m 8m 9m 5p 5p", "9m");
    kan.melds = &.{
        .{ .kind = .kan, .tiles = tile.tiles("2m 2m 2m 2m") }, .{ .kind = .ankan, .tiles = tile.tiles("4p 4p 4p 4p") }, .{ .kind = .ankan, .tiles = tile.tiles("6s 6s 6s 6s") },
    };
    try std.testing.expect(any(try engine.evaluate(a.allocator(), kan), "sankantsu"));
    kan = request("east east", "east");
    kan.melds = &.{
        .{ .kind = .kan, .tiles = tile.tiles("2m 2m 2m 2m") }, .{ .kind = .ankan, .tiles = tile.tiles("4p 4p 4p 4p") }, .{ .kind = .ankan, .tiles = tile.tiles("6s 6s 6s 6s") }, .{ .kind = .kan, .tiles = tile.tiles("9m 9m 9m 9m") },
    };
    const four = try engine.evaluate(a.allocator(), kan);
    try std.testing.expect(any(four, "suukantsu") and !any(four, "sankantsu"));
}
test "declared situational roles, riichi exclusivity and impossible first-draw context" {
    var a: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer a.deinit();
    var r = request("1m 2m 3m 4p 5p 6p 7s 8s 9s 5m 5m 5m east east", "5m");
    r.riichi = .double_riichi;
    r.ippatsu = true;
    const declared = try engine.evaluate(a.allocator(), r);
    try std.testing.expect(any(declared, "double_riichi") and any(declared, "ippatsu") and !any(declared, "riichi"));
    r.riichi = .none;
    r.ippatsu = false;
    r.special = .houtei;
    try std.testing.expect(any(try engine.evaluate(a.allocator(), r), "houtei"));
    r.special = .chankan;
    try std.testing.expect(any(try engine.evaluate(a.allocator(), r), "chankan"));
    r.win_method = .tsumo;
    r.special = .haitei;
    try std.testing.expect(any(try engine.evaluate(a.allocator(), r), "haitei"));
    r.special = .chiihou;
    const child = try engine.evaluate(a.allocator(), r);
    try std.testing.expect(any(child, "chiihou") and !any(child, "menzen_tsumo"));
    r.special = .tenhou;
    try std.testing.expectError(error.invalid_context, engine.evaluate(a.allocator(), r));
    r.seat_wind = .east;
    try std.testing.expect(any(try engine.evaluate(a.allocator(), r), "tenhou"));
    r = request("1m 2m 3m 4p 5p 6p 7s 8s 9s 5m 5m", "9s");
    r.win_method = .tsumo;
    r.special = .rinshan;
    r.melds = &.{.{ .kind = .ankan, .tiles = tile.tiles("white white white white") }};
    try std.testing.expect(any(try engine.evaluate(a.allocator(), r), "rinshan"));
    r.riichi = .riichi;
    r.ippatsu = true;
    try std.testing.expectError(error.invalid_context, engine.evaluate(a.allocator(), r));
}
test "open hand han reductions and negative concealed-only roles" {
    var a: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer a.deinit();
    var r = request("2p 3p 4p 2s 3s 4s 6m 7m 8m 5p 5p", "8m");
    r.melds = &.{.{ .kind = .chi, .tiles = tile.tiles("2m 3m 4m") }};
    const result = try engine.evaluate(a.allocator(), r);
    try std.testing.expect(any(result, "sanshoku_doujun") and any(result, "tanyao") and !any(result, "pinfu"));
    var han: u8 = 0;
    for (result.patterns) |pattern| for (pattern.yaku) |y| if (std.mem.eql(u8, y.id, "sanshoku_doujun")) {
        han = y.han.?;
    };
    try std.testing.expectEqual(@as(u8, 1), han);
}
