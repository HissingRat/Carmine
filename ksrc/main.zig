const boot = @import("boot/boot.zig");
const cpu = @import("arch/x86_64/cpu.zig");
const framebuffer = @import("drivers/graphics/framebuffer.zig");
const logger = @import("log/klogger.zig");

export fn _start() callconv(.c) noreturn {
    cpu.disableInterrupts();
    logger.init();
    logger.kprint("loading Carmine 0.0.1");

    const boot_info = boot.init();

    const fb = framebuffer.init(boot_info.framebuffer);
    const blue = fb.rgb(30, 120, 255);

    for (0..fb.height) |y| {
        for (0..fb.width) |x| {
            fb.putPixel(x, y, blue);
        }
    }

    logger.kprint("Carmine loaded");
    cpu.halt();
}
