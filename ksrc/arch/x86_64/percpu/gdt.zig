/// GDT 设计参考 https://wiki.osdev.org/Global_Descriptor_Table
/// GDT Long Mode setup参考 https://wiki.osdev.org/GDT_Tutorial#What_to_Put_In_a_GDT
const PerCpuTss = @import("tss.zig").PerCpuTss;

const GdtEntry = packed struct(u64) {
    limit_low: u16,
    base_low: u16,
    base_mid: u8,
    access_byte: u8,
    limit_high: u4,
    flags: u4,
    base_high: u8,
};

const TssEntry = extern struct {
    gdt: GdtEntry,
    base_upper: u32,
    reserved: u32 = 0,
};

const Gdtr = packed struct {
    size: u16,
    addr: u64,
};

const GdtTable = extern struct {
    empty: GdtEntry,
    kernel_code: GdtEntry,
    kernel_data: GdtEntry,
    user_data: GdtEntry,
    user_code: GdtEntry,
    tss: TssEntry,
};

pub const PerCpuGdt = struct {
    gdt_table: GdtTable = undefined,

    pub fn initGdt(this: *PerCpuGdt, tss: *PerCpuTss) void {
        createGdt(&this.gdt_table.empty, 0, 0x00000, 0x00, 0x0);
        createGdt(&this.gdt_table.kernel_code, 0, 0xFFFFF, 0x9A, 0xA);
        createGdt(&this.gdt_table.kernel_data, 0, 0xFFFFF, 0x92, 0xC);
        createGdt(&this.gdt_table.user_data, 0, 0xFFFFF, 0xF2, 0xC);
        createGdt(&this.gdt_table.user_code, 0, 0xFFFFF, 0xFA, 0xA);
        createTss(&this.gdt_table.tss, @intFromPtr(tss), @sizeOf(PerCpuTss) - 1, 0x89, 0x0);
        this.lgdt();
        reloadSegments();
        loadTaskRegister();
    }

    fn lgdt(this: *PerCpuGdt) void {
        const gdtr_ptr: Gdtr = .{
            .size = @sizeOf(@TypeOf(this.gdt_table)) - 1,
            .addr = @intFromPtr(&this.gdt_table),
        };
        asm volatile (
            \\lgdt (%[ptr])
            :
            : [ptr] "r" (&gdtr_ptr),
            : .{ .memory = true });
    }
};

fn createGdt(entry: *GdtEntry, base: u64, limit: u20, access: u8, flags: u4) void {
    entry.* = .{
        .limit_low = @truncate(limit),
        .base_low = @truncate(base),
        .base_mid = @truncate(base >> 16),
        .access_byte = access,
        .limit_high = @truncate(limit >> 16),
        .flags = flags,
        .base_high = @truncate(base >> 24),
    };
}

fn createTss(entry: *TssEntry, base: u64, limit: u20, access: u8, flags: u4) void {
    entry.* = .{
        .gdt = .{
            .limit_low = @truncate(limit),
            .base_low = @truncate(base),
            .base_mid = @truncate(base >> 16),
            .access_byte = access,
            .limit_high = @truncate(limit >> 16),
            .flags = flags,
            .base_high = @truncate(base >> 24),
        },
        .base_upper = @truncate(base >> 32),
    };
}

fn loadTaskRegister() void {
    const offset: u16 = @offsetOf(GdtTable, "tss");
    asm volatile ("ltr %[selector]"
        :
        : [selector] "r" (offset),
        : .{ .memory = true });
}

extern fn reloadSegments() callconv(.c) void;

comptime {
    asm (
        \\.global reloadSegments
        \\.type reloadSegments, @function
        \\reloadSegments:
        \\  pushq $0x08
        \\  leaq 1f(%rip), %rax
        \\  pushq %rax
        \\  lretq
        \\1:
        \\  movw $0x10, %ax
        \\  movw %ax, %ds
        \\  movw %ax, %es
        \\  movw %ax, %ss
        \\  retq
    );
}
