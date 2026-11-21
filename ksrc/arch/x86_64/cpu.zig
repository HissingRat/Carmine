const PerCpuGdt = @import("percpu/gdt.zig").PerCpuGdt;
const PerCpuTss = @import("percpu/tss.zig").PerCpuTss;
const limine = @import("../../boot/limine.zig");
const bootInfo = @import("../../boot/boot.zig").bootInfo;
const logger = @import("../../log/klogger.zig");
const kopts = @import("../../koptions.zig");

const Cpu = struct {
    index: usize,
    lapic_id: u32,

    gdt: PerCpuGdt,
    tss: PerCpuTss,

    kernel_stack: [kopts.KERNEL_STACK_SIZE]u8,
    interrupt_stack: [kopts.INT_STACK_SIZE]u8,

    //加scheduler之类的
};

const max_cups: u32 = 16;
var cpus: [max_cups]Cpu = undefined; //TODO: 等内存管理完工后换成动态分配
var cpu_count: usize = 0;

pub fn init(boot_info: bootInfo) void {
    if (boot_info.mp) |mp|
        start_aps(mp);
    logger.kprintf("Detected {d} cpus.\n", .{cpu_count});
}

fn start_aps(response: *const limine.MpResponse) void {
    const cpu_infos = response.cpus[0..response.cpu_count];

    for (cpu_infos, 0..) |cpu_info, index| {
        if (index >= max_cups) @panic("TOO MANY CPUS");

        const cur_cpu = init_percpu(index, cpu_info.lapic_id);
        cpu_count += 1;

        if (cpu_info.lapic_id == response.bsp_lapic_id) {
            cur_cpu.gdt.init_gdt(&cur_cpu.tss);
            continue;
        }

        cpu_info.extra_args = @intFromPtr(cur_cpu);

        @atomicStore(
            u64,
            &cpu_info.goto_addr,
            @intFromPtr(&ap_entry),
            .release,
        );
    }
}

fn init_percpu(index: usize, lapic_id: u32) *Cpu {
    const cpu = &cpus[index];
    cpu.* = .{
        .index = index,
        .lapic_id = lapic_id,
        .gdt = .{},
        .tss = .{},
        .kernel_stack = undefined,
        .interrupt_stack = undefined,
    };
    cpu.tss.rsp0 = @intFromPtr(&cpu.kernel_stack) + kopts.KERNEL_STACK_SIZE;
    cpu.tss.ist1 = @intFromPtr(&cpu.interrupt_stack) + kopts.INT_STACK_SIZE;
    return cpu;
}

fn ap_entry(info: *limine.MpInfo) callconv(.c) noreturn {
    const cur_cpu: *Cpu = @ptrFromInt(info.extra_args);
    cur_cpu.gdt.init_gdt(&cur_cpu.tss);
    // TODO: 接入每个核心的调度器
    @import("cpuio.zig").halt();
}
