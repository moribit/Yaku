const ak = @import("akamata");
const Question = @import("../quiz/question.zig");
const Tile = @import("../mahjong/tile.zig").Tile;
const Meld = @import("../mahjong/meld.zig").Meld;
const Yaku = @import("../mahjong/yaku.zig").Yaku;
pub const QuizRequest = struct {
    difficulty: Question.Difficulty,
    count: u8 = 10,
    pub const validation = .{ .count = .{ak.model.rule.range(1, 10)} };
};
pub const CheckRequest = struct {
    question_id: []const u8,
    answers: []const []const u8,
    pub const validation = .{ .question_id = .{ ak.model.rule.min_len(1), ak.model.rule.max_len(32) } };
};
/// Only presentation fields. No primary_yaku, correct_yaku, decomposition or explanation.
pub const Choice = struct { id: []const u8, name_ja: []const u8, reading: []const u8 };
pub const PublicQuestion = struct {
    id: []const u8,
    hand: []const Tile,
    open_melds: []const Meld,
    context: Question.Context,
    choices: []const Choice,
};
pub const QuizResponse = struct { questions: []const PublicQuestion };
pub const YakuList = struct { yaku: []const Yaku };
pub const CheckResponse = struct {
    correct: bool,
    correct_yaku: []const []const u8,
    selected_yaku: []const []const u8,
    matched_yaku: []const []const u8,
    missed_yaku: []const []const u8,
    extra_yaku: []const []const u8,
    explanation: []const u8,
    decomposition: []const u8,
    yaku: []const Yaku,
};
