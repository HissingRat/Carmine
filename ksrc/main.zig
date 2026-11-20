const boot = @import("boot/boot.zig");
const cpuio = @import("arch/x86_64/cpuio.zig");
const framebuffer = @import("drivers/graphics/framebuffer.zig");
const logger = @import("log/klogger.zig");
const cpu = @import("arch/x86_64/cpu.zig");

export fn _start() callconv(.c) noreturn {
    cpuio.disableInterrupts();
    logger.init();
    logger.kprint("loading Carmine 0.0.1\n");

    const boot_info = boot.init();

    cpu.init(boot_info);

    const fb = framebuffer.init(boot_info.framebuffer);
    const blue = fb.rgb(30, 120, 255);

    for (0..fb.height) |y| {
        for (0..fb.width) |x| {
            fb.putPixel(x, y, blue);
        }
    }

    logger.kprint("Carmine loaded");
    cpuio.halt();
}
