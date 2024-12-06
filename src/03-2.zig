// --- Day 3: Mull It Over ---
//
// "Our computers are having issues, so I have no idea if we have any Chief
// Historians in stock! You're welcome to check the warehouse, though," says the
// mildly flustered shopkeeper at the North Pole Toboggan Rental Shop. The
// Historians head out to take a look.
//
// The shopkeeper turns to you. "Any chance you can see why our computers are
// having issues again?"
//
// The computer appears to be trying to run a program, but its memory (your puzzle
// input) is corrupted. All of the instructions have been jumbled up!
//
// It seems like the goal of the program is just to multiply some numbers. It does
// that with instructions like mul(X,Y), where X and Y are each 1-3 digit numbers.
// For instance, mul(44,46) multiplies 44 by 46 to get a result of 2024. Similarly,
// mul(123,4) would multiply 123 by 4.
//
// However, because the program's memory has been corrupted, there are also many
// invalid characters that should be ignored, even if they look like part of a mul
// instruction. Sequences like mul(4*, mul(6,9!, ?(12,34), or mul ( 2 , 4 ) do
// nothing.
//
// For example, consider the following section of corrupted memory:
//
// xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
//  ^^^^^^^^                    ^^^^^^^^                ^^^^^^^^^^^^^^^^^
// Only the four highlighted sections are real mul instructions. Adding up the
// result of each instruction produces 161 (2*4 + 5*5 + 11*8 + 8*5).
//
// Scan the corrupted memory for uncorrupted mul instructions. What do you get if
// you add up all of the results of the multiplications?
//
// --- Part Two ---
//
// As you scan through the corrupted memory, you notice that some of the
// conditional statements are also still intact. If you handle some of the
// uncorrupted conditional statements in the program, you might be able to get
// an even more accurate result.
//
// There are two new instructions you'll need to handle:
//
// The do() instruction enables future mul instructions.
// The don't() instruction disables future mul instructions.
//
// Only the most recent do() or don't() instruction applies. At the beginning
// of the program, mul instructions are enabled.
//
// For example:
//
// xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
//
// This corrupted memory is similar to the example from before, but this time
// the mul(5,5) and mul(11,8) instructions are disabled because there is a
// don't() instruction before them. The other mul instructions function
// normally, including the one at the end that gets re-enabled by a do()
// instruction.
//
// This time, the sum of the results is 48 (2*4 + 8*5).
//
// Handle the new instructions; what do you get if you add up all of the
// results of just the enabled multiplications?

const std = @import("std");
const lines = @import("lines.zig");

const MulMachine = struct {
    state: State = .init,
    x: [16]u8 = [_]u8{0} ** 16,
    x_len: u8 = 0,
    y: [16]u8 = [_]u8{0} ** 16,
    y_len: u8 = 0,
    mul_enable: bool = true,
    sum: u32 = 0,

    const State = enum {
        init,

        m,
        mu,
        mul,
        @"mul(",
        @"mul(x",
        @"mul(x,",
        @"mul(x,y",
        @"mul(x,y)",

        d,
        do,
        @"do(",
        @"do()",

        don,
        @"don'",
        @"don't",
        @"don't(",
        @"don't()",
    };

    pub fn read(self: *MulMachine, char: u8) void {
        var state: State = switch (char) {
            'm' => .m,
            'u' => if (self.state == .m) .mu else .init,
            'l' => if (self.state == .mu) .mul else .init,
            ',' => if (self.state == .@"mul(x") .@"mul(x," else .init,
            '0'...'9' => switch (self.state) {
                .@"mul(", .@"mul(x" => blk: {
                    if (self.state == .@"mul(") {
                        self.x_len = 0;
                    }
                    self.x[self.x_len] = char;
                    self.x_len += 1;
                    break :blk .@"mul(x";
                },
                .@"mul(x,", .@"mul(x,y" => blk: {
                    if (self.state == .@"mul(x,") {
                        self.y_len = 0;
                    }
                    self.y[self.y_len] = char;
                    self.y_len += 1;
                    break :blk .@"mul(x,y";
                },
                else => .init,
            },

            'd' => .d,
            'o' => if (self.state == .d) .do else .init,

            'n' => if (self.state == .do) .don else .init,
            '\'' => if (self.state == .don) .@"don'" else .init,
            't' => if (self.state == .@"don'") .@"don't" else .init,

            '(' => switch (self.state) {
                .mul => .@"mul(",
                .do => .@"do(",
                .@"don't" => .@"don't(",
                else => .init,
            },
            ')' => switch (self.state) {
                .@"mul(x,y" => .@"mul(x,y)",
                .@"do(" => .@"do()",
                .@"don't(" => .@"don't()",
                else => .init,
            },

            else => .init,
        };

        state = switch (state) {
            .@"mul(x,y)" => blk: {
                if (!self.mul_enable) break :blk .init;
                const x = std.fmt.parseInt(u32, self.x[0..self.x_len], 10) catch unreachable;
                const y = std.fmt.parseInt(u32, self.y[0..self.y_len], 10) catch unreachable;
                const prod = x * y;
                self.sum += prod;
                break :blk .init;
            },
            .@"do()" => blk: {
                self.mul_enable = true;
                break :blk .init;
            },
            .@"don't()" => blk: {
                self.mul_enable = false;
                break :blk .init;
            },
            else => state,
        };

        self.state = state;
    }
};

fn eval(buf: []const u8) u32 {
    var mach = MulMachine{};
    for (buf) |char| mach.read(char);
    return mach.sum;
}

test {
    try std.testing.expectEqual(48, eval("xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"));
    try std.testing.expectEqual(48, eval("xmul(10,2mul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"));
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    var mach = MulMachine{};
    while (stdin.readByte() catch null) |char| mach.read(char);
    std.debug.print("Sum: {}\n", .{mach.sum});
}
