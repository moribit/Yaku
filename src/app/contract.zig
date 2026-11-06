const ak = @import("akamata");
pub fn For(comptime target: ak.capability.Target) type {
    const C = ak.capability.Contract("yaku-mvp", &.{}, &.{});
    C.validate(target);
    return C;
}
const h = @import("handlers.zig");
// This is the sole route declaration for both Native and Workers and generators.
pub const routes = .{
    ak.endpoint(.{ .method = .GET, .path = "/", .handler = h.index, .operation_id = "home", .fallback = .internal_server_error }),
    ak.endpoint(.{ .method = .GET, .path = "/app.js", .handler = h.javascript, .fallback = .internal_server_error }),
    ak.endpoint(.{ .method = .GET, .path = "/tiles.js", .handler = h.tilescript, .fallback = .internal_server_error }),
    ak.endpoint(.{ .method = .GET, .path = "/stats.js", .handler = h.statsScript, .fallback = .internal_server_error }),
    ak.endpoint(.{ .method = .GET, .path = "/styles.css", .handler = h.css, .fallback = .internal_server_error }),
    ak.endpoint(.{ .method = .GET, .path = "/api/yaku", .handler = h.listYaku, .operation_id = "listYaku" }),
    ak.endpoint(.{ .method = .GET, .path = "/api/yaku/:id", .handler = h.showYaku, .operation_id = "getYaku", .errors = .{ .not_found = .not_found } }),
    ak.endpoint(.{ .method = .POST, .path = "/api/quiz", .handler = h.quiz, .operation_id = "createQuiz", .limits = .{ .request_bytes = 4096 }, .fallback = .internal_server_error }),
    ak.endpoint(.{ .method = .POST, .path = "/api/quiz/check", .handler = h.check, .operation_id = "checkAnswer", .limits = .{ .request_bytes = 4096 }, .errors = .{ .not_found = .not_found, .invalid_answers = .bad_request }, .fallback = .internal_server_error }),
    ak.endpoint(.{ .method = .POST, .path = "/api/hand/analyze", .handler = h.analyze, .operation_id = "analyzeHand", .limits = .{ .request_bytes = 4096 }, .errors = .{ .invalid_tile_count = .bad_request, .invalid_tile = .bad_request, .missing_winning_tile = .bad_request, .invalid_meld = .bad_request, .too_many_copies = .bad_request, .invalid_context = .bad_request }, .fallback = .internal_server_error }),
    ak.endpoint(.{ .method = .GET, .path = "/api/glossary", .handler = h.glossary, .operation_id = "listGlossary" }),
    ak.endpoint(.{ .method = .GET, .path = "/api/glossary/:id", .handler = h.glossaryTerm, .operation_id = "getGlossaryTerm", .errors = .{ .not_found = .not_found } }),
    ak.endpoint(.{ .method = .GET, .path = "/analyzer.js", .handler = h.analyzerScript, .fallback = .internal_server_error }),
    ak.endpoint(.{ .method = .GET, .path = "/hand-input.js", .handler = h.handInputScript, .fallback = .internal_server_error }),
    ak.endpoint(.{ .method = .GET, .path = "/openapi.json", .handler = h.openapi, .fallback = .internal_server_error }),
    ak.endpoint(.{ .method = .GET, .path = "/client.ts", .handler = h.client, .fallback = .internal_server_error }),
};
