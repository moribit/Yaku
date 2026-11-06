const Tile = @import("tile.zig").Tile;
pub const Meld = struct {
    kind: enum { chi, pon, kan },
    tiles: []const Tile,
    pub fn equivalentCount(self: Meld) usize {
        _ = self;
        return 3;
    }
    pub fn validate(self: Meld) bool {
        if (self.tiles.len != (if (self.kind == .kan) @as(usize, 4) else 3)) return false;
        for (self.tiles) |tile| if (!tile.validate()) return false;
        const a = self.tiles[0];
        for (self.tiles, 0..) |tile, i| {
            if (tile.suit != a.suit) return false;
            if (self.kind == .chi) {
                if (a.suit == .honor or tile.value != a.value + i) return false;
            } else if (tile.value != a.value) return false;
        }
        return true;
    }
};
