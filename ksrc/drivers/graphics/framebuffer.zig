const limine = @import("../../boot/limine.zig");
const logger = @import("../../log/klogger.zig");

const fb = struct {
    pixels: [*]volatile u32,
    width: usize,
    height: usize,

    stride: usize,

    red_shift: u5,
    green_shift: u5,
    blue_shift: u5,

    pub fn rgb(this: *const fb, red: u8, green: u8, blue: u8) u32 {
        return @as(u32, red) << this.red_shift |
            @as(u32, green) << this.green_shift |
            @as(u32, blue) << this.blue_shift;
    }

    pub fn putPixel(this: *const fb, x: usize, y: usize, color: u32) void {
        if (x > this.width or y > this.height)
            return;
        this.pixels[y * this.stride + x] = color;
    }
};

pub fn init(info: *const limine.Framebuffer) fb {
    logger.kprintf("framebuffer:\n width: {d}\n height: {d}\n", .{
        info.width,
        info.height,
    });

    return .{
        .pixels = @ptrCast(@alignCast(info.address)),
        .width = info.width,
        .height = info.height,
        .stride = info.pitch / 4,
        .red_shift = @intCast(info.red_mask_shift),
        .green_shift = @intCast(info.green_mask_shift),
        .blue_shift = @intCast(info.blue_mask_shift),
    };
}
