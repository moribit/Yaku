const std = @import("std");
const bank = @import("question_bank.zig");
const catalog = @import("../mahjong/yaku_catalog.zig");
const dto = @import("../app/dto.zig");
const Difficulty = @import("question.zig").Difficulty;
const Choice = dto.Choice;
fn choice(id: []const u8) Choice {
    const y = catalog.find(id).?;
    return .{ .id = y.id, .name_ja = y.name_ja, .reading = y.reading };
}
/// A caller-owned random source makes both shuffles deterministic under test.
pub fn generate(allocator: std.mem.Allocator, difficulty: Difficulty, count: usize, random: std.Random) !dto.QuizResponse {
    if (count == 0 or count > 10) return error.InvalidCount;
    var indices: [bank.all.len]usize = undefined;
    var len: usize = 0;
    for (bank.all, 0..) |q, i| if (q.difficulty == difficulty) {
        indices[len] = i;
        len += 1;
    };
    if (count > len) return error.InsufficientQuestions;
    random.shuffle(usize, indices[0..len]);
    const questions = try allocator.alloc(dto.PublicQuestion, count);
    for (questions, indices[0..count]) |*public, i| {
        const q = bank.all[i];
        const choices = try allocator.alloc(Choice, q.correct_yaku.len + q.distractors.len);
        for (q.correct_yaku, 0..) |id, j| choices[j] = choice(id);
        for (q.distractors, q.correct_yaku.len..) |id, j| choices[j] = choice(id);
        random.shuffle(Choice, choices);
        public.* = .{ .id = q.id, .hand = q.hand, .open_melds = q.open_melds, .context = q.context, .choices = choices };
    }
    return .{ .questions = questions };
}
test "difficulty filtering, unique selection, choices and deterministic randomness" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();
    for ([_]Difficulty{ .beginner, .intermediate, .advanced }) |difficulty| {
        var prng: std.Random.DefaultPrng = .init(42);
        var replay: std.Random.DefaultPrng = .init(42);
        var other: std.Random.DefaultPrng = .init(99);
        const quiz = try generate(arena.allocator(), difficulty, 10, prng.random());
        const same = try generate(arena.allocator(), difficulty, 10, replay.random());
        const different = try generate(arena.allocator(), difficulty, 10, other.random());
        var differs = false;
        for (quiz.questions, 0..) |q, i| {
            try std.testing.expectEqual(difficulty, bank.find(q.id).?.difficulty);
            try std.testing.expectEqualStrings(q.id, same.questions[i].id);
            if (!std.mem.eql(u8, q.id, different.questions[i].id)) differs = true;
            for (quiz.questions[0..i]) |previous| try std.testing.expect(!std.mem.eql(u8, q.id, previous.id));
            const internal = bank.find(q.id).?;
            try std.testing.expectEqual(internal.correct_yaku.len + internal.distractors.len, q.choices.len);
            for (q.choices, 0..) |option, j| {
                try std.testing.expectEqualStrings(option.id, same.questions[i].choices[j].id);
                try std.testing.expect(bank.contains(internal.correct_yaku, option.id) or bank.contains(internal.distractors, option.id));
                for (q.choices[0..j]) |previous| try std.testing.expect(!std.mem.eql(u8, option.id, previous.id));
            }
        }
        try std.testing.expect(differs);
    }
    var prng: std.Random.DefaultPrng = .init(0);
    try std.testing.expectError(error.InvalidCount, generate(arena.allocator(), .beginner, 0, prng.random()));
    try std.testing.expectError(error.InvalidCount, generate(arena.allocator(), .beginner, 11, prng.random()));
}
