const boot = @import("boot/boot.zig");
const cpuio = @import("arch/x86_64/cpuio.zig");
const framebuffer = @import("drivers/graphics/framebuffer.zig");
const logger = @import("log/klogger.zig");
const cpu = @import("arch/x86_64/cpu.zig");
const mem_early = @import("mem/early.zig");

export fn _start() callconv(.c) noreturn {
    cpuio.disableInterrupts();
    cpu.initBsp();
    logger.init();
    const boot_info = boot.init();

    const time_ = boot_info.startup_time;
    if (time_) |time| {
        logger.kprintf(
            "Entered kernel at UTC {d}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}\n",
            .{ time.year, time.month, time.day, time.hour, time.minute, time.second },
        );
    } else logger.kprint("unable to get startup time\n");
    logger.kprint("loading Carmine 0.0.1\n");

    mem_early.init(boot_info);
    cpu.init(boot_info);

    asm volatile ("int3");
    // @panic("test panic");

    const fb = framebuffer.init(boot_info.framebuffer);
    const blue = fb.rgb(30, 120, 255);

    for (0..fb.height) |y| {
        for (0..fb.width) |x| {
            fb.putPixel(x, y, blue);
        }
    }

    logger.kprint("Carmine loaded.\n");
    cpuio.halt();
}

pub const panic = @import("std").debug.FullPanic(kernelPanic);

fn kernelPanic(msg: []const u8, _: ?usize) noreturn {
    cpuio.disableInterrupts();
    logger.kprint("Kernel panic: ");
    logger.kprint(msg);
    logger.kprint("\n");
    cpuio.halt();
}
