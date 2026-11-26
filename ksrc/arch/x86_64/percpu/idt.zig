/// IDT https://wiki.osdev.org/Interrupt_Descriptor_Table
const isrs = @import("interrupts/isrs.zig");

comptime {
    _ = @import("interrupts/Interrupts.zig");
}

const IdtEntry = packed struct {
    offset1: u16,
    selector: u16 = 0x08,
    ist: u3,
    reserved0: u5 = 0,
    gate_type: u4,
    zero: u1 = 0,
    dpl: u2,
    p: u1 = 1,
    offset2: u16,
    offset3: u32,
    reserved1: u32 = 0,
};

const Idtr = packed struct {
    size: u16,
    addr: u64,
};

pub const PerCpuIdt = struct {
    idt_table: [isrs.isr_table_size]IdtEntry = undefined,

    pub fn initIdt(this: *PerCpuIdt) void {
        for (0..isrs.isr_table_size) |vec| {
            this.idt_table[vec] = createIdt(
                isrs.isr_table[vec],
                isrs.gateType(vec),
                isrs.ist(vec),
                0x00,
            );
        }
        this.lidt();
    }

    fn lidt(this: *PerCpuIdt) void {
        const idtr_ptr: Idtr = .{
            .size = @sizeOf(@TypeOf(this.idt_table)) - 1,
            .addr = @intFromPtr(&this.idt_table),
        };
        asm volatile (
            \\lidt (%[ptr])
            :
            : [ptr] "r" (&idtr_ptr),
            : .{ .memory = true });
    }
};

fn createIdt(addr: usize, gate_type: u4, ist: u3, dpl: u2) IdtEntry {
    return .{
        .offset1 = @truncate(addr),
        .offset2 = @truncate(addr >> 16),
        .offset3 = @truncate(addr >> 32),
        .gate_type = gate_type,
        .ist = ist,
        .dpl = dpl,
    };
}
