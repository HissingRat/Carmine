const klogger = @import("../../../../log/klogger.zig");
const cpuio = @import("../../cpuio.zig");

// 按 interrupt.asm 里面pop的顺序读取所有寄存器
const InterruptFrame = extern struct {
    r15: u64,
    r14: u64,
    r13: u64,
    r12: u64,
    r11: u64,
    r10: u64,
    r9: u64,
    r8: u64,
    rsi: u64,
    rdi: u64,
    rbp: u64,
    rdx: u64,
    rcx: u64,
    rbx: u64,
    rax: u64,

    vector: u64,
    error_code: u64,

    rip: u64,
    cs: u64,
    rflags: u64,
    rsp: u64,
    ss: u64,
};

export fn interruptDispatch(frame: *const InterruptFrame) callconv(.c) void {
    switch (frame.vector) {
        3 => {
            klogger.kprint("detected int3!!!!\n");
            return;
        },
        14 => {
            const cr2 = asm volatile ("mov %%cr2, %[value]"
                : [value] "=r" (-> u64),
            );
            klogger.kprintf(
                "Page Fault: RIP=0x{x}, CR2=0x{x}, error=0x{x}",
                .{ frame.rip, cr2, frame.error_code },
            );
            cpuio.halt(); // TODO: 之后做一个修复页表
        },
        else => {
            klogger.kprintf(
                "CPU Exception {d}: RIP=0x{x}, error=0x{x}",
                .{ frame.vector, frame.rip, frame.error_code },
            );
            cpuio.halt();
        },
    }
}
