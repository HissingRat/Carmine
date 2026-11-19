const std = @import("std");
const serial = @import("../arch/x86_64/serial/uart16550.zig");

var format_buf: [256]u8 = undefined;

pub fn init() void {
    serial.init();
}

pub fn kprintf(comptime format: []const u8, args: anytype) void {
    const text = std.mem.print(&format_buf, format, args) catch {
        @panic("Kernel Panic: no memory left for formatting!");
    };
    write(text);
}

pub fn kprint(text: []const u8) void {
    write(text);
}

// 当前先输出到串口, TODO: 之后搞输出到屏幕或文件
fn write(text: []const u8) void {
    serial.write(text);
}
