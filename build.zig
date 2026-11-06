const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const Backend = enum { native, workers };
    const backend = b.option(Backend, "backend", "deployment backend (native | workers)") orelse .native;

    const native_target = b.standardTargetOptions(.{});
    const target = switch (backend) {
        .native => native_target,
        .workers => b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding }),
    };

    const am = b.dependency("akamata", .{
        .backend = backend,
        .target = target,
        .optimize = optimize,
    });

    const root = switch (backend) {
        .native => "src/main.zig",
        .workers => "src/worker.zig",
    };

    const web_assets = b.createModule(.{ .root_source_file = b.path("web/assets.zig") });

    const exe = b.addExecutable(.{
        .name = if (backend == .workers) "yaku-mvp_worker" else "yaku-mvp",
        .root_module = b.createModule(.{
            .root_source_file = b.path(root),
            .target = target,
            // Respect -Doptimize. `akamata deploy --workers` defaults to
            // ReleaseFast (override with --optimize=ReleaseSmall for the
            // smallest bundle).
            .optimize = optimize,
            .imports = &.{ .{ .name = "akamata", .module = am.module("akamata") }, .{ .name = "web_assets", .module = web_assets } },
        }),
    });
    if (backend == .workers) {
        exe.entry = .disabled;
        exe.rdynamic = true;
    }
    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    run.addPassthruArgs();
    b.step("run", "run the app (native)").dependOn(&run.step);

    if (backend == .native) {
        const unit_tests = b.addTest(.{ .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = native_target,
            .optimize = optimize,
            .imports = &.{ .{ .name = "akamata", .module = am.module("akamata") }, .{ .name = "web_assets", .module = web_assets } },
        }) });
        const run_tests = b.addRunArtifact(unit_tests);
        const web_tests = b.addSystemCommand(&.{ "node", "--test", "tests/stats.test.mjs", "tests/request-limit.test.mjs", "tests/frontend-syntax.test.mjs", "tests/hand-input.test.mjs" });
        b.step("web-test", "test browser learning record").dependOn(&web_tests.step);
        const test_step = b.step("test", "test the application without a listener");
        test_step.dependOn(&run_tests.step);
        test_step.dependOn(&web_tests.step);
    }
}
