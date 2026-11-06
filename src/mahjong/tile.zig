const std = @import("std");
pub const Suit = enum { man, pin, sou, honor };
pub const Tile = struct {
    suit: Suit,
    value: u8,
    pub fn validate(self: Tile) bool {
        return self.value >= 1 and self.value <= (if (self.suit == .honor) @as(u8, 7) else 9);
    }
    pub fn index(self: Tile) usize {
        return @as(usize, @backingInt(self.suit)) * 9 + self.value - 1;
    }
    pub fn canonical(self: Tile) []const u8 {
        if (!self.validate()) return "invalid";
        return switch (self.suit) {
            .man => man[self.value - 1],
            .pin => pin[self.value - 1],
            .sou => sou[self.value - 1],
            .honor => honors[self.value - 1],
        };
    }
};
const man = [_][]const u8{ "1m", "2m", "3m", "4m", "5m", "6m", "7m", "8m", "9m" };
const pin = [_][]const u8{ "1p", "2p", "3p", "4p", "5p", "6p", "7p", "8p", "9p" };
const sou = [_][]const u8{ "1s", "2s", "3s", "4s", "5s", "6s", "7s", "8s", "9s" };
pub const honors = [_][]const u8{ "east", "south", "west", "north", "white", "green", "red" };
pub fn parse(text: []const u8) error{InvalidTile}!Tile {
    if (text.len == 2 and text[0] >= '1' and text[0] <= '9') {
        const suit: Suit = switch (text[1]) {
            'm' => .man,
            'p' => .pin,
            's' => .sou,
            else => return error.InvalidTile,
        };
        return .{ .suit = suit, .value = text[0] - '0' };
    }
    for (honors, 1..) |name, value| if (std.mem.eql(u8, name, text)) return .{ .suit = .honor, .value = @intCast(value) };
    return error.InvalidTile;
}
/// Compile-time canonical notation; bad bank data fails the build.
pub fn tiles(comptime text: []const u8) []const Tile {
    @setEvalBranchQuota(100000);
    const result = comptime blk: {
        var count: usize = 0;
        var it = std.mem.tokenizeScalar(u8, text, ' ');
        while (it.next() != null) count += 1;
        var values: [count]Tile = undefined;
        it = std.mem.tokenizeScalar(u8, text, ' ');
        var i: usize = 0;
        while (it.next()) |token| {
            values[i] = parse(token) catch @compileError("Invalid canonical tile: " ++ token);
            i += 1;
        }
        break :blk values;
    };
    return &result;
}
test "canonical parsing and validation" {
    const t = std.testing;
    for (0..4) |s| for (1..(if (s == 3) @as(usize, 8) else 10)) |v| {
        const tile: Tile = .{ .suit = @fromBackingInt(@intCast(s)), .value = @intCast(v) };
        try t.expect(tile.validate());
        try t.expectEqual(tile, try parse(tile.canonical()));
    };
    for ([_][]const u8{ "0m", "10p", "5z", "East", "red5m", "" }) |bad| try t.expectError(error.InvalidTile, parse(bad));
    try t.expect(!(Tile{ .suit = .honor, .value = 8 }).validate());
    try t.expect(!(Tile{ .suit = .man, .value = 0 }).validate());
    try t.expectEqual(@as(usize, 3), tiles("1m east red").len);
}
