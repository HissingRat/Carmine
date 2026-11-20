pub inline fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]"
        :
        : [value] "{al}" (value),
          [port] "{dx}" (port),
    );
}

pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[value]"
        : [value] "={al}" (-> u8),
        : [port] "{dx}" (port),
    );
}

pub inline fn halt() noreturn {
    asm volatile ("cli");
    while (true) asm volatile ("hlt");
}

pub inline fn disableInterrupts() void {
    asm volatile ("cli" ::: .{ .memory = true });
}

pub inline fn enableInterrputs() void {
    asm volatile ("sti" ::: .{ .memory = true });
}

pub inline fn enableAndHalt() void {
    asm volatile (
        \\sti
        \\hlt
        ::: .{ .memory = true });
}
