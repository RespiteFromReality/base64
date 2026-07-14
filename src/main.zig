const std = @import("std");
const Base64 = @import("base64.zig").Base64;

const Mode = enum {
    unset,
    encode,
    decode,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena: std.mem.Allocator = init.arena.allocator();

    // Args
    var mode: Mode = .unset;
    const args = try init.minimal.args.toSlice(arena);
    if (std.mem.startsWith(u8, args[1], "-e") or std.mem.startsWith(u8, args[1], "--encode")) {
        mode = .encode;
    } else if (std.mem.startsWith(u8, args[1], "-d") or std.mem.startsWith(u8, args[1], "--decode")) {
        mode = .decode;
    }
    const input: []const u8 = args[2];

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    const base64 = Base64.init();
    switch (mode) {
        .encode => {
            const encoded = try base64.encode(arena, input);
            try stdout.print("Encoded Base64 output for \"{s}\":\n", .{input});
            try stdout.print("{s}\n", .{encoded});
            try stdout.flush();
        },
        .decode => {
            const decoded = try base64.decode(arena, input);
            try stdout.print("Decoded Base64 output for \"{s}\":\n", .{input});
            try stdout.print("{s}\n", .{decoded});
            try stdout.flush();
        },
        else => return,
    }
}
