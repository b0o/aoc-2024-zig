// --- Day 4: Ceres Search ---
//
// "Looks like the Chief's not here. Next!" One of The Historians pulls out a
// device and pushes the only button on it. After a brief flash, you recognize
// the interior of the Ceres monitoring station!
//
// As the search for the Chief continues, a small Elf who lives on the station
// tugs on your shirt; she'd like to know if you could help her with her word
// search (your puzzle input). She only has to find one word: XMAS.
//
// This word search allows words to be horizontal, vertical, diagonal, written
// backwards, or even overlapping other words. It's a little unusual, though,
// as you don't merely need to find one instance of XMAS - you need to find all
// of them. Here are a few ways XMAS might appear, where irrelevant characters
// have been replaced with .:
//
//
// ..X...
// .SAMX.
// .A..A.
// XMAS.S
// .X....
//
// The actual word search will be full of letters instead. For example:
//
// MMMSXXMASM
// MSAMXMSMSA
// AMXSXMAAMM
// MSAMASMSMX
// XMASAMXAMM
// XXAMMXXAMA
// SMSMSASXSS
// SAXAMASAAA
// MAMMMXMMMM
// MXMXAXMASX
//
// In this word search, XMAS occurs a total of 18 times; here's the same word
// search again, but where letters not involved in any XMAS have been replaced
// with .:
//
// ....XXMAS.
// .SAMXMS...
// ...S..A...
// ..A.A.MS.X
// XMASAMX.MM
// X.....XA.A
// S.S.S.S.SS
// .A.A.A.A.A
// ..M.M.M.MM
// .X.X.XMASX
//
// Take a look at the little Elf's word search. How many times does XMAS
// appear?
//
// --- Part Two ---
//
// The Elf looks quizzically at you. Did you misunderstand the assignment?
//
// Looking for the instructions, you flip over the word search to find that
// this isn't actually an XMAS puzzle; it's an X-MAS puzzle in which you're
// supposed to find two MAS in the shape of an X.
//
// One way to achieve that is like this:
//
// M.S
// .A.
// M.S
//
// Irrelevant characters have again been replaced with . in the above diagram.
// Within the X, each MAS can be written forwards or backwards.
//
// Here's the same example from before, but this time all of the X-MASes have
// been kept instead:
//
// .M.S......
// ..A..MSMS.
// .M.S.MAA..
// ..A.ASMSM.
// .M.S.M....
// ..........
// S.S.S.S.S.
// .A.A.A.A..
// M.M.M.M.M.
// ..........
//
// In this example, an X-MAS appears 9 times.
//
// Flip the word search from the instructions back over to the word search side
// and try again. How many times does an X-MAS appear?

const std = @import("std");
const lines = @import("lines.zig");

const CeresSearcher = struct {
    lines: std.BoundedArray(std.BoundedArray(u8, 256), 3) = .{},
    found: u32 = 0,

    fn check(str: []const u8) bool {
        return (std.mem.eql(u8, str, "MAS") or std.mem.eql(u8, str, "SAM"));
    }

    pub fn read(self: *CeresSearcher, char: u8) !void {
        if (char == '\n') {
            if (self.lines.len == self.lines.capacity()) _ = self.lines.popOrNull();
            try self.lines.insert(0, .{});
            return;
        }
        if (self.lines.len == 0) try self.lines.insert(0, .{});

        const l0: *std.BoundedArray(u8, 256) = &self.lines.buffer[0];
        try l0.append(char);

        if (!(char == 'M' or char == 'S')) return;

        const i = l0.len - 1;
        if (self.lines.len < 3 or i < 2) return;

        const l1 = self.lines.get(1);
        const l2 = self.lines.get(2);
        if (check(&[_]u8{
            // North-West
            // 2  .  .
            // .  1  .
            // .  .  0
            char,
            l1.get(i - 1),
            l2.get(i - 2),
        }) and check(&[_]u8{
            // North-East
            // .  .  2
            // .  1  .
            // 0  .  .
            l0.get(i - 2),
            l1.get(i - 1),
            l2.get(i),
        })) {
            self.found += 1;
        }
    }
};

fn ceresSearchString(buf: []const u8) !u32 {
    var cs = CeresSearcher{};
    for (buf) |char| try cs.read(char);
    return cs.found;
}

fn ceresSearchReader(reader: std.io.AnyReader) !u32 {
    var cs = CeresSearcher{};
    while (reader.readByte() catch null) |char| try cs.read(char);
    return cs.found;
}

test {
    try std.testing.expectEqual(9, try ceresSearchString(
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ));
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    std.debug.print("Result: {}\n", .{try ceresSearchReader(stdin.any())});
}
