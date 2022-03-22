const std = @import("std");

test {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const expect = std.testing.expect;
    const Place = struct { lat: f32, long: f32, garbage: []struct{id: usize} };

    var stream = std.json.TokenStream.init(
        \\{ "lat": 40.684540, "long": -74.401422, "garbage": [ {"id": 1}, {"id": 2} ] }
    );
    const x = try std.json.parse(Place, &stream, .{ .allocator = arena.allocator(), .ignore_unknown_fields = true});

    try expect(x.lat == 40.684540);
    try expect(x.long == -74.401422);
}


// test allocator is allotted twice the memory it needs to operate
test "i3-workspaces-parse" {
    var buffer: [700]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // const expect = std.testing.expect;

    var stream = std.json.TokenStream.init(
        \\[
        \\ {
        \\  "num": 0,
        \\  "name": "1",
        \\  "visible": true,
        \\  "focused": true,
        \\  "urgent": false,
        \\  "rect": {
        \\   "x": 0,
        \\   "y": 0,
        \\   "width": 1280,
        \\   "height": 800
        \\  },
        \\  "output": "LVDS1"
        \\ },
        \\ {
        \\  "num": 1,
        \\  "name": "2",
        \\  "visible": false,
        \\  "focused": false,
        \\  "urgent": false,
        \\  "rect": {
        \\   "x": 0,
        \\   "y": 0,
        \\   "width": 1280,
        \\   "height": 800
        \\  },
        \\  "output": "LVDS1"
        \\ }
        \\]
    );
    const x = try std.json.parse(I3Workspaces, &stream, .{ .allocator = allocator, .ignore_unknown_fields = true});
    defer std.json.parseFree(I3Workspaces, x, .{ .allocator = allocator });
    std.debug.print("{s}\n", .{x});
}

// test allocator is allotted twice the memory it needs to operate
test "i3-tree-parse" {
    var buffer: [1400]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // const expect = std.testing.expect;

    var stream = std.json.TokenStream.init(
        \\{
        \\ "id": 6875648,
        \\ "name": "root",
        \\ "rect": {
        \\   "x": 0,
        \\   "y": 0,
        \\   "width": 1280,
        \\   "height": 800
        \\ },
        \\ "nodes": [
        \\
        \\   {
        \\    "id": 6878320,
        \\    "name": "LVDS1",
        \\    "layout": "output",
        \\    "rect": {
        \\      "x": 0,
        \\      "y": 0,
        \\      "width": 1280,
        \\      "height": 800
        \\    },
        \\    "nodes": [
        \\
        \\      {
        \\       "id": 6878784,
        \\       "name": "topdock",
        \\       "layout": "dockarea",
        \\       "orientation": "vertical",
        \\       "rect": {
        \\         "x": 0,
        \\         "y": 0,
        \\         "width": 1280,
        \\         "height": 0
        \\       }
        \\      },
        \\
        \\      {
        \\       "id": 6879344,
        \\       "name": "content",
        \\       "rect": {
        \\         "x": 0,
        \\         "y": 0,
        \\         "width": 1280,
        \\         "height": 782
        \\       },
        \\       "nodes": [
        \\
        \\         {
        \\          "id": 6880464,
        \\          "name": "1",
        \\          "orientation": "horizontal",
        \\          "rect": {
        \\            "x": 0,
        \\            "y": 0,
        \\            "width": 1280,
        \\            "height": 782
        \\          },
        \\          "window_properties": {
        \\            "class": "Evince",
        \\            "instance": "evince",
        \\            "title": "Properties",
        \\            "transient_for": 52428808
        \\          },
        \\          "floating_nodes": [],
        \\          "nodes": [
        \\
        \\            {
        \\             "id": 6929968,
        \\             "name": "#aa0000",
        \\             "border": "normal",
        \\             "percent": 1,
        \\             "rect": {
        \\               "x": 0,
        \\               "y": 18,
        \\               "width": 1280,
        \\               "height": 782
        \\             }
        \\            }
        \\
        \\          ]
        \\         }
        \\
        \\       ]
        \\      },
        \\
        \\      {
        \\       "id": 6880208,
        \\       "name": "bottomdock",
        \\       "layout": "dockarea",
        \\       "orientation": "vertical",
        \\       "rect": {
        \\         "x": 0,
        \\         "y": 782,
        \\         "width": 1280,
        \\         "height": 18
        \\       },
        \\       "nodes": [
        \\
        \\         {
        \\          "id": 6931312,
        \\          "name": "#00aa00",
        \\          "percent": 1,
        \\          "rect": {
        \\            "x": 0,
        \\            "y": 782,
        \\            "width": 1280,
        \\            "height": 18
        \\          }
        \\         }
        \\
        \\       ]
        \\      }
        \\    ]
        \\   }
        \\ ]
        \\}
    );
    const T = I3Tree;
    const x = try std.json.parse(T, &stream, .{ .allocator = allocator, .ignore_unknown_fields = true});
    defer std.json.parseFree(T, x, .{ .allocator = allocator });
    std.debug.print("{s}\n", .{x.nodes[0].nodes});
}

const err = std.io.getStdErr().writer();

fn errPrint(comptime fmt: []const u8, args: anytype) void {
    err.print(fmt, args) catch {};
    err.print("\n", .{}) catch {};
}

