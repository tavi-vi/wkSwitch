const std = @import("std");

const jsmn = @cImport({
    @cDefine("JSMN_STRICT", "1");
    @cInclude("jsmn.h");
});

const JSONIterator = struct {};

pub fn parseJSON(allocator: std.mem.Allocator, json: []u8) JSONIterator {
    _ = json;
    _ = allocator;
    return .{};
}
