const io = @import("../cpuio.zig");

const com1: u16 = 0x3f8;

pub fn init() void {
    io.outb(com1 + 1, 0x00); // Disable UART interrupts.
    io.outb(com1 + 3, 0x80); // Divisor latch access.
    io.outb(com1 + 0, 0x01); // 115200 baud.
    io.outb(com1 + 1, 0x00);
    io.outb(com1 + 3, 0x03); // 8 data bits, no parity, 1 stop bit.
    io.outb(com1 + 2, 0xc7); // Enable and clear FIFOs.
    io.outb(com1 + 4, 0x03); // DTR and RTS.
}

fn writeByte(byte: u8) void {
    // Bound the wait so a missing UART cannot trap the panic path forever.
    var attempts: usize = 0;
    while (io.inb(com1 + 5) & 0x20 == 0) : (attempts += 1) {
        if (attempts == 100_000) return;
        asm volatile ("pause");
    }
    io.outb(com1, byte);
}

pub fn write(text: []const u8) void {
    for (text) |byte| {
        if (byte == '\n') writeByte('\r');
        writeByte(byte);
    }
}

pub fn writeHex(value: u64) void {
    const digits = "0123456789abcdef";
    var buffer: [18]u8 = undefined;
    buffer[0..2].* = "0x".*;
    for (0..16) |index| {
        const shift: u6 = @intCast((15 - index) * 4);
        buffer[index + 2] = digits[@intCast((value >> shift) & 0xf)];
    }
    write(&buffer);
}

pub fn readable() bool {
    return io.inb(com1 + 5) & 1 != 0;
}
pub fn tryRead() ?u8 {
    return if (readable()) io.inb(com1) else null;
}