const Workspace = struct {
    name: []const u8,
    nodes: ?[]struct {
        id: usize,
    } = null,
};

const Output = struct {
    name: []const u8,
    nodes: []Workspace,
};

const I3Tree = struct {
    nodes: []Output,
};

const I3Workspaces = []struct {
    output: []const u8,
    name: []const u8,
    visible: bool,
    focused: bool,
};

fn foo(s: []const u8) void {
    for (s) |v| {
        std.debug.print("{d}\n", .{v});
    }
}

fn rawByteLen(comptime T: type) usize {
    return std.math.divExact(usize, @bitSizeOf(T), 8) catch @compileError("Type's bitsize must be divisible by 8");
}

fn asConstByteArray(comptime T: type, v: *T) *const [rawByteLen(T)]u8 {
    return @ptrCast(*[rawByteLen(T)]u8, v);
}

fn asByteArray(comptime T: type, v: *T) *[rawByteLen(T)]u8 {
    return @ptrCast(*[rawByteLen(T)]u8, v);
}

fn socketErrorToInt(sock_err: SocketError) u8 {
    return switch (sock_err) {
        SocketError.BadVariable => 1,
        SocketError.BadSocket => 2,
        SocketError.ReadFail => 3,
        SocketError.WriteFail => 4,
        SocketError.MsgTooLong => 5,
        SocketError.ResourceFailure => 6,
        SocketError.ProtocolFailure => 7,
    };
}

const SocketError = error{
    BadVariable,
    BadSocket,
    ReadFail,
    WriteFail,
    MsgTooLong,
    ResourceFailure,
    ProtocolFailure,
};

const I3IPC = struct {
    fd: i32,

    fn init() SocketError!I3IPC {
        const sock_variable = "I3SOCK";
        const sock_path = std.os.getenv(sock_variable) orelse {
            errPrint("Environment variable '{s}' unavailable.", .{sock_variable});
            return error.BadVariable;
        };
    
        var addr: std.os.sockaddr.un = .{ .path = undefined };
        std.mem.set(u8, &addr.path, 0);
        if(sock_path.len >= addr.path.len-1) {
            errPrint("Sock variable '{s}' is longer than the maximum path length, {}", .{sock_variable, addr.path.len-1});
            return error.BadVariable;
        }
        std.mem.copy(u8, &addr.path, sock_path);
    
        const sock = std.os.socket(std.os.AF.UNIX, std.os.SOCK.STREAM, 0) catch {
            errPrint("Failed to open socket", .{});
            return error.BadSocket;
        };
        std.os.connect(sock, @ptrCast(*std.os.sockaddr, &addr), @sizeOf(@TypeOf(addr))) catch |err| {
            errPrint("Failed to connect to socket: {s}", .{err});
            return error.BadSocket;
        };
    
        return I3IPC{ .fd = sock };
    }

    fn writeError() SocketError {
        errPrint("Failed to write to socket", .{});
        return SocketError.WriteFail;
    }
    fn readError() SocketError {
        errPrint("Failed to read from socket", .{});
        return SocketError.ReadFail;
    }
    fn request(self: I3IPC, allocator: std.mem.Allocator, msg_type: u32, msg: []u8) SocketError![]u8 {
        var magic = "i3-ipc";
        const Header = packed struct {
            magic: [6]u8,
            len: u32,
            msg_type: u32,

            fn len() usize {
                return 14;
            }
        };
        if(msg.len > std.math.maxInt(i32))
            return error.MsgTooLong;
        var h = Header {
            .magic = magic.*,
            .len = @intCast(u32, msg.len),
            .msg_type = msg_type,
        };

        _ = std.os.write(self.fd, asConstByteArray(@TypeOf(h), &h)) catch return writeError();
        if(msg.len > 0)
            _ = std.os.write(self.fd, msg) catch return writeError();
        
        _ = std.os.read(self.fd, asByteArray(@TypeOf(h), &h)) catch return readError();
        if(!std.mem.eql(u8, &h.magic, magic)) {
            // errPrint("Received incorrect magic.", .{});
            // return error.ProtocolFailure;
        }
        if(h.len > 0) {
            var response: []u8 = allocator.alloc(u8, h.len) catch return error.ResourceFailure;
            _ = std.os.read(self.fd, response) catch return readError();
            return response;
        }

        return &[0]u8{};
    }
};


pub fn main() u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const ipc = I3IPC.init() catch |err| return socketErrorToInt(err);

    var response = ipc.request(allocator, 4, &[0]u8{}) catch |err| return socketErrorToInt(err);
    var stream = std.json.TokenStream.init(response);
    const tree = std.json.parse(I3Tree, &stream, .{ .allocator = allocator, .ignore_unknown_fields = true}) catch {
        errPrint("Failed to parse tree json.", .{});
        return 100;
    };
    response = ipc.request(allocator, 1, &[0]u8{}) catch |err| return socketErrorToInt(err);
    stream = std.json.TokenStream.init(response);
    const ws = std.json.parse(I3Workspaces, &stream, .{ .allocator = allocator, .ignore_unknown_fields = true}) catch {
        errPrint("Failed to parse workspace json.", .{});
        return 100;
    };
    
    _ = tree;
    _ = ws;

    return 0;
}
