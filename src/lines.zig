const std = @import("std");

pub fn LineIterator(comptime ReaderType: type) type {
    return struct {
        reader: ReaderType,
        allocator: std.mem.Allocator,
        current_line: ?[]u8,

        pub fn init(alloc: std.mem.Allocator, reader: ReaderType) @This() {
            return .{
                .reader = reader,
                .allocator = alloc,
                .current_line = null,
            };
        }

        pub fn next(self: *@This()) !?[]const u8 {
            if (self.current_line) |line| {
                self.allocator.free(line);
                self.current_line = null;
            }

            var line_buffer = std.ArrayList(u8).init(self.allocator);
            errdefer line_buffer.deinit();

            self.reader.streamUntilDelimiter(line_buffer.writer(), '\n', null) catch |err| switch (err) {
                error.EndOfStream => {
                    if (line_buffer.items.len == 0) {
                        line_buffer.deinit();
                        return null;
                    }
                    self.current_line = try line_buffer.toOwnedSlice();
                    return self.current_line;
                },
                else => {
                    line_buffer.deinit();
                    return err;
                },
            };

            self.current_line = try line_buffer.toOwnedSlice();
            return self.current_line;
        }

        pub fn deinit(self: *@This()) void {
            if (self.current_line) |line| {
                self.allocator.free(line);
            }
        }
    };
}

pub fn lineIterator(alloc: std.mem.Allocator, reader: anytype) LineIterator(@TypeOf(reader)) {
    return LineIterator(@TypeOf(reader)).init(alloc, reader);
}
