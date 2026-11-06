const Tile = @import("../mahjong/tile.zig").Tile;
const Meld = @import("../mahjong/meld.zig").Meld;
pub const Difficulty = enum { beginner, intermediate, advanced };
pub const Wind = enum { east, south, west, north };
pub const Context = struct {
    closed: bool = true,
    win_method: enum { ron, tsumo } = .ron,
    round_wind: Wind = .east,
    seat_wind: Wind = .south,
    riichi: bool = false,
    winning_tile: Tile,
    wait: enum { ryanmen, kanchan, penchan, shanpon, tanki },
    circumstances: []const u8 = "通常の和了。ダブル立直・一発・海底・河底・嶺上開花・槍槓・天和・地和はありません。",
};
pub const Question = struct {
    id: []const u8,
    difficulty: Difficulty,
    hand: []const Tile,
    open_melds: []const Meld = &.{},
    context: Context,
    primary_yaku: []const []const u8,
    correct_yaku: []const []const u8,
    distractors: []const []const u8,
    explanation: []const u8,
    /// Human audit aid, never included in pre-answer DTO.
    decomposition: []const u8,
};
