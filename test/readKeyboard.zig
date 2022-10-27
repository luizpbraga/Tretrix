const std = @import("std");
const fs = std.fs;
const io = std.io;
const os = std.os;
const mem = std.mem;
const debug = std.debug;

pub fn main() !void {
    var tty = try fs.cwd().openFile("/dev/tty", .{});
    //var tty = try fs.cwd().openFile("/dev/tty", .{ .read = true, .write = true });
    defer tty.close();

    const original = try os.tcgetattr(tty.handle);
    var raw = original;
    raw.lflag &= ~@as(
        os.linux.tcflag_t,
        os.linux.ECHO | os.linux.ICANON | os.linux.ISIG | os.linux.IEXTEN,
    );
    raw.iflag &= ~@as(
        os.linux.tcflag_t,
        os.linux.IXON | os.linux.ICRNL | os.linux.BRKINT | os.linux.INPCK | os.linux.ISTRIP,
    );
    raw.cc[os.system.V.TIME] = 0;
    raw.cc[os.system.V.MIN] = 1;
    try os.tcsetattr(tty.handle, .FLUSH, raw);

    while (true) {
        var buffer: [1]u8 = undefined;
        _ = try tty.read(&buffer);
        if (buffer[0] == 'q') {
            try os.tcsetattr(tty.handle, .FLUSH, original);
            return;
        } else if (buffer[0] == '\x1B') {
            debug.print("input: escape\r\n", .{});
        } else if (buffer[0] == '\n' or buffer[0] == '\r') {
            debug.print("input: return\r\n", .{});
        } else {
            debug.print("input: {} {s}\r\n", .{ buffer[0], buffer });
        }
    }

    var buffer: [1]u8 = undefined;
    _ = try tty.read(&buffer);
    switch (buffer[0]) {
        'q' => return,
        'l' => std.debug.print("l", .{}),
        'h' => std.debug.print("l", .{}),
        else => return,
    }
}
