const std = @import("std");
const jsmn = @import("./jsmn.zig");

fn foo(s: []const u8) void {
    for (s) |v| {
        std.debug.print("{d}\n", .{v});
    }
}

fn asByteArray(comptime T: type, v: *T) *const [@sizeOf(T)]u8 {
    return @ptrCast(*[@sizeOf(T)]u8, v);
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    _ = jsmn.parseJSON(arena.allocator(), undefined);
}
