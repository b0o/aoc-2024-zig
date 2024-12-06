const std = @import("std");
const lines = @import("lines.zig");

fn foo() u8 {
    return 0;
}

test {
    try std.testing.expectEqual(0, foo());
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();
    const stdin = std.io.getStdIn().reader();
    var iter = lines.lineIterator(alloc, stdin.any());
    defer iter.deinit();
    while (try iter.next()) |line| {
        _ = line;
    }
    std.debug.print("Result: {}\n", .{foo()});
}
