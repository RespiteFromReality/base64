const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var memory_buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    const base64 = Base64.init();
    const text = "Testing some more stuff";
    const b64 = "VGVzdGluZyBzb21lIG1vcmUgc3R1ZmY=";
    const encoded_text = try base64.encode(allocator, text);
    const decoded_text = try base64.decode(allocator, b64);
    try stdout.print("Encoded text: {s}\n", .{encoded_text});
    try stdout.print("Decoded text: {s}\n", .{decoded_text});
    try stdout.flush();
}

const Base64 = struct {
    _table: *const [64]u8,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers_symb = "0123456789+/";
        return Base64{
            ._table = upper ++ lower ++ numbers_symb,
        };
    }

    pub fn charAt(self: Base64, index: usize) u8 {
        return self._table[index];
    }

    pub fn encode(self: Base64, alloc: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const length = try calcEncodeLength(input);
        var base64 = try alloc.alloc(u8, length);
        var buf = [3]u8{ 0, 0, 0 };
        var count: u8 = 0;
        var pos: u64 = 0;

        for (input) |char| {
            buf[count] = char;
            count += 1;

            if (count == 3) {
                base64[pos] = self.charAt(buf[0] >> 2);
                base64[pos + 1] = self.charAt(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
                base64[pos + 2] = self.charAt(((buf[1] & 0x0f) << 2) + (buf[2] >> 6));
                base64[pos + 3] = self.charAt(buf[2] & 0x3f);
                pos += 4;
                count = 0;
            }
        }

        if (count == 1) {
            base64[pos] = self.charAt(buf[0] >> 2);
            base64[pos + 1] = self.charAt((buf[0] & 0x03) << 4);
            base64[pos + 2] = '=';
            base64[pos + 3] = '=';
        }

        if (count == 2) {
            base64[pos] = self.charAt(buf[0] >> 2);
            base64[pos + 1] = self.charAt(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
            base64[pos + 2] = self.charAt((buf[1] & 0x0f) << 2);
            base64[pos + 3] = '=';
            pos += 4;
        }

        return base64;
    }
    pub fn decode(self: Base64, allocator: std.mem.Allocator, base64: []const u8) ![]u8 {
        if (base64.len == 0) {
            return "";
        }
        const length = try calcDecodeLength(base64);
        var output = try allocator.alloc(u8, length);
        var count: u8 = 0;
        var pos: u64 = 0;
        var buf = [4]u8{ 0, 0, 0, 0 };

        for (0..base64.len) |i| {
            buf[count] = self.charIndex(base64[i]);
            count += 1;
            if (count == 4) {
                output[pos] = (buf[0] << 2) + (buf[1] >> 4);
                if (buf[2] != 64) {
                    output[pos + 1] = (buf[1] << 4) + (buf[2] >> 2);
                }
                if (buf[3] != 64) {
                    output[pos + 2] = (buf[2] << 6) + buf[3];
                }
                pos += 3;
                count = 0;
            }
        }

        return output;
    }

    fn calcEncodeLength(input: []const u8) !usize {
        if (input.len < 3) {
            return 4;
        }
        const groups: usize = try std.math.divCeil(usize, input.len, 3);
        return groups * 4;
    }

    fn calcDecodeLength(input: []const u8) !usize {
        if (input.len < 4) {
            return 3;
        }

        const groups: usize = try std.math.divFloor(usize, input.len, 4);
        var byte_groups: usize = groups * 3;

        var i: usize = input.len - 1;
        while (i > 0) : (i -= 1) {
            if (input[i] == '=') {
                byte_groups -= 1;
            } else {
                break;
            }
        }

        return byte_groups;
    }

    fn charIndex(self: Base64, char: u8) u8 {
        if (char == '=')
            return 64;

        var out_index: u8 = 0;

        for (0..64) |index| {
            if (self.charAt(index) == char)
                break;
            out_index += 1;
        }

        return out_index;
    }
};
