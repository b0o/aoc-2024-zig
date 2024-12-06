const std = @import("std");

const Puzzle = struct {
    name: []const u8,
};

const puzzles: []const Puzzle = &.{
    .{ .name = "01-1" },
    .{ .name = "01-2" },
    .{ .name = "02-1" },
    .{ .name = "02-2" },
    .{ .name = "03-1" },
    .{ .name = "03-2" },
    .{ .name = "04-1" },
    .{ .name = "04-2" },
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var puzzle_map = std.StringHashMap(*std.Build.Step.Compile).init(b.allocator);
    defer puzzle_map.deinit();

    const selected_puzzle = b.option(
        []const u8,
        "puzzle",
        "Select specific puzzle to build (e.g. '01', '02-1')",
    );

    const run_all = b.step("run", "Run all puzzles");
    const test_all = b.step("test", "Run all unit tests");

    for (puzzles) |puzzle| {
        const exe = b.addExecutable(.{
            .name = puzzle.name,
            .root_source_file = b.path(b.fmt("src/{s}.zig", .{puzzle.name})),
            .target = target,
            .optimize = optimize,
        });

        puzzle_map.put(puzzle.name, exe) catch unreachable;

        if (selected_puzzle == null or std.mem.eql(u8, puzzle.name, selected_puzzle.?)) {
            b.installArtifact(exe);

            const run_cmd = b.addRunArtifact(exe);
            run_cmd.step.dependOn(b.getInstallStep());

            if (b.args) |args| {
                run_cmd.addArgs(args);
            }

            const run_step = b.step(b.fmt("run-{s}", .{puzzle.name}), b.fmt("Run puzzle {s}", .{puzzle.name}));
            run_step.dependOn(&run_cmd.step);
            run_all.dependOn(run_step);

            const lib_unit_tests = b.addTest(.{
                .root_source_file = b.path(b.fmt("src/{s}.zig", .{puzzle.name})),
                .target = target,
                .optimize = optimize,
            });

            const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

            const success_msg = b.addSystemCommand(&.{
                "echo",
                b.fmt("✓ Tests passed for {s}", .{puzzle.name}),
            });
            success_msg.step.dependOn(&run_lib_unit_tests.step);

            const exe_unit_tests = b.addTest(.{
                .root_source_file = b.path(b.fmt("src/{s}.zig", .{puzzle.name})),
                .target = target,
                .optimize = optimize,
            });

            const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

            const test_step = b.step(b.fmt("test-{s}", .{puzzle.name}), b.fmt("Run unit tests for puzzle {s}", .{puzzle.name}));
            test_step.dependOn(&run_lib_unit_tests.step);
            test_step.dependOn(&run_exe_unit_tests.step);
            test_step.dependOn(&success_msg.step);
            test_all.dependOn(test_step);
        }
    }

    const summary_step = b.step("test-summary", "Show test summary");
    const summary_msg = b.addSystemCommand(&.{
        "echo",
        "✓ All tests passed successfully",
    });
    summary_step.dependOn(test_all);
    summary_step.dependOn(&summary_msg.step);
}
