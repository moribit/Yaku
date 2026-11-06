//! All reviewed-at-source teaching fixtures live here. Structural validation is not a rules oracle.
const std = @import("std");
const tiles = @import("../mahjong/tile.zig").tiles;
const parse = @import("../mahjong/tile.zig").parse;
const catalog = @import("../mahjong/yaku_catalog.zig");
const Question = @import("question.zig").Question;
const Difficulty = @import("question.zig").Difficulty;
pub const all = [_]Question{
    // b-01: riichi
    .{ .id = "b-01", .difficulty = .beginner, .hand = tiles("1m 2m 3m 4p 5p 6p 7s 8s 9s 5m 5m 5m east east"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = true, .win_method = .ron, .winning_tile = parse("5m") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"riichi"}, .correct_yaku = &.{"riichi"}, .distractors = &.{ "menzen_tsumo", "pinfu", "tanyao", "iipeikou" }, .decomposition = "123m / 456p / 789s / 555m / 東東。5mのロンで刻子を完成。", .explanation = "立直宣言がある門前手なので立直。5萬の刻子があるため平和ではなく、1・9・東を含むため断么九でもありません。" },
    // b-02: menzen_tsumo
    .{ .id = "b-02", .difficulty = .beginner, .hand = tiles("1m 2m 3m 4p 5p 6p 7s 8s 9s 5m 5m 5m east east"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .tsumo, .winning_tile = parse("5m") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"menzen_tsumo"}, .correct_yaku = &.{"menzen_tsumo"}, .distractors = &.{ "pinfu", "tanyao", "riichi", "iipeikou" }, .decomposition = "123m / 456p / 789s / 555m / 東東。5mをツモ。", .explanation = "副露せず自分で和了牌を引いたので門前清自摸和。立直宣言がないので立直は成立しません。" },
    // b-03: tanyao
    .{ .id = "b-03", .difficulty = .beginner, .hand = tiles("3p 4p 5p 4s 5s 6s 6m 6m 6m 8p 8p"), .open_melds = &.{.{ .kind = .chi, .tiles = tiles("2m 3m 4m") }}, .context = .{ .closed = false, .riichi = false, .win_method = .ron, .winning_tile = parse("6m") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"tanyao"}, .correct_yaku = &.{"tanyao"}, .distractors = &.{ "menzen_tsumo", "pinfu", "riichi", "iipeikou" }, .decomposition = "234m（チー） / 345p / 456s / 666m / 88p。6mをロン。", .explanation = "副露していても、全牌が2〜8なので断么九（喰いタン）。6萬の刻子があるので平和の形ではありません。" },
    // b-04: pinfu
    .{ .id = "b-04", .difficulty = .beginner, .hand = tiles("1m 2m 3m 4m 5m 6m 7p 8p 9p 2s 3s 4s 5p 5p"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .ron, .winning_tile = parse("4s") catch unreachable, .wait = .ryanmen }, .primary_yaku = &.{"pinfu"}, .correct_yaku = &.{"pinfu"}, .distractors = &.{ "menzen_tsumo", "tanyao", "riichi", "iipeikou" }, .decomposition = "123m / 456m / 789p / 234s / 55p。23sから4sロン（両面）。", .explanation = "門前の4順子、5筒の雀頭、23索からの両面待ちなので平和。1・9があるため断么九は成立しません。" },
    // b-05: iipeikou
    .{ .id = "b-05", .difficulty = .beginner, .hand = tiles("1m 2m 3m 1m 2m 3m 4p 5p 6p 7s 7s 7s east east"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .ron, .winning_tile = parse("7s") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"iipeikou"}, .correct_yaku = &.{"iipeikou"}, .distractors = &.{ "menzen_tsumo", "pinfu", "tanyao", "riichi" }, .decomposition = "123m / 123m / 456p / 777s / 東東。7sをロン。", .explanation = "門前で123萬を2組作っているので一盃口。7索の刻子があるため平和ではありません。東は雀頭なので役牌にはなりません。" },
    // b-06: yakuhai
    .{ .id = "b-06", .difficulty = .beginner, .hand = tiles("1m 2m 3m 4p 5p 6p 7s 8s 9s 5m 5m"), .open_melds = &.{.{ .kind = .pon, .tiles = tiles("white white white") }}, .context = .{ .closed = false, .riichi = false, .win_method = .ron, .winning_tile = parse("9s") catch unreachable, .wait = .ryanmen }, .primary_yaku = &.{"yakuhai"}, .correct_yaku = &.{"yakuhai"}, .distractors = &.{ "menzen_tsumo", "pinfu", "tanyao", "riichi" }, .decomposition = "白白白（ポン） / 123m / 456p / 789s / 55m。78sから9sロン（両面）。", .explanation = "白の刻子が役牌です。副露しているので平和や門前清自摸和は成立しません。" },
    // b-07: chiitoitsu
    .{ .id = "b-07", .difficulty = .beginner, .hand = tiles("1m 1m 3m 3m 5p 5p 7p 7p 2s 2s 8s 8s east east"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .ron, .winning_tile = parse("east") catch unreachable, .wait = .tanki }, .primary_yaku = &.{"chiitoitsu"}, .correct_yaku = &.{"chiitoitsu"}, .distractors = &.{ "menzen_tsumo", "pinfu", "tanyao", "riichi" }, .decomposition = "11m / 33m / 55p / 77p / 22s / 88s / 東東。東単騎ロン。", .explanation = "異なる7種類の対子なので七対子。1萬と東を含むため断么九ではありません。" },
    // b-08: toitoi
    .{ .id = "b-08", .difficulty = .beginner, .hand = tiles("4p 4p 4p 6s 6s 6s 9m 9m 9m 5p 5p"), .open_melds = &.{.{ .kind = .pon, .tiles = tiles("2m 2m 2m") }}, .context = .{ .closed = false, .riichi = false, .win_method = .ron, .winning_tile = parse("9m") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"toitoi"}, .correct_yaku = &.{"toitoi"}, .distractors = &.{ "menzen_tsumo", "pinfu", "tanyao", "riichi" }, .decomposition = "222m（ポン） / 444p / 666s / 999m / 55p。9mをロン、暗刻は444pと666s。", .explanation = "4面子がすべて刻子なので対々和。ロンで完成した9萬の刻子は暗刻に数えず、暗刻は4筒・6索の2組なので三暗刻はありません。" },
    // b-09: riichi + pinfu
    .{ .id = "b-09", .difficulty = .beginner, .hand = tiles("1p 2p 3p 4p 5p 6p 7s 8s 9s 2m 3m 4m 5s 5s"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = true, .win_method = .ron, .winning_tile = parse("4m") catch unreachable, .wait = .ryanmen }, .primary_yaku = &.{ "riichi", "pinfu" }, .correct_yaku = &.{ "riichi", "pinfu" }, .distractors = &.{ "menzen_tsumo", "tanyao", "iipeikou" }, .decomposition = "123p / 456p / 789s / 234m / 55s。23mから4mロン（両面）。", .explanation = "立直宣言に加え、4順子・5索の雀頭・23萬の両面待ちで平和も成立します。立直だけを選ぶと不足です。" },
    // b-10: tanyao + pinfu
    .{ .id = "b-10", .difficulty = .beginner, .hand = tiles("2m 3m 4m 4m 5m 6m 3p 4p 5p 6s 7s 8s 2p 2p"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .ron, .winning_tile = parse("8s") catch unreachable, .wait = .ryanmen }, .primary_yaku = &.{ "tanyao", "pinfu" }, .correct_yaku = &.{ "tanyao", "pinfu" }, .distractors = &.{ "menzen_tsumo", "riichi", "iipeikou" }, .decomposition = "234m / 456m / 345p / 678s / 22p。67sから8sロン（両面）。", .explanation = "全牌が2〜8なので断么九。門前の4順子、2筒の雀頭、67索の両面待ちなので平和も成立します。" },
    // b-11: chiitoitsu + tanyao
    .{ .id = "b-11", .difficulty = .beginner, .hand = tiles("2m 2m 4m 4m 6m 6m 3p 3p 5p 5p 7s 7s 8s 8s"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .ron, .winning_tile = parse("8s") catch unreachable, .wait = .tanki }, .primary_yaku = &.{"chiitoitsu"}, .correct_yaku = &.{ "chiitoitsu", "tanyao" }, .distractors = &.{ "menzen_tsumo", "pinfu", "riichi" }, .decomposition = "22m / 44m / 66m / 33p / 55p / 77s / 88s。8s単騎ロン。", .explanation = "異なる7対子で七対子。さらに全牌が2〜8なので断么九も成立します。" },
    // b-12: riichi + tanyao
    .{ .id = "b-12", .difficulty = .beginner, .hand = tiles("2m 3m 4m 3p 4p 5p 6s 7s 8s 6p 6p 6p 8m 8m"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = true, .win_method = .ron, .winning_tile = parse("6p") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"riichi"}, .correct_yaku = &.{ "riichi", "tanyao" }, .distractors = &.{ "menzen_tsumo", "pinfu", "iipeikou" }, .decomposition = "234m / 345p / 678s / 666p / 88m。6pをロン。", .explanation = "立直宣言があり、全牌が2〜8なので立直と断么九。6筒の刻子があるので平和ではありません。" },
    // b-13: menzen_tsumo + tanyao
    .{ .id = "b-13", .difficulty = .beginner, .hand = tiles("2p 3p 4p 3s 4s 5s 6m 7m 8m 6s 6s 6s 8p 8p"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .tsumo, .winning_tile = parse("6s") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"menzen_tsumo"}, .correct_yaku = &.{ "menzen_tsumo", "tanyao" }, .distractors = &.{ "pinfu", "riichi", "iipeikou" }, .decomposition = "234p / 345s / 678m / 666s / 88p。6sをツモ。", .explanation = "門前ツモで門前清自摸和、全牌が2〜8で断么九。刻子があるため平和ではありません。" },
    // b-14: yakuhai
    .{ .id = "b-14", .difficulty = .beginner, .hand = tiles("1m 2m 3m 4p 5p 6p 7s 8s 9s 5m 5m"), .open_melds = &.{.{ .kind = .pon, .tiles = tiles("south south south") }}, .context = .{ .closed = false, .riichi = false, .win_method = .ron, .winning_tile = parse("9s") catch unreachable, .wait = .ryanmen }, .primary_yaku = &.{"yakuhai"}, .correct_yaku = &.{"yakuhai"}, .distractors = &.{ "menzen_tsumo", "pinfu", "tanyao", "riichi" }, .decomposition = "南南南（ポン） / 123m / 456p / 789s / 55m。78sから9sロン（両面）。", .explanation = "自風は南なので、南の刻子が役牌です。場風は東であり、この南の刻子は自風の1翻です。" },
    // b-15: toitoi + yakuhai
    .{ .id = "b-15", .difficulty = .beginner, .hand = tiles("4p 4p 4p 6s 6s 6s 5p 5p"), .open_melds = &.{ .{ .kind = .pon, .tiles = tiles("red red red") }, .{ .kind = .pon, .tiles = tiles("2m 2m 2m") } }, .context = .{ .closed = false, .riichi = false, .win_method = .ron, .winning_tile = parse("6s") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"toitoi"}, .correct_yaku = &.{ "toitoi", "yakuhai" }, .distractors = &.{ "menzen_tsumo", "pinfu", "tanyao" }, .decomposition = "中中中（ポン） / 222m（ポン） / 444p / 666s / 55p。6sをロン。", .explanation = "すべての面子が刻子なので対々和。中の刻子による役牌も成立します。副露2組なので三暗刻ではありません。" },
    // i-01: sanshoku_doujun + tanyao + pinfu
    .{ .id = "i-01", .difficulty = .intermediate, .hand = tiles("2m 3m 4m 2p 3p 4p 2s 3s 4s 6m 7m 8m 5p 5p"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .ron, .winning_tile = parse("8m") catch unreachable, .wait = .ryanmen }, .primary_yaku = &.{"sanshoku_doujun"}, .correct_yaku = &.{ "sanshoku_doujun", "tanyao", "pinfu" }, .distractors = &.{ "sanankou", "toitoi" }, .decomposition = "234m / 234p / 234s / 678m / 55p。67mから8mロン（両面）。", .explanation = "234の順子が3色にあるので三色同順。全牌2〜8で断么九、門前の4順子と両面待ちで平和も成立します。" },
    // i-02: sanshoku_doujun + tanyao
    .{ .id = "i-02", .difficulty = .intermediate, .hand = tiles("2p 3p 4p 2s 3s 4s 6m 7m 8m 5p 5p"), .open_melds = &.{.{ .kind = .chi, .tiles = tiles("2m 3m 4m") }}, .context = .{ .closed = false, .riichi = false, .win_method = .ron, .winning_tile = parse("8m") catch unreachable, .wait = .ryanmen }, .primary_yaku = &.{"sanshoku_doujun"}, .correct_yaku = &.{ "sanshoku_doujun", "tanyao" }, .distractors = &.{ "pinfu", "sanankou", "toitoi" }, .decomposition = "234m（チー） / 234p / 234s / 678m / 55p。67mから8mロン。", .explanation = "副露した234萬と234筒・234索で三色同順（1翻）。全牌2〜8で断么九。副露しているので平和は成立しません。" },
    // i-03: ittsuu
    .{ .id = "i-03", .difficulty = .intermediate, .hand = tiles("1m 2m 3m 4m 5m 6m 7m 8m 9m 2p 2p 2p south south"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .ron, .winning_tile = parse("2p") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"ittsuu"}, .correct_yaku = &.{"ittsuu"}, .distractors = &.{ "pinfu", "sanankou", "toitoi", "sanshoku_doujun" }, .decomposition = "123m / 456m / 789m / 222p / 南南。2pをロン。", .explanation = "萬子に123・456・789の順子がそろい、一気通貫。2筒の刻子があるため平和ではなく、2種類の数牌があるため混一色でもありません。" },
    // i-04: ittsuu
    .{ .id = "i-04", .difficulty = .intermediate, .hand = tiles("4m 5m 6m 7m 8m 9m 2p 2p 2p south south"), .open_melds = &.{.{ .kind = .chi, .tiles = tiles("1m 2m 3m") }}, .context = .{ .closed = false, .riichi = false, .win_method = .ron, .winning_tile = parse("2p") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"ittsuu"}, .correct_yaku = &.{"ittsuu"}, .distractors = &.{ "pinfu", "sanankou", "toitoi", "sanshoku_doujun" }, .decomposition = "123m（チー） / 456m / 789m / 222p / 南南。2pをロン。", .explanation = "副露していても萬子の123・456・789で一気通貫（1翻）。南は対子であり、役牌の刻子ではありません。" },
    // i-05: chanta
    .{ .id = "i-05", .difficulty = .intermediate, .hand = tiles("1m 2m 3m 7p 8p 9p 1s 1s 1s west west west north north"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .ron, .winning_tile = parse("1s") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"chanta"}, .correct_yaku = &.{"chanta"}, .distractors = &.{ "pinfu", "sanankou", "toitoi", "sanshoku_doujun" }, .decomposition = "123m / 789p / 111s / 西西西 / 北北。1sをロン。西・北は客風。", .explanation = "123萬・789筒・111索・西刻子・北雀頭の各組に1・9・字牌があり、順子と字牌を含むので混全帯么九。西は場風でも自風でもないため役牌ではありません。" },
    // i-06: junchan
    .{ .id = "i-06", .difficulty = .intermediate, .hand = tiles("1m 2m 3m 7p 8p 9p 1s 1s 1s 9m 9m 9m 9s 9s"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .ron, .winning_tile = parse("1s") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"junchan"}, .correct_yaku = &.{"junchan"}, .distractors = &.{ "pinfu", "sanankou", "toitoi", "sanshoku_doujun" }, .decomposition = "123m / 789p / 111s / 999m / 99s。1sをロン。", .explanation = "各組に1か9があり、字牌がなく順子も含むので純全帯么九。混全帯么九は重複して数えません。" },
    // i-07: sanshoku_doukou
    .{ .id = "i-07", .difficulty = .intermediate, .hand = tiles("5p 5p 5p 5s 5s 5s 1m 2m 3m east east"), .open_melds = &.{.{ .kind = .pon, .tiles = tiles("5m 5m 5m") }}, .context = .{ .closed = false, .riichi = false, .win_method = .ron, .winning_tile = parse("3m") catch unreachable, .wait = .penchan }, .primary_yaku = &.{"sanshoku_doukou"}, .correct_yaku = &.{"sanshoku_doukou"}, .distractors = &.{ "pinfu", "sanankou", "toitoi", "sanshoku_doujun" }, .decomposition = "555m（ポン） / 555p / 555s / 123m / 東東。12mから3mロン（辺張）。", .explanation = "5萬・5筒・5索の刻子で三色同刻。123萬の順子があるので対々和ではありません。暗刻は2組なので三暗刻でもありません。" },
    // i-08: sanankou
    .{ .id = "i-08", .difficulty = .intermediate, .hand = tiles("2m 2m 2m 4p 4p 4p 6s 6s 6s 7m 8m 9m 5p 5p"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .ron, .winning_tile = parse("9m") catch unreachable, .wait = .ryanmen }, .primary_yaku = &.{"sanankou"}, .correct_yaku = &.{"sanankou"}, .distractors = &.{ "pinfu", "toitoi", "sanshoku_doujun", "ittsuu" }, .decomposition = "222m / 444p / 666s / 789m / 55p。78mから9mロン（両面）。3刻子は和了前から暗刻。", .explanation = "2萬・4筒・6索の刻子はすべて和了前から手の中にあり三暗刻。ロンは789萬の順子を完成させるので、暗刻の数に影響しません。" },
    // i-09: shousangen + yakuhai
    .{ .id = "i-09", .difficulty = .intermediate, .hand = tiles("red red 1m 2m 3m 4p 5p 6p"), .open_melds = &.{ .{ .kind = .pon, .tiles = tiles("white white white") }, .{ .kind = .pon, .tiles = tiles("green green green") } }, .context = .{ .closed = false, .riichi = false, .win_method = .ron, .winning_tile = parse("6p") catch unreachable, .wait = .ryanmen }, .primary_yaku = &.{"shousangen"}, .correct_yaku = &.{ "shousangen", "yakuhai" }, .distractors = &.{ "pinfu", "sanankou", "toitoi" }, .decomposition = "白白白（ポン） / 發發發（ポン） / 123m / 456p / 中中。45pから6pロン。", .explanation = "白と發が刻子、中が雀頭なので小三元。白と發それぞれの役牌も成立します。選択肢では役牌を1項目にまとめています。" },
    // i-10: honitsu + yakuhai
    .{ .id = "i-10", .difficulty = .intermediate, .hand = tiles("1m 2m 3m 4m 5m 6m 7m 7m 7m east east"), .open_melds = &.{.{ .kind = .pon, .tiles = tiles("white white white") }}, .context = .{ .closed = false, .riichi = false, .win_method = .ron, .winning_tile = parse("7m") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"honitsu"}, .correct_yaku = &.{ "honitsu", "yakuhai" }, .distractors = &.{ "pinfu", "sanankou", "toitoi" }, .decomposition = "白白白（ポン） / 123m / 456m / 777m / 東東。7mをロン。", .explanation = "萬子と字牌だけなので混一色（副露2翻）。白の刻子による役牌も成立します。字牌があるので清一色ではありません。" },
    // a-01: riichi + menzen_tsumo + tanyao + pinfu + sanshoku_doujun
    .{ .id = "a-01", .difficulty = .advanced, .hand = tiles("2m 3m 4m 2p 3p 4p 2s 3s 4s 6m 7m 8m 5p 5p"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = true, .win_method = .tsumo, .winning_tile = parse("8m") catch unreachable, .wait = .ryanmen }, .primary_yaku = &.{"sanshoku_doujun"}, .correct_yaku = &.{ "riichi", "menzen_tsumo", "tanyao", "pinfu", "sanshoku_doujun" }, .distractors = &.{"sanankou"}, .decomposition = "234m / 234p / 234s / 678m / 55p。67mから8mツモ（両面）。通常の立直。", .explanation = "234が3色で三色同順。全牌2〜8の断么九、門前4順子・非役牌雀頭・両面待ちの平和、立直宣言、門前ツモも成立。5役すべて選びます。" },
    // a-02: riichi + menzen_tsumo + pinfu + ittsuu
    .{ .id = "a-02", .difficulty = .advanced, .hand = tiles("1m 2m 3m 4m 5m 6m 7m 8m 9m 2p 3p 4p 5s 5s"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = true, .win_method = .tsumo, .winning_tile = parse("4p") catch unreachable, .wait = .ryanmen }, .primary_yaku = &.{"ittsuu"}, .correct_yaku = &.{ "riichi", "menzen_tsumo", "pinfu", "ittsuu" }, .distractors = &.{"sanankou"}, .decomposition = "123m / 456m / 789m / 234p / 55s。23pから4pツモ（両面）。", .explanation = "萬子の123・456・789で一気通貫。門前4順子、5索雀頭、23筒両面待ちで平和。立直と門前清自摸和も成立します。" },
    // a-03: riichi + menzen_tsumo + pinfu + iipeikou
    .{ .id = "a-03", .difficulty = .advanced, .hand = tiles("1m 2m 3m 1m 2m 3m 4p 5p 6p 7s 8s 9s 5p 5p"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = true, .win_method = .tsumo, .winning_tile = parse("6p") catch unreachable, .wait = .ryanmen }, .primary_yaku = &.{"iipeikou"}, .correct_yaku = &.{ "riichi", "menzen_tsumo", "pinfu", "iipeikou" }, .distractors = &.{"sanankou"}, .decomposition = "123m / 123m / 456p / 789s / 55p。45pから6pツモ（両面）。", .explanation = "123萬2組で一盃口。門前の4順子・5筒雀頭・45筒両面待ちで平和。立直と門前ツモも成立。1・9があるので断么九はありません。" },
    // a-04: riichi + menzen_tsumo + chiitoitsu + tanyao
    .{ .id = "a-04", .difficulty = .advanced, .hand = tiles("2m 2m 4m 4m 6m 6m 3p 3p 5p 5p 7s 7s 8s 8s"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = true, .win_method = .tsumo, .winning_tile = parse("8s") catch unreachable, .wait = .tanki }, .primary_yaku = &.{"chiitoitsu"}, .correct_yaku = &.{ "riichi", "menzen_tsumo", "chiitoitsu", "tanyao" }, .distractors = &.{"pinfu"}, .decomposition = "22m / 44m / 66m / 33p / 55p / 77s / 88s。8s単騎ツモ。", .explanation = "異なる7対子で七対子、全牌2〜8で断么九。立直と門前清自摸和も成立。七対子は平和や一盃口と複合しません。" },
    // a-05: toitoi + sanankou
    .{ .id = "a-05", .difficulty = .advanced, .hand = tiles("4p 4p 4p 6s 6s 6s 9m 9m 9m 5p 5p"), .open_melds = &.{.{ .kind = .pon, .tiles = tiles("2m 2m 2m") }}, .context = .{ .closed = false, .riichi = false, .win_method = .tsumo, .winning_tile = parse("9m") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"sanankou"}, .correct_yaku = &.{ "toitoi", "sanankou" }, .distractors = &.{ "pinfu", "sanshoku_doujun", "ittsuu" }, .decomposition = "222m（ポン） / 444p / 666s / 999m / 55p。9mツモで3つ目の暗刻を完成。", .explanation = "副露があるため門前清自摸和は成立しません。4面子が刻子で対々和。9萬をツモして完成した刻子も暗刻に数え、4筒・6索と合わせ三暗刻です。" },
    // a-06: tanyao + toitoi + sanankou + sanshoku_doukou
    .{ .id = "a-06", .difficulty = .advanced, .hand = tiles("5p 5p 5p 5s 5s 5s 2m 2m 2m 8p 8p"), .open_melds = &.{.{ .kind = .pon, .tiles = tiles("5m 5m 5m") }}, .context = .{ .closed = false, .riichi = false, .win_method = .tsumo, .winning_tile = parse("2m") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{ "sanshoku_doukou", "sanankou" }, .correct_yaku = &.{ "tanyao", "toitoi", "sanankou", "sanshoku_doukou" }, .distractors = &.{"pinfu"}, .decomposition = "555m（ポン） / 555p / 555s / 222m / 88p。2mツモで3つ目の暗刻を完成。", .explanation = "5の刻子が3色で三色同刻。5筒・5索・ツモ完成の2萬が暗刻で三暗刻。全牌2〜8で断么九、全刻子で対々和。副露しているので門前清自摸和はありません。" },
    // a-07: honitsu + shousangen + yakuhai
    .{ .id = "a-07", .difficulty = .advanced, .hand = tiles("1m 2m 3m 7m 7m 7m red red"), .open_melds = &.{ .{ .kind = .pon, .tiles = tiles("white white white") }, .{ .kind = .pon, .tiles = tiles("green green green") } }, .context = .{ .closed = false, .riichi = false, .win_method = .ron, .winning_tile = parse("3m") catch unreachable, .wait = .penchan }, .primary_yaku = &.{"shousangen"}, .correct_yaku = &.{ "honitsu", "shousangen", "yakuhai" }, .distractors = &.{ "pinfu", "sanankou" }, .decomposition = "白白白（ポン） / 發發發（ポン） / 123m / 777m / 中中。12mから3mロン（辺張）。", .explanation = "白・發の刻子と中の雀頭で小三元、2組の役牌も成立。萬子と字牌だけなので混一色。萬子は123と777であり一気通貫はありません。" },
    // a-08: chinitsu + ittsuu
    .{ .id = "a-08", .difficulty = .advanced, .hand = tiles("1p 2p 3p 4p 5p 6p 7p 8p 9p 2p 2p 2p 5p 5p"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .ron, .winning_tile = parse("2p") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{"chinitsu"}, .correct_yaku = &.{ "chinitsu", "ittsuu" }, .distractors = &.{ "pinfu", "sanankou", "toitoi" }, .decomposition = "123p / 456p / 789p / 222p / 55p。2pをロン。", .explanation = "筒子だけで清一色。123・456・789の組み合わせで一気通貫も成立。222筒の刻子があるため平和ではありません。" },
    // a-09: chanta + sanshoku_doujun
    .{ .id = "a-09", .difficulty = .advanced, .hand = tiles("1m 2m 3m 1p 2p 3p 1s 2s 3s west west west north north"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .ron, .winning_tile = parse("west") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{ "chanta", "sanshoku_doujun" }, .correct_yaku = &.{ "chanta", "sanshoku_doujun" }, .distractors = &.{ "pinfu", "sanankou", "toitoi" }, .decomposition = "123m / 123p / 123s / 西西西 / 北北。西をロン。西・北は客風。", .explanation = "123が3色で三色同順。各面子と雀頭に1か字牌があり、順子と字牌を含むので混全帯么九。西は客風のため役牌ではありません。" },
    // a-10: junchan + sanshoku_doujun
    .{ .id = "a-10", .difficulty = .advanced, .hand = tiles("1m 2m 3m 1p 2p 3p 1s 2s 3s 9m 9m 9m 9s 9s"), .open_melds = &.{}, .context = .{ .closed = true, .riichi = false, .win_method = .ron, .winning_tile = parse("9m") catch unreachable, .wait = .shanpon }, .primary_yaku = &.{ "junchan", "sanshoku_doujun" }, .correct_yaku = &.{ "junchan", "sanshoku_doujun" }, .distractors = &.{ "pinfu", "sanankou", "toitoi" }, .decomposition = "123m / 123p / 123s / 999m / 99s。9mをロン。", .explanation = "123が3色で三色同順。各組に1か9があり、字牌なしで純全帯么九。混全帯么九は重複しません。" },
};
pub fn find(id: []const u8) ?Question {
    for (all) |question| if (std.mem.eql(u8, id, question.id)) return question;
    return null;
}
pub fn contains(ids: []const []const u8, id: []const u8) bool {
    for (ids) |item| if (std.mem.eql(u8, item, id)) return true;
    return false;
}
pub fn validate(bank: []const Question) !void {
    for (bank, 0..) |q, i| {
        for (bank[0..i]) |other| if (std.mem.eql(u8, q.id, other.id)) return error.DuplicateQuestion;
        var counts: [34]u8 = @splat(0);
        var total = q.hand.len;
        var winning_present = false;
        for (q.hand) |tile| {
            if (!tile.validate()) return error.InvalidTile;
            counts[tile.index()] += 1;
            if (std.meta.eql(tile, q.context.winning_tile)) winning_present = true;
        }
        for (q.open_melds) |meld| {
            if (!meld.validate()) return error.InvalidMeld;
            total += meld.equivalentCount();
            for (meld.tiles) |tile| counts[tile.index()] += 1;
        }
        if (total != 14) return error.InvalidTileCount;
        for (counts) |count| if (count > 4) return error.FiveCopies;
        if (!winning_present) return error.MissingWinningTile;
        if (q.context.closed != (q.open_melds.len == 0)) return error.InvalidClosedContext;
        if (q.context.riichi and !q.context.closed) return error.OpenRiichi;
        const choices = q.correct_yaku.len + q.distractors.len;
        if (choices < 4 or choices > 6 or q.correct_yaku.len == 0) return error.InvalidChoices;
        for (q.primary_yaku) |id| if (!contains(q.correct_yaku, id)) return error.InvalidPrimary;
        for ([_][]const []const u8{ q.correct_yaku, q.primary_yaku, q.distractors }) |ids| {
            for (ids, 0..) |id, j| {
                if (catalog.find(id) == null) return error.UnknownYaku;
                if (contains(ids[0..j], id)) return error.DuplicateYaku;
            }
        }
        for (q.distractors) |id| if (contains(q.correct_yaku, id)) return error.OverlappingChoices;
    }
}
test "all 35 bank fixtures validate and difficulty quotas hold" {
    try validate(&all);
    var quotas: [3]usize = @splat(0);
    for (all) |q| quotas[@backingInt(q.difficulty)] += 1;
    try std.testing.expect(quotas[0] >= 15 and quotas[1] >= 10 and quotas[2] >= 5);
}
test "validator rejects broken fixtures including meld totals and five physical copies" {
    var q = all[0];
    q.hand = tiles("1m");
    try std.testing.expectError(error.InvalidTileCount, validate(&.{q}));
    q = all[0];
    q.hand = tiles("1m 1m 1m 1m 1m 2m 3m 4p 5p 6p 7s 8s 9s east");
    try std.testing.expectError(error.FiveCopies, validate(&.{q}));
    q = all[0];
    q.correct_yaku = &.{"unknown"};
    q.primary_yaku = &.{"unknown"};
    try std.testing.expectError(error.UnknownYaku, validate(&.{q}));
    q = all[0];
    q.distractors = &.{ "riichi", "tanyao", "pinfu" };
    try std.testing.expectError(error.OverlappingChoices, validate(&.{q}));
    try std.testing.expectError(error.DuplicateQuestion, validate(&.{ all[0], all[0] }));
    q = all[2];
    q.open_melds = &.{};
    try std.testing.expectError(error.InvalidTileCount, validate(&.{q}));
    // A kan counts as one three-tile meld, but all four copies count physically.
    q = all[2];
    q.open_melds = &.{.{ .kind = .kan, .tiles = tiles("2m 2m 2m 2m") }};
    try validate(&.{q});
    q.hand = tiles("2m 4p 5p 4s 5s 6s 6m 6m 6m 8p 8p");
    try std.testing.expectError(error.FiveCopies, validate(&.{q}));
}
