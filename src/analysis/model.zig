const Tile = @import("../mahjong/tile.zig").Tile;
const Wind = @import("../quiz/question.zig").Wind;
pub const DeclaredMeld = struct { kind: enum { chi, pon, kan, ankan }, tiles: []const Tile };
pub const Request = struct {
    /// Concealed tiles including the winning tile. Declared melds live separately.
    hand: []const Tile,
    melds: []const DeclaredMeld = &.{},
    winning_tile: Tile,
    win_method: enum { ron, tsumo } = .ron,
    round_wind: Wind = .east,
    seat_wind: Wind = .south,
    riichi: enum { none, riichi, double_riichi } = .none,
    ippatsu: bool = false,
    special: enum { none, haitei, houtei, rinshan, chankan, tenhou, chiihou } = .none,
};
pub const Match = struct {
    id: []const u8,
    name_ja: []const u8,
    reading: []const u8,
    han: ?u8,
    is_yakuman: bool,
    reason: []const u8,
};
pub const Group = struct {
    kind: enum { sequence, triplet, quad, pair, orphan },
    tiles: []const Tile,
    concealed: bool,
    winning_group: bool,
};
pub const Pattern = struct {
    form: enum { standard, seven_pairs, thirteen_orphans },
    groups: []const Group,
    yaku: []const Match,
    total_han: u16,
    yakuman_count: u8,
};
pub const Response = struct {
    status: enum { winning, no_yaku, not_winning },
    closed: bool,
    patterns: []const Pattern,
    message: []const u8,
};
