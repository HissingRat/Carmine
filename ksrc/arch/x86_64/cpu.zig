const PerCpuGdt = @import("percpu/gdt.zig").PerCpuGdt;
const PerCpuTss = @import("percpu/tss.zig").PerCpuTss;
const PerCpuIdt = @import("percpu/idt.zig").PerCpuIdt;
const limine = @import("../../boot/limine.zig");
const bootInfo = @import("../../boot/boot.zig").bootInfo;
const logger = @import("../../log/klogger.zig");
const kopts = @import("../../koptions.zig");

const Cpu = struct {
    index: usize,
    lapic_id: u32,

    gdt: PerCpuGdt,
    tss: PerCpuTss,
    idt: PerCpuIdt,

    kernel_stack: [kopts.KERNEL_STACK_SIZE]u8,
    interrupt_stacks: [7][kopts.INT_STACK_SIZE]u8,

    //加scheduler之类的
};

const max_cups: u32 = 16;
var cpus: [max_cups]Cpu = undefined; //TODO: 等内存管理完工后换成动态分配
var cpu_count: usize = 0;

pub fn init(info: bootInfo) void {
    if (info.mp) |mp|
        startAps(mp);
    logger.kprintf("Detected {d} cpus.\n", .{cpu_count});
}

pub fn initBsp() void {
    const cur_cpu = initPerCpu(0, 0);
    cur_cpu.gdt.initGdt(&cur_cpu.tss);
    cur_cpu.idt.initIdt();
    cpu_count += 1;
}

fn startAps(response: *const limine.MpResponse) void {
    const cpu_infos = response.cpus[0..response.cpu_count];

    var index: usize = 1;
    for (cpu_infos) |cpu_info| {
        if (index >= max_cups) @panic("TOO MANY CPUS");

        if (cpu_info.lapic_id == response.bsp_lapic_id) {
            cpus[0].lapic_id = cpu_info.lapic_id;
            continue;
        }

        const cur_cpu = initPerCpu(index, cpu_info.lapic_id);
        cpu_count += 1;
        index += 1;

        cpu_info.extra_args = @intFromPtr(cur_cpu);

        @atomicStore(
            u64,
            &cpu_info.goto_addr,
            @intFromPtr(&apEntry),
            .release,
        );
    }
}

fn initPerCpu(index: usize, lapic_id: u32) *Cpu {
    const cpu = &cpus[index];
    cpu.* = .{
        .index = index,
        .lapic_id = lapic_id,
        .gdt = .{},
        .tss = .{},
        .idt = .{},
        .kernel_stack = undefined,
        .interrupt_stacks = undefined,
    };
    cpu.tss.rsp0 = @intFromPtr(&cpu.kernel_stack) + kopts.KERNEL_STACK_SIZE;
    const stacks = &cpu.interrupt_stacks;
    cpu.tss.ist1 = @intFromPtr(&stacks[0]) + stacks[0].len;
    cpu.tss.ist2 = @intFromPtr(&stacks[1]) + stacks[1].len;
    cpu.tss.ist3 = @intFromPtr(&stacks[2]) + stacks[2].len;
    cpu.tss.ist4 = @intFromPtr(&stacks[3]) + stacks[3].len;
    cpu.tss.ist5 = @intFromPtr(&stacks[4]) + stacks[3].len;
    cpu.tss.ist6 = @intFromPtr(&stacks[5]) + stacks[3].len;
    cpu.tss.ist7 = @intFromPtr(&stacks[6]) + stacks[3].len;
    return cpu;
}

fn apEntry(info: *limine.MpInfo) callconv(.c) noreturn {
    const cur_cpu: *Cpu = @ptrFromInt(info.extra_args);
    cur_cpu.gdt.initGdt(&cur_cpu.tss);
    cur_cpu.idt.initIdt();
    // TODO: 接入每个核心的调度器
    @import("cpuio.zig").halt();
}
