const std = @import("std");
const ak = @import("akamata");

pub const State = struct {
    pub const application_contract = @import("app/contract.zig").For(if (ak.backend == .workers) .workers else .native);
};
pub const Application = ak.App(.{ .State = State, .routes = @import("app/contract.zig").routes, .configure = configure });
pub fn buildApplication(allocator: std.mem.Allocator) !Application {
    return Application.init(allocator);
}

pub fn main(init: std.process.Init) !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    var args_arena: std.heap.ArenaAllocator = .init(gpa.allocator());
    defer args_arena.deinit();
    const args = try init.minimal.args.toSlice(args_arena.allocator());
    if (args.len > 1) {
        const command = std.mem.sliceTo(args[1], 0);
        if (std.mem.eql(u8, command, "akamata-openapi") or std.mem.eql(u8, command, "akamata-capabilities")) {
            var buffer: [4096]u8 = undefined;
            var stdout = std.Io.File.stdout().writer(init.io, &buffer);
            if (std.mem.eql(u8, command, "akamata-openapi")) {
                var metadata: Application.Metadata = .{};
                const document = try ak.openapi.generate(Application.Metadata, &metadata, gpa.allocator(), .{ .title = "役のノート", .version = "1.0.0" });
                defer gpa.allocator().free(document);
                try stdout.interface.writeAll(document);
            } else {
                const Contract = @import("app/contract.zig").For(.native);
                const target = if (args.len == 3) std.mem.sliceTo(args[2], 0) else "native";
                if (std.mem.eql(u8, target, "workers")) try Contract.writeManifest(.workers, &stdout.interface, Application.Endpoints) else if (std.mem.eql(u8, target, "native")) try Contract.writeManifest(.native, &stdout.interface, Application.Endpoints) else if (std.mem.eql(u8, target, "containers")) try Contract.writeManifest(.containers, &stdout.interface, Application.Endpoints) else return error.InvalidTarget;
            }
            return stdout.interface.flush();
        }
        return error.UnknownCommand;
    }
    var app = try buildApplication(gpa.allocator());
    defer app.deinit();
    const configured_port = ak.env.get(gpa.allocator(), "PORT");
    defer if (configured_port) |value| gpa.allocator().free(value);
    const port = if (configured_port) |value| try std.fmt.parseInt(u16, value, 10) else 8080;
    std.debug.print("Akamata: starting http://127.0.0.1:{d}/\n", .{port});
    try app.serve(.{ .port = port, .parse_limits = .{ .max_body_bytes = 4096 } });
}

test "Hello application contract" {
    var app = try buildApplication(std.testing.allocator);
    defer app.deinit();
    var client = app.client(std.testing.allocator);
    defer client.deinit();
    var response = try client.get("/").send();
    defer response.deinit();
    try response.expectStatus(.ok);
}

test {
    _ = @import("mahjong/tile.zig");
    _ = @import("mahjong/meld.zig");
    _ = @import("mahjong/yaku.zig");
    _ = @import("quiz/question.zig");
}

test {
    _ = @import("mahjong/yaku_catalog.zig");
}

test {
    _ = @import("quiz/question_bank.zig");
}

test {
    _ = @import("quiz/generator.zig");
    _ = @import("quiz/evaluator.zig");
}

fn configure(app: *ak.App(State)) !void {
    _ = try app.useAll(ak.mw.recover(State));
    _ = try app.useAll(ak.mw.logger(State));
}
test {
    _ = @import("app/integration_test.zig");
}

test {
    _ = @import("analysis/evaluator_test.zig");
}

test {
    _ = @import("mahjong/glossary.zig");
}
