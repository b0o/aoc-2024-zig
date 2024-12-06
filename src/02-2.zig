// --- Day 2: Red-Nosed Reports ---
//
// Fortunately, the first location The Historians want to search isn't a long
// walk from the Chief Historian's office.
//
// While the Red-Nosed Reindeer nuclear fusion/fission plant appears to contain
// no sign of the Chief Historian, the engineers there run up to you as soon as
// they see you. Apparently, they still talk about the time Rudolph was saved
// through molecular synthesis from a single electron.
//
// They're quick to add that - since you're already here - they'd really
// appreciate your help analyzing some unusual data from the Red-Nosed reactor.
// You turn to check if The Historians are waiting for you, but they seem to
// have already divided into groups that are currently searching every corner
// of the facility. You offer to help with the unusual data.
//
// The unusual data (your puzzle input) consists of many reports, one report
// per line. Each report is a list of numbers called levels that are separated
// by spaces. For example:
//
// 7 6 4 2 1
// 1 2 7 8 9
// 9 7 6 2 1
// 1 3 2 4 5
// 8 6 4 4 1
// 1 3 6 7 9
//
// This example data contains six reports each containing five levels.
//
// The engineers are trying to figure out which reports are safe. The Red-Nosed
// reactor safety systems can only tolerate levels that are either gradually
// increasing or gradually decreasing. So, a report only counts as safe if both
// of the following are true:
//
//     The levels are either all increasing or all decreasing.
//     Any two adjacent levels differ by at least one and at most three.
//
// In the example above, the reports can be found safe or unsafe by checking
// those rules:
//
//     7 6 4 2 1: Safe because the levels are all decreasing by 1 or 2.
//     1 2 7 8 9: Unsafe because 2 7 is an increase of 5.
//     9 7 6 2 1: Unsafe because 6 2 is a decrease of 4.
//     1 3 2 4 5: Unsafe because 1 3 is increasing but 3 2 is decreasing.
//     8 6 4 4 1: Unsafe because 4 4 is neither an increase or a decrease.
//     1 3 6 7 9: Safe because the levels are all increasing by 1, 2, or 3.
//
// So, in this example, 2 reports are safe.
//
// Analyze the unusual data from the engineers. How many reports are safe?
//
// --- Part Two ---
//
// The engineers are surprised by the low number of safe reports until they
// realize they forgot to tell you about the Problem Dampener.
//
// The Problem Dampener is a reactor-mounted module that lets the reactor
// safety systems tolerate a single bad level in what would otherwise be a safe
// report. It's like the bad level never happened!
//
// Now, the same rules apply as before, except if removing a single level from
// an unsafe report would make it safe, the report instead counts as safe.
//
// More of the above example's reports are now safe:
//
//     7 6 4 2 1: Safe without removing any level.
//     1 2 7 8 9: Unsafe regardless of which level is removed.
//     9 7 6 2 1: Unsafe regardless of which level is removed.
//     1 3 2 4 5: Safe by removing the second level, 3.
//     8 6 4 4 1: Safe by removing the third level, 4.
//     1 3 6 7 9: Safe without removing any level.
//
// Thanks to the Problem Dampener, 4 reports are actually safe!
//
// Update your analysis by handling situations where the Problem Dampener can
// remove a single level from unsafe reports. How many reports are now safe?

const std = @import("std");
const lines = @import("lines.zig");

const Dir = enum { dec, eq, inc };

fn isSafe(lvls: []const i32) bool {
    if (lvls.len < 2) return true;
    var dir: ?Dir = null;
    var prev = lvls[0];
    for (lvls[1..]) |lvl| {
        const diff = lvl - prev;
        const d: Dir = switch (std.math.sign(diff)) {
            -1 => .dec,
            0 => .eq,
            1 => .inc,
            else => unreachable,
        };
        if (d == .eq or (dir != null and d != dir) or @abs(diff) > 3) return false;
        prev = lvl;
        dir = d;
    }
    return true;
}

fn isSafeRecoverable(alloc: std.mem.Allocator, lvls: []const i32) !bool {
    if (lvls.len < 2) return true;
    // 01 12 23 34 45 56
    // __ 12 23 34 45 56
    // 01 __ 23 34 45 56
    // 01 12 __ 34 45 56
    // 01 12 23 __ 45 56
    // 01 12 23 34 __ 56
    // 01 12 23 34 45 __
    if (isSafe(lvls)) return true;
    var sub = try std.ArrayList(i32).initCapacity(alloc, lvls.len - 1);
    defer sub.deinit();
    for (0..lvls.len) |i| {
        try sub.appendSlice(lvls[0..i]);
        try sub.appendSlice(lvls[i + 1 ..]);
        if (isSafe(sub.items)) return true;
        try sub.resize(0);
    }
    return false;
}

test {
    const expectEqual = std.testing.expectEqual;
    const alloc = std.testing.allocator;

    try expectEqual(true, isSafeRecoverable(alloc, &.{}));
    try expectEqual(true, isSafeRecoverable(alloc, &.{12}));
    try expectEqual(true, isSafeRecoverable(alloc, &.{ 12, 11 }));
    try expectEqual(true, isSafeRecoverable(alloc, &.{ 7, 6, 4, 2, 1 }));
    try expectEqual(true, isSafeRecoverable(alloc, &.{ 1, 3, 2, 4, 5 }));
    try expectEqual(true, isSafeRecoverable(alloc, &.{ 8, 6, 4, 4, 1 }));
    try expectEqual(true, isSafeRecoverable(alloc, &.{ 1, 3, 6, 7, 9 }));
    try expectEqual(true, isSafeRecoverable(alloc, &.{ 8, 11, 13, 14, 15, 18, 17 }));
    try expectEqual(true, isSafeRecoverable(alloc, &.{ 43, 44, 47, 49, 52, 52 }));
    try expectEqual(true, isSafeRecoverable(alloc, &.{ 2, 4, 3, 4, 5, 6 }));
    try expectEqual(false, isSafeRecoverable(alloc, &.{ 1, 2, 7, 8, 9 }));
    try expectEqual(false, isSafeRecoverable(alloc, &.{ 9, 7, 6, 2, 1 }));
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();
    const stdin = std.io.getStdIn().reader();
    var iter = lines.lineIterator(alloc, stdin.any());
    defer iter.deinit();

    var safe: u16 = 0;
    var lvls = try std.ArrayList(i32).initCapacity(alloc, 64);
    defer lvls.deinit();

    while (try iter.next()) |line| {
        var seq = std.mem.splitSequence(u8, line, " ");
        while (seq.next()) |lvl| {
            try lvls.append(try std.fmt.parseInt(i32, lvl, 10));
        }
        safe += if (try isSafeRecoverable(alloc, lvls.items)) 1 else 0;
        try lvls.resize(0);
    }

    std.debug.print("Safe: {}\n", .{safe});
}
