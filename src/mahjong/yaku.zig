const Tile = @import("tile.zig").Tile;
pub const Category = enum { one_han, two_han, three_plus, yakuman };
pub const Yaku = struct {
    id: []const u8,
    name_ja: []const u8,
    reading: []const u8,
    closed_han: ?u8,
    open_han: ?u8,
    category: Category,
    description: []const u8,
    condition: []const u8,
    mnemonic: []const u8,
    is_yakuman: bool = false,
    example: []const Tile,
};
