//! Exhaustive four-meld/pair decomposition for a bounded 14-tile-equivalent input.
//! Quiz grading deliberately continues to use its static Question Bank.
const std = @import("std");
const model = @import("model.zig");
const tile_mod = @import("../mahjong/tile.zig");
const Tile = tile_mod.Tile;
const catalog = @import("../mahjong/yaku_catalog.zig");
const Meld = @import("../mahjong/meld.zig").Meld;
const Kind = enum { sequence, triplet, quad };
const Part = struct { kind: Kind, base: usize, concealed: bool };
fn tileAt(i: usize) Tile {
    return .{ .suit = @fromBackingInt(@intCast(i / 9)), .value = @intCast(i % 9 + 1) };
}
fn terminal(i: usize) bool {
    return i < 27 and (i % 9 == 0 or i % 9 == 8);
}
fn outside(i: usize) bool {
    return i >= 27 or terminal(i);
}
fn green(i: usize) bool {
    return i == 19 or i == 20 or i == 21 or i == 23 or i == 25 or i == 32;
}
fn includes(part: Part, i: usize) bool {
    return if (part.kind == .sequence) i >= part.base and i <= part.base + 2 else i == part.base;
}

pub fn evaluate(allocator: std.mem.Allocator, req: model.Request) !model.Response {
    var engine: Engine = .{ .allocator = allocator, .req = req };
    try engine.validate();
    try engine.specialForms();
    for (0..34) |pair| {
        if (engine.counts[pair] < 2) continue;
        engine.counts[pair] -= 2;
        try engine.search(pair, req.melds.len);
        engine.counts[pair] += 2;
    }
    // Higher han comes first for readability; all valid role sets remain visible.
    std.mem.sort(model.Pattern, engine.patterns.items, {}, struct {
        fn less(_: void, a: model.Pattern, b: model.Pattern) bool {
            return if (a.yakuman_count != b.yakuman_count) a.yakuman_count > b.yakuman_count else a.total_han > b.total_han;
        }
    }.less);
    var has_yaku = false;
    for (engine.patterns.items) |pattern| if (pattern.yaku.len > 0) {
        has_yaku = true;
    };
    return .{ .status = if (has_yaku) .winning else if (engine.patterns.items.len > 0) .no_yaku else .not_winning, .closed = engine.closed, .patterns = engine.patterns.items, .message = if (has_yaku) "指定した和了条件で成立する役を、牌の分け方ごとに表示します。" else if (engine.patterns.items.len > 0) "和了の形ですが、指定した条件では役がありません。ドラだけでは和了できません。" else "この牌姿は4面子と雀頭、七対子、国士無双の和了形になっていません。" };
}
const Engine = struct {
    allocator: std.mem.Allocator,
    req: model.Request,
    counts: [34]u8 = @splat(0),
    all: [34]u8 = @splat(0),
    parts: [4]Part = undefined,
    closed: bool = true,
    patterns: std.ArrayList(model.Pattern) = .empty,
    nodes: usize = 0,

    fn validate(self: *Engine) !void {
        const r = self.req;
        if (r.melds.len > 4 or r.hand.len != 14 - 3 * r.melds.len) return error.invalid_tile_count;
        if (!r.winning_tile.validate()) return error.invalid_tile;
        for (r.hand) |tile| {
            if (!tile.validate()) return error.invalid_tile;
            self.counts[tile.index()] += 1;
            self.all[tile.index()] += 1;
        }
        if (self.counts[r.winning_tile.index()] == 0) return error.missing_winning_tile;
        for (r.melds, 0..) |m, j| {
            const regular: Meld = .{ .kind = switch (m.kind) {
                .chi => .chi,
                .pon => .pon,
                .kan, .ankan => .kan,
            }, .tiles = m.tiles };
            if (!regular.validate()) return error.invalid_meld;
            for (m.tiles) |tile| self.all[tile.index()] += 1;
            const concealed = m.kind == .ankan;
            if (!concealed) self.closed = false;
            self.parts[j] = .{ .kind = switch (m.kind) {
                .chi => .sequence,
                .pon => .triplet,
                .kan, .ankan => .quad,
            }, .base = m.tiles[0].index(), .concealed = concealed };
        }
        for (self.all) |count| if (count > 4) return error.too_many_copies;
        if (r.riichi != .none and !self.closed) return error.invalid_context;
        if (r.ippatsu and (r.riichi == .none or !self.closed)) return error.invalid_context;
        const has_kan = blk: {
            for (r.melds) |m| if (m.kind == .kan or m.kind == .ankan) break :blk true;
            break :blk false;
        };
        switch (r.special) {
            .haitei => if (r.win_method != .tsumo) return error.invalid_context,
            .houtei, .chankan => if (r.win_method != .ron) return error.invalid_context,
            .rinshan => if (r.win_method != .tsumo or !has_kan or r.ippatsu) return error.invalid_context,
            .tenhou, .chiihou => {
                if (r.win_method != .tsumo or r.melds.len != 0 or r.riichi != .none or r.ippatsu) return error.invalid_context;
                if ((r.special == .tenhou) != (r.seat_wind == .east)) return error.invalid_context;
            },
            .none => {},
        }
    }
    fn search(self: *Engine, pair: usize, len: usize) !void {
        self.nodes += 1;
        if (self.nodes > 20000) return error.DecompositionBudgetExceeded;
        var first: usize = 0;
        while (first < 34 and self.counts[first] == 0) : (first += 1) {}
        if (first == 34) {
            if (len != 4) return;
            const winning = self.req.winning_tile.index();
            if (pair == winning) try self.standard(pair, null);
            for (self.parts[self.req.melds.len..], self.req.melds.len..) |part, i| if (includes(part, winning)) try self.standard(pair, i);
            return;
        }
        if (len == 4) return;
        if (self.counts[first] >= 3) {
            self.counts[first] -= 3;
            self.parts[len] = .{ .kind = .triplet, .base = first, .concealed = true };
            try self.search(pair, len + 1);
            self.counts[first] += 3;
        }
        if (first < 27 and first % 9 <= 6 and self.counts[first + 1] > 0 and self.counts[first + 2] > 0) {
            for (0..3) |i| self.counts[first + i] -= 1;
            self.parts[len] = .{ .kind = .sequence, .base = first, .concealed = true };
            try self.search(pair, len + 1);
            for (0..3) |i| self.counts[first + i] += 1;
        }
    }
    fn match(self: *Engine, ids: *std.ArrayList(model.Match), id: []const u8, reason: []const u8, han_override: ?u8) !void {
        const y = catalog.find(id) orelse return error.UnknownImplementedYaku;
        try ids.append(self.allocator, .{ .id = y.id, .name_ja = y.name_ja, .reading = y.reading, .han = if (y.is_yakuman) null else han_override orelse (if (self.closed) y.closed_han.? else y.open_han.?), .is_yakuman = y.is_yakuman, .reason = reason });
    }
    fn environment(self: *Engine, ids: *std.ArrayList(model.Match), yakuman_only: bool) !void {
        const r = self.req;
        if (r.special == .tenhou or r.special == .chiihou) {
            try self.match(ids, if (r.special == .tenhou) "tenhou" else "chiihou", "入力された、鳴きのない最初のツモでの和了条件による役満です。", null);
        }
        if (yakuman_only) return;
        if (r.riichi != .none) try self.match(ids, if (r.riichi == .riichi) "riichi" else "double_riichi", "門前で入力された立直宣言が成立条件です。", null);
        if (r.ippatsu) try self.match(ids, "ippatsu", "立直後の一巡以内で、途中に鳴きのない和了として指定されています。", null);
        if (self.closed and r.win_method == .tsumo) try self.match(ids, "menzen_tsumo", "門前を保って自分で和了牌を引いています。", null);
        const special_id: ?[]const u8 = switch (r.special) {
            .haitei => "haitei",
            .houtei => "houtei",
            .rinshan => "rinshan",
            .chankan => "chankan",
            else => null,
        };
        if (special_id) |id| try self.match(ids, id, "入力された和了時の状況により成立します。", null);
    }
    fn tileTraits(self: *Engine, ids: *std.ArrayList(model.Match), yakuman_only: bool) !void {
        var simples = true;
        var only_outside = true;
        var only_terminals = true;
        var only_honors = true;
        var only_green = true;
        var has_honors = false;
        var suits: [3]bool = @splat(false);
        for (self.all, 0..) |count, i| {
            if (count == 0) continue;
            simples = simples and !outside(i);
            only_outside = only_outside and outside(i);
            only_terminals = only_terminals and terminal(i);
            only_honors = only_honors and i >= 27;
            only_green = only_green and green(i);
            if (i >= 27) has_honors = true else suits[i / 9] = true;
        }
        if (only_honors) try self.match(ids, "tsuuiisou", "すべての牌が字牌です。", null);
        if (only_terminals) try self.match(ids, "chinroutou", "すべての牌が数牌の1または9です。", null);
        if (only_green) try self.match(ids, "ryuuiisou", "2・3・4・6・8索と發だけを使っています。", null);
        if (yakuman_only) return;
        if (simples) try self.match(ids, "tanyao", "1・9・字牌がなく、すべて2〜8です。", null);
        if (only_outside) try self.match(ids, "honroutou", "1・9・字牌だけで構成されています。", null);
        var suit_count: u8 = 0;
        for (suits) |used| if (used) {
            suit_count += 1;
        };
        if (suit_count == 1) try self.match(ids, if (has_honors) "honitsu" else "chinitsu", if (has_honors) "数牌は1種類だけで、字牌を含みます。" else "1種類の数牌だけで、字牌を含みません。", null);
    }
    fn save(self: *Engine, form: @FieldType(model.Pattern, "form"), groups: []const model.Group, ids: *std.ArrayList(model.Match)) !void {
        var yakuman_count: u8 = 0;
        var han: u16 = 0;
        for (ids.items) |y| if (y.is_yakuman) {
            yakuman_count += 1;
        };
        if (yakuman_count > 0) {
            var kept: usize = 0;
            for (ids.items) |y| if (y.is_yakuman) {
                ids.items[kept] = y;
                kept += 1;
            };
            ids.items.len = kept;
        } else {
            for (ids.items) |y| {
                han += y.han.?;
            }
        }
        // Identical role sets from symmetrical winning-tile assignments need one teaching example.
        for (self.patterns.items) |old| {
            if (old.form != form or old.yaku.len != ids.items.len) continue;
            var same = true;
            for (old.yaku, ids.items) |a, b| if (!std.mem.eql(u8, a.id, b.id) or a.han != b.han) {
                same = false;
            };
            if (same) return;
        }
        if (self.patterns.items.len >= 256) return error.DecompositionBudgetExceeded;
        try self.patterns.append(self.allocator, .{ .form = form, .groups = groups, .yaku = ids.items, .total_han = han, .yakuman_count = yakuman_count });
    }
    fn group(self: *Engine, part: Part, winning: bool) !model.Group {
        const count: usize = if (part.kind == .quad) 4 else 3;
        const tiles = try self.allocator.alloc(Tile, count);
        for (tiles, 0..) |*tile, i| tile.* = tileAt(part.base + (if (part.kind == .sequence) i else 0));
        return .{ .kind = switch (part.kind) {
            .sequence => .sequence,
            .triplet => .triplet,
            .quad => .quad,
        }, .tiles = tiles, .concealed = part.concealed and !(winning and part.kind != .sequence and self.req.win_method == .ron), .winning_group = winning };
    }
    fn standard(self: *Engine, pair: usize, winning_group: ?usize) !void {
        const r = self.req;
        var ids: std.ArrayList(model.Match) = .empty;
        try self.environment(&ids, false);
        try self.tileTraits(&ids, false);
        var sequences: [27]u8 = @splat(0);
        var triplets: [34]bool = @splat(false);
        var sequence_count: u8 = 0;
        var concealed_triplets: u8 = 0;
        var kans: u8 = 0;
        var all_groups_outside = outside(pair);
        var has_honors = pair >= 27;
        var has_kan = false;
        const groups = try self.allocator.alloc(model.Group, 5);
        for (self.parts, 0..) |part, i| {
            const winning = winning_group != null and winning_group.? == i;
            groups[i] = try self.group(part, winning);
            if (part.kind == .sequence) {
                sequences[part.base] += 1;
                sequence_count += 1;
                all_groups_outside = all_groups_outside and (part.base % 9 == 0 or part.base % 9 == 6);
            } else {
                triplets[part.base] = true;
                if (groups[i].concealed) concealed_triplets += 1;
                all_groups_outside = all_groups_outside and outside(part.base);
                has_honors = has_honors or part.base >= 27;
                if (part.kind == .quad) {
                    kans += 1;
                    has_kan = true;
                }
            }
        }
        const pair_tiles = try self.allocator.alloc(Tile, 2);
        @memset(pair_tiles, tileAt(pair));
        groups[4] = .{ .kind = .pair, .tiles = pair_tiles, .concealed = true, .winning_group = winning_group == null };
        var dragon_sets: u8 = 0;
        for (31..34) |i| if (triplets[i]) {
            dragon_sets += 1;
        };
        var wind_sets: u8 = 0;
        for (27..31) |i| if (triplets[i]) {
            wind_sets += 1;
        };
        if (dragon_sets == 3) try self.match(&ids, "daisangen", "白・發・中がすべて刻子または槓子です。", null);
        if (wind_sets == 4) try self.match(&ids, "daisuushii", "東・南・西・北がすべて刻子または槓子です。", null) else if (wind_sets == 3 and pair >= 27 and pair < 31) try self.match(&ids, "shousuushii", "風牌3種類が刻子または槓子、残り1種類が雀頭です。", null);
        if (concealed_triplets == 4) try self.match(&ids, "suuankou", "4面子すべてが暗刻または暗槓です。ロンの場合は雀頭を完成させています。", null);
        if (kans == 4) try self.match(&ids, "suukantsu", "4面子すべてが槓子です。", null);
        if (self.closed and !has_kan) {
            for (0..3) |suit| {
                const start = suit * 9;
                var nine_gates = self.all[start] >= 3 and self.all[start + 8] >= 3;
                for (start + 1..start + 8) |i| nine_gates = nine_gates and self.all[i] > 0;
                for (0..34) |i| if (i < start or i >= start + 9) {
                    nine_gates = nine_gates and self.all[i] == 0;
                };
                if (nine_gates) try self.match(&ids, "chuurenpoutou", "門前の1色で1112345678999に同色1枚を加えた形です。", null);
            }
        }
        var yakuhai_han: u8 = dragon_sets;
        const round: usize = 27 + @as(usize, @backingInt(r.round_wind));
        const seat: usize = 27 + @as(usize, @backingInt(r.seat_wind));
        if (triplets[round]) yakuhai_han += 1;
        if (triplets[seat]) yakuhai_han += 1;
        if (yakuhai_han > 0) try self.match(&ids, "yakuhai", "三元牌・場風・自風の刻子または槓子です。各1翻、連風牌は2翻として合計しています。", yakuhai_han);
        if (dragon_sets == 2 and pair >= 31) try self.match(&ids, "shousangen", "三元牌の2種類が刻子または槓子、残りが雀頭です。役牌も複合します。", null);
        if (sequence_count == 0) try self.match(&ids, "toitoi", "4面子すべてが刻子または槓子です。", null);
        if (concealed_triplets >= 3) try self.match(&ids, "sanankou", "暗刻または暗槓が3組以上。ロンで完成した刻子は暗刻に含めていません。", null);
        if (kans >= 3) try self.match(&ids, "sankantsu", "槓子が3組以上あります。", null);
        if (all_groups_outside and sequence_count > 0) try self.match(&ids, if (has_honors) "chanta" else "junchan", "すべての面子と雀頭に1・9または字牌があり、順子を含みます。字牌の有無で混全帯／純全帯を区別します。", null);
        if (self.closed) {
            var pairs_of_sequences: u8 = 0;
            for (sequences) |count| pairs_of_sequences += count / 2;
            if (pairs_of_sequences >= 2) try self.match(&ids, "ryanpeikou", "同じ順子2組の組み合わせが2つあります。一盃口・七対子とは重複しません。", null) else if (pairs_of_sequences == 1) try self.match(&ids, "iipeikou", "門前で同じ数字・種類の順子が2組あります。", null);
            if (sequence_count == 4 and pair < 31 and pair != round and pair != seat and winning_group != null) {
                const part = self.parts[winning_group.?];
                const w = r.winning_tile.index();
                const middle = w == part.base + 1;
                const edge = (part.base % 9 == 0 and w == part.base + 2) or (part.base % 9 == 6 and w == part.base);
                if (!middle and !edge) try self.match(&ids, "pinfu", "門前4順子、役牌ではない雀頭、指定和了牌が両面待ちの端を完成させています。", null);
            }
        }
        for (0..7) |start| if (sequences[start] > 0 and sequences[start + 9] > 0 and sequences[start + 18] > 0) {
            try self.match(&ids, "sanshoku_doujun", "同じ数字の順子が萬子・筒子・索子に1組ずつあります。", null);
            break;
        };
        for (0..9) |value| if (triplets[value] and triplets[value + 9] and triplets[value + 18]) {
            try self.match(&ids, "sanshoku_doukou", "同じ数字の刻子または槓子が3色にあります。", null);
            break;
        };
        for (0..3) |suit| if (sequences[suit * 9] > 0 and sequences[suit * 9 + 3] > 0 and sequences[suit * 9 + 6] > 0) {
            try self.match(&ids, "ittsuu", "同じ種類の数牌で123・456・789の3順子がそろっています。", null);
            break;
        };
        try self.save(.standard, groups, &ids);
    }
    fn specialForms(self: *Engine) !void {
        if (self.req.melds.len != 0) return;
        var pairs: usize = 0;
        var seven = true;
        var kokushi = true;
        var orphan_pairs: usize = 0;
        for (self.all, 0..) |count, i| {
            if (count == 2) pairs += 1;
            if (count != 0 and count != 2) seven = false;
            if (outside(i)) {
                if (count != 1 and count != 2) kokushi = false;
                if (count == 2) orphan_pairs += 1;
            } else if (count != 0) kokushi = false;
        }
        if (seven and pairs == 7) {
            var ids: std.ArrayList(model.Match) = .empty;
            try self.environment(&ids, false);
            try self.tileTraits(&ids, false);
            try self.match(&ids, "chiitoitsu", "異なる7種類の対子です。同じ牌4枚は2対子に数えません。", null);
            const groups = try self.allocator.alloc(model.Group, 7);
            var j: usize = 0;
            for (self.all, 0..) |count, i| if (count == 2) {
                const tiles = try self.allocator.alloc(Tile, 2);
                @memset(tiles, tileAt(i));
                groups[j] = .{ .kind = .pair, .tiles = tiles, .concealed = true, .winning_group = i == self.req.winning_tile.index() };
                j += 1;
            };
            try self.save(.seven_pairs, groups, &ids);
        }
        if (kokushi and orphan_pairs == 1) {
            var ids: std.ArrayList(model.Match) = .empty;
            try self.environment(&ids, true);
            try self.match(&ids, "kokushi_musou", "13種類すべての1・9・字牌と、そのうち1種類の対子です。", null);
            const groups = try self.allocator.alloc(model.Group, 13);
            var j: usize = 0;
            for (self.all, 0..) |count, i| if (count > 0) {
                const tiles = try self.allocator.alloc(Tile, count);
                @memset(tiles, tileAt(i));
                groups[j] = .{ .kind = if (count == 2) .pair else .orphan, .tiles = tiles, .concealed = true, .winning_group = i == self.req.winning_tile.index() };
                j += 1;
            };
            try self.save(.thirteen_orphans, groups, &ids);
        }
    }
};
