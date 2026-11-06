const std = @import("std");
pub const Term = struct {
    id: []const u8,
    name_ja: []const u8,
    reading: []const u8,
    category: enum { basics, hand, context, winning, rules },
    definition: []const u8,
    example: []const u8,
    aliases: []const []const u8,
    related: []const []const u8,
};
pub const all = [_]Term{
    .{ .id = "hai", .name_ja = "牌", .reading = "ハイ", .category = .basics, .definition = "麻雀で使う駒。萬子・筒子・索子の数牌と、風牌・三元牌の字牌があります。", .example = "1mは一萬、whiteは白を表します。", .aliases = &.{"mahjong_tile"}, .related = &.{ "number_tile", "honor_tile" } },
    .{ .id = "number_tile", .name_ja = "数牌", .reading = "シュウパイ", .category = .basics, .definition = "萬子・筒子・索子それぞれの1〜9。合計27種類あります。", .example = "2萬・5筒・8索は数牌です。", .aliases = &.{}, .related = &.{ "terminal_tile", "simple_tile" } },
    .{ .id = "honor_tile", .name_ja = "字牌", .reading = "ジハイ", .category = .basics, .definition = "東・南・西・北・白・發・中の7種類。数字ではない牌です。", .example = "東は風牌、白は三元牌です。", .aliases = &.{}, .related = &.{ "wind_tile", "dragon_tile" } },
    .{ .id = "man", .name_ja = "萬子", .reading = "マンズ", .category = .basics, .definition = "一萬〜九萬の数牌。表記mを使います。", .example = "3mは三萬。", .aliases = &.{}, .related = &.{ "number_tile", "pin", "sou" } },
    .{ .id = "pin", .name_ja = "筒子", .reading = "ピンズ", .category = .basics, .definition = "丸い模様の数牌。表記pを使います。", .example = "3pは三筒。", .aliases = &.{}, .related = &.{ "number_tile", "man", "sou" } },
    .{ .id = "sou", .name_ja = "索子", .reading = "ソーズ", .category = .basics, .definition = "竹を図案にした数牌。表記sを使います。", .example = "3sは三索。", .aliases = &.{}, .related = &.{ "number_tile", "man", "pin" } },
    .{ .id = "wind_tile", .name_ja = "風牌", .reading = "カゼハイ", .category = .basics, .definition = "東・南・西・北の4種類の字牌。場風や自風になると役牌です。", .example = "東場の東は場風牌。", .aliases = &.{}, .related = &.{ "round_wind", "seat_wind", "guest_wind" } },
    .{ .id = "dragon_tile", .name_ja = "三元牌", .reading = "サンゲンパイ", .category = .basics, .definition = "白・發・中の3種類。刻子や槓子にすると役牌になります。", .example = "白を3枚そろえると役牌。", .aliases = &.{}, .related = &.{ "triplet", "quad" } },
    .{ .id = "terminal_tile", .name_ja = "老頭牌", .reading = "ロウトウハイ", .category = .basics, .definition = "数牌の1と9。各種類の端の数字です。", .example = "1萬・9筒・1索など。", .aliases = &.{"一九牌"}, .related = &.{ "outside_tile", "simple_tile" } },
    .{ .id = "outside_tile", .name_ja = "么九牌", .reading = "ヤオチュウハイ", .category = .basics, .definition = "数牌の1・9と、すべての字牌。断么九では使いません。", .example = "9萬も中も么九牌です。", .aliases = &.{}, .related = &.{ "terminal_tile", "honor_tile" } },
    .{ .id = "simple_tile", .name_ja = "中張牌", .reading = "チュンチャンパイ", .category = .basics, .definition = "数牌の2〜8。1・9・字牌以外の牌です。", .example = "断么九は中張牌だけで作ります。", .aliases = &.{}, .related = &.{"outside_tile"} },
    .{ .id = "hand", .name_ja = "手牌", .reading = "テハイ", .category = .hand, .definition = "自分の持っている牌。役を調べる画面では、和了牌を含めて入力します。", .example = "副露面子を別欄に置いた場合、手牌欄には残りだけを入力。", .aliases = &.{}, .related = &.{ "winning_tile", "meld", "pair" } },
    .{ .id = "meld", .name_ja = "面子", .reading = "メンツ", .category = .hand, .definition = "順子・刻子・槓子の組。通常の和了は4面子と1つの雀頭で構成します。", .example = "123萬は順子、555筒は刻子。", .aliases = &.{}, .related = &.{ "sequence", "triplet", "quad", "head" } },
    .{ .id = "pair", .name_ja = "対子", .reading = "トイツ", .category = .hand, .definition = "同じ牌2枚の組。雀頭や七対子の材料になります。", .example = "5筒・5筒で1対子。", .aliases = &.{}, .related = &.{ "head", "triplet" } },
    .{ .id = "head", .name_ja = "雀頭", .reading = "ジャントウ", .category = .hand, .definition = "4面子の手で、残る同じ牌2枚の組。アタマとも呼びます。", .example = "平和では雀頭に役牌を使えません。", .aliases = &.{"アタマ"}, .related = &.{ "pair", "value_pair" } },
    .{ .id = "sequence", .name_ja = "順子", .reading = "シュンツ", .category = .hand, .definition = "同じ種類の数牌が連続した3枚の組。字牌では作れません。", .example = "2萬・3萬・4萬。9萬・1萬・2萬は順子ではありません。", .aliases = &.{}, .related = &.{ "meld", "chi" } },
    .{ .id = "triplet", .name_ja = "刻子", .reading = "コーツ", .category = .hand, .definition = "同じ牌3枚の組。数牌でも字牌でも作れます。", .example = "中・中・中。", .aliases = &.{}, .related = &.{ "concealed_triplet", "open_triplet", "pon" } },
    .{ .id = "quad", .name_ja = "槓子", .reading = "カンツ", .category = .hand, .definition = "同じ牌4枚の組。面子としては3枚相当を数えます。", .example = "1槓なら、和了時の実物の牌は15枚になります。", .aliases = &.{}, .related = &.{ "kan", "concealed_kan" } },
    .{ .id = "concealed_triplet", .name_ja = "暗刻", .reading = "アンコ", .category = .hand, .definition = "他家の牌をポンせず、手の中で完成した刻子。ロンで刻子を完成させた場合は暗刻に数えません。", .example = "三暗刻は暗刻または暗槓が3組必要。", .aliases = &.{}, .related = &.{ "triplet", "ron", "concealed_kan" } },
    .{ .id = "open_triplet", .name_ja = "明刻", .reading = "ミンコ", .category = .hand, .definition = "ポンで作った刻子。役の計算上、ロンで完成した刻子も明刻として扱います。", .example = "ロンした牌が雀頭や順子を完成させる場合、他の暗刻には影響しません。", .aliases = &.{}, .related = &.{ "pon", "concealed_triplet" } },
    .{ .id = "closed", .name_ja = "門前", .reading = "メンゼン", .category = .context, .definition = "チー・ポン・明槓をしていない状態。暗槓は門前を保ちます。", .example = "門前でもロンはできます。", .aliases = &.{"門前清"}, .related = &.{ "open", "concealed_kan" } },
    .{ .id = "open", .name_ja = "副露", .reading = "フーロ", .category = .context, .definition = "チー・ポン・明槓で面子を公開すること。門前限定役が成立しなくなります。", .example = "副露しても断么九や役牌は成立します。", .aliases = &.{"鳴き"}, .related = &.{ "chi", "pon", "kan", "open_reduction" } },
    .{ .id = "chi", .name_ja = "チー", .reading = "チー", .category = .context, .definition = "上家の捨て牌を使って順子を作る鳴き。", .example = "手に23萬があり、上家の4萬をチーして234萬。", .aliases = &.{}, .related = &.{ "sequence", "open" } },
    .{ .id = "pon", .name_ja = "ポン", .reading = "ポン", .category = .context, .definition = "他家の捨て牌を使って刻子を作る鳴き。", .example = "手に白白があり、白をポンして白白白。", .aliases = &.{}, .related = &.{ "triplet", "open" } },
    .{ .id = "kan", .name_ja = "明槓", .reading = "ミンカン", .category = .context, .definition = "他家の牌を使って作る槓子。大明槓・加槓があります。", .example = "ポンした組に4枚目を加えるのは加槓。", .aliases = &.{}, .related = &.{ "quad", "concealed_kan", "rinshan_tile" } },
    .{ .id = "concealed_kan", .name_ja = "暗槓", .reading = "アンカン", .category = .context, .definition = "自分で集めた同じ牌4枚を槓子として宣言すること。門前を保ち、暗刻としても数えます。", .example = "4枚を手牌欄に置くだけでなく、暗槓面子として指定します。", .aliases = &.{}, .related = &.{ "quad", "closed" } },
    .{ .id = "winning_tile", .name_ja = "和了牌", .reading = "アガリハイ", .category = .winning, .definition = "和了を完成させた最後の1枚。平和や三暗刻の判定にも必要です。", .example = "同じ完成形でも、どの牌でロンしたかで役が変わることがあります。", .aliases = &.{}, .related = &.{ "ron", "tsumo", "wait" } },
    .{ .id = "ron", .name_ja = "ロン", .reading = "ロン", .category = .winning, .definition = "他家の捨て牌などを使って和了すること。", .example = "シャンポン待ちでロンして完成した刻子は暗刻ではありません。", .aliases = &.{}, .related = &.{ "tsumo", "concealed_triplet" } },
    .{ .id = "tsumo", .name_ja = "ツモ", .reading = "ツモ", .category = .winning, .definition = "自分で牌を引くこと。和了方法としては、自分で引いた牌で和了することです。", .example = "門前でツモ和了すれば門前清自摸和。", .aliases = &.{}, .related = &.{ "ron", "closed" } },
    .{ .id = "tenpai", .name_ja = "聴牌", .reading = "テンパイ", .category = .winning, .definition = "あと1枚で和了の形が完成する状態。役がない聴牌もあります。", .example = "このアプリは待ちの列挙や聴牌判定は行いません。", .aliases = &.{}, .related = &.{ "wait", "riichi_declaration" } },
    .{ .id = "wait", .name_ja = "待ち", .reading = "マチ", .category = .winning, .definition = "和了を完成させる牌、またはその待ちの形。", .example = "同じ牌姿でも和了牌の使い方で待ちが変わる場合があります。", .aliases = &.{}, .related = &.{ "ryanmen", "kanchan", "penchan", "shanpon", "tanki" } },
    .{ .id = "ryanmen", .name_ja = "両面待ち", .reading = "リャンメンマチ", .category = .winning, .definition = "連続する2枚の両端を待つ形。平和の条件のひとつです。", .example = "23萬から1萬または4萬。78萬から6萬または9萬も両面。", .aliases = &.{"リャンメン"}, .related = &.{ "wait", "penchan" } },
    .{ .id = "kanchan", .name_ja = "嵌張待ち", .reading = "カンチャンマチ", .category = .winning, .definition = "1つ飛ばしの2枚の間を待つ形。", .example = "24萬から3萬。", .aliases = &.{"カンチャン"}, .related = &.{"wait"} },
    .{ .id = "penchan", .name_ja = "辺張待ち", .reading = "ペンチャンマチ", .category = .winning, .definition = "12の3、または89の7を待つ形。", .example = "12索から3索。78索から9索は辺張ではなく両面。", .aliases = &.{"ペンチャン"}, .related = &.{ "ryanmen", "wait" } },
    .{ .id = "shanpon", .name_ja = "シャンポン待ち", .reading = "シャンポンマチ", .category = .winning, .definition = "2組の対子のどちらかを刻子にする待ち。", .example = "55萬と中中なら、5萬または中。", .aliases = &.{ "双碰", "シャボ" }, .related = &.{ "concealed_triplet", "wait" } },
    .{ .id = "tanki", .name_ja = "単騎待ち", .reading = "タンキマチ", .category = .winning, .definition = "雀頭や七対子の最後の対子を完成させる1枚を待つ形。", .example = "5萬1枚からもう1枚の5萬を待ちます。", .aliases = &.{"タンキ"}, .related = &.{ "head", "pair" } },
    .{ .id = "round_wind", .name_ja = "場風", .reading = "バカゼ", .category = .context, .definition = "局の場を表す風。東場では東、南場では南が場風です。", .example = "場風牌の刻子・槓子が役牌。", .aliases = &.{}, .related = &.{ "seat_wind", "double_wind" } },
    .{ .id = "seat_wind", .name_ja = "自風", .reading = "ジカゼ", .category = .context, .definition = "その局での自分の風。親は東、次の人から南・西・北です。", .example = "南家の南刻子は役牌。", .aliases = &.{"門風"}, .related = &.{ "round_wind", "guest_wind" } },
    .{ .id = "guest_wind", .name_ja = "客風", .reading = "オタカゼ", .category = .context, .definition = "場風でも自風でもない風牌。刻子にしても役牌にはなりません。", .example = "東場の南家にとって、西と北は客風。", .aliases = &.{"オタ風"}, .related = &.{ "round_wind", "seat_wind" } },
    .{ .id = "double_wind", .name_ja = "連風牌", .reading = "レンプウハイ", .category = .context, .definition = "場風と自風が同じ風牌。刻子・槓子なら役牌2翻を数えます。", .example = "東場の東家の東刻子。", .aliases = &.{ "ダブ東", "ダブ南" }, .related = &.{ "round_wind", "seat_wind" } },
    .{ .id = "value_pair", .name_ja = "役牌の雀頭", .reading = "ヤクハイノジャントウ", .category = .rules, .definition = "三元牌・場風・自風を雀頭にした形。雀頭だけでは役牌という役は成立せず、平和にもなりません。", .example = "白白の雀頭は平和を妨げますが、白白だけでは役牌の役にはなりません。", .aliases = &.{}, .related = &.{ "head", "dragon_tile" } },
    .{ .id = "riichi_declaration", .name_ja = "立直宣言", .reading = "リーチセンゲン", .category = .context, .definition = "門前で聴牌し、立直を宣言すること。牌姿だけから宣言の有無は分かりません。", .example = "役を調べる画面では、立直の項目で有無を指定します。", .aliases = &.{"リーチ"}, .related = &.{ "closed", "tenpai" } },
    .{ .id = "han", .name_ja = "翻", .reading = "ハン", .category = .rules, .definition = "役の価値を表す単位。役の翻数を合計しますが、点数には符なども関係します。", .example = "立直1翻＋七対子2翻で3翻。点数計算は対象外です。", .aliases = &.{}, .related = &.{ "open_reduction", "yakuman", "dora" } },
    .{ .id = "open_reduction", .name_ja = "喰い下がり", .reading = "クイサガリ", .category = .rules, .definition = "副露すると役の翻数が1翻下がること。副露不可とは異なります。", .example = "三色同順は門前2翻、副露1翻。", .aliases = &.{}, .related = &.{ "open", "han", "closed" } },
    .{ .id = "open_tanyao", .name_ja = "喰いタン", .reading = "クイタン", .category = .rules, .definition = "副露した断么九。この教材では成立するルールを採用しています。", .example = "チー・ポンをしても、全牌が2〜8なら断么九。", .aliases = &.{}, .related = &.{ "simple_tile", "open" } },
    .{ .id = "yakuman", .name_ja = "役満", .reading = "ヤクマン", .category = .rules, .definition = "特別に高い価値を持つ役。成立した場合、通常役は一緒に表示しません。", .example = "国士無双、大三元など。役満同士は複合します。", .aliases = &.{}, .related = &.{"han"} },
    .{ .id = "dora", .name_ja = "ドラ", .reading = "ドラ", .category = .rules, .definition = "役に追加する翻数の材料。ドラそのものは役ではありません。", .example = "ドラがあっても、役がなければ和了できません。", .aliases = &.{}, .related = &.{"han"} },
    .{ .id = "no_yaku", .name_ja = "役なし", .reading = "ヤクナシ", .category = .rules, .definition = "和了の形ができていても、成立する役がない状態。", .example = "副露した4順子の手は、他の役がなければ平和にはなりません。", .aliases = &.{}, .related = &.{ "closed", "dora" } },
    .{ .id = "rinshan_tile", .name_ja = "嶺上牌", .reading = "リンシャンハイ", .category = .winning, .definition = "槓した後に補充として引く牌。嶺上牌でツモ和了すると嶺上開花です。", .example = "通常の山の最後のツモ牌とは区別します。", .aliases = &.{}, .related = &.{ "kan", "concealed_kan" } },
};
pub fn find(id: []const u8) ?Term {
    for (all) |term| if (std.mem.eql(u8, id, term.id)) return term;
    return null;
}
test "glossary has unique IDs and valid related links" {
    try std.testing.expect(all.len >= 40);
    try std.testing.expect(find("ryanmen") != null);
    try std.testing.expect(find("unknown") == null);
    for (all, 0..) |term, i| {
        try std.testing.expect(term.definition.len > 0 and term.example.len > 0);
        for (all[0..i]) |other| try std.testing.expect(!std.mem.eql(u8, term.id, other.id));
        for (term.related) |id| try std.testing.expect(find(id) != null);
    }
}
