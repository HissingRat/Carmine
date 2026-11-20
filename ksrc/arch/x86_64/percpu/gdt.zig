/// x86_64 global descriptor table
/// GTD设计参考 https://wiki.osdev.org/Global_Descriptor_Table
/// GDT Long Mode setup参考 https://wiki.osdev.org/GDT_Tutorial#What_to_Put_In_a_GDT
const GdtEntry = packed struct {
    limit_low: u16,
    base_low: u16,
    base_mid: u8,
    access_byte: u8,
    limit_high: u4,
    flags: u4,
    base_high: u8,
};

const Gdtr = packed struct {
    size: u16,
    addr: u64,
};

pub const PerCpuGdt = struct {
    gdt_table: [6]GdtEntry = undefined,

    pub fn init_gdt(this: *PerCpuGdt) void {
        this.create_gdt(0, 0, 0x00000, 0x00, 0x0);
        this.create_gdt(1, 0, 0xFFFFF, 0x9A, 0xA); // Kernel Mode Code Segment
        this.create_gdt(2, 0, 0xFFFFF, 0x92, 0xC); // Kernel Mode Data Segment
        this.create_gdt(3, 0, 0xFFFFF, 0xF2, 0xC); // User Mode Data Segment
        this.create_gdt(4, 0, 0xFFFFF, 0xFA, 0xA); // User Mode Code Segment
        this.create_gdt(5, 0, 0, 0, 0); // 给TSS占位, 加TSS之后删掉这行
        // create_gdt(5, &tss, sizeOf(tss) - 1, 0x89, 0x0) // TODO: 64位 Task State Segment
        this.lgdt();
        reload_segments();
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

    fn create_gdt(this: *PerCpuGdt, index: usize, base: u32, limit: u20, access: u8, flags: u4) void {
        this.gdt_table[index] = .{
            .limit_low = @truncate(limit),
            .base_low = @truncate(base),
            .base_mid = @truncate(base >> 16),
            .access_byte = access,
            .limit_high = @truncate(limit >> 16),
            .flags = flags,
            .base_high = @truncate(base >> 24),
        };
    }
};

extern fn reload_segments() callconv(.c) void;

comptime {
    asm (
        \\.global reload_segments
        \\.type reload_segments, @function
        \\reload_segments:
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
