//! Minimal native Zig declarations for the pinned Limine boot protocol.
//! Only add features here when the kernel starts using them; no libc is needed.
//! Reference: https://github.com/Limine-Bootloader/limine-protocol/blob/trunk/PROTOCOL.md

pub const base_revision: u64 = 6;
pub const requests_start: [4]u64 = .{
    0xf6b8f4b39de7d1ae, 0xfab91a6940fcb9cf,
    0x785c6ed015d3e316, 0x181e920a7852b9d9,
};
pub const requests_end: [2]u64 = .{ 0xadc0e0531bb10d03, 0x9572709f31764c62 };
pub const revision_tag: [3]u64 = .{ 0xf9562b2d5c95a6c8, 0x6a7b384944536bdc, base_revision };

pub fn Request(comptime Response: type) type {
    return extern struct {
        id: [4]u64,
        revision: u64 = 0,
        response: ?*const Response = null,
    };
}

pub const boot_date_id: [4]u64 = .{
    0xc7b1dd30df4c8b88, 0x0a82e883a194f07b,
    0x502746e184c088aa, 0xfbc5ec83e6327893,
};

pub const stack_size_id: [4]u64 = .{
    0xc7b1dd30df4c8b88, 0x0a82e883a194f07b,
    0x224ef0460a8e8926, 0xe1cb0fc25f46ea3d,
};

pub const memory_map_id: [4]u64 = .{
    0xc7b1dd30df4c8b88, 0x0a82e883a194f07b,
    0x67cf3d9d378a806f, 0xe304acdfc50c3c62,
};
pub const hhdm_id: [4]u64 = .{
    0xc7b1dd30df4c8b88, 0x0a82e883a194f07b,
    0x48dcf1cb8ad2b852, 0x63984e959a98244b,
};

pub const framebuffer_id: [4]u64 = .{
    0xc7b1dd30df4c8b88, 0x0a82e883a194f07b,
    0x9d5827dcd881dd75, 0xa3148604f6fab11b,
};

pub const module_id: [4]u64 = .{
    0xc7b1dd30df4c8b88, 0x0a82e883a194f07b,
    0x3e7e279702be32af, 0xca1c4f3bd1280cee,
};

pub const stackSizeResponse = extern struct {
    revision: u64,
};

pub const stackSizeRequest = extern struct {
    id: [4]u64 = stack_size_id,
    revision: u64 = 0,
    response: ?*const stackSizeResponse = null,
    stack_size: u64,
};

pub const MemoryType = enum(u64) {
    usable = 0,
    reserved = 1,
    acpi_reclaimable = 2,
    acpi_nvs = 3,
    bad_memory = 4,
    bootloader_reclaimable = 5,
    executable_and_modules = 6,
    framebuffer = 7,
    reserved_mapped = 8,
    _,
};

pub const MemoryMapEntry = extern struct {
    base: u64,
    length: u64,
    kind: MemoryType,
};

pub const MemoryMapResponse = extern struct {
    revision: u64,
    entry_count: u64,
    entries: [*]const *const MemoryMapEntry,

    pub fn slice(self: *const MemoryMapResponse) []const *const MemoryMapEntry {
        return self.entries[0..@intCast(self.entry_count)];
    }
};

pub const HhdmResponse = extern struct {
    revision: u64,
    offset: u64,
};

pub const moduleFile = extern struct {
    revision: u64,
    address: [*]const u8,
    size: u64,
    path: [*:0]const u8,
    string: [*:0]const u8,
    media_type: u32,
    unused: u32,
    tftp_ipv4: [4]u8,
    tftp_port: u32,
    partition_index: u32,
    mbr_disk_id: u32,
    uuids: [48]u8,
};
pub const moduleResponse = extern struct { revision: u64, module_count: u64, modules: [*]const *const moduleFile };
comptime {
    if (@sizeOf(moduleFile) != 112 or @offsetOf(moduleFile, "size") != 16 or @sizeOf(moduleResponse) != 24) @compileError("invalid Limine module layout");
}

pub const VideoMode = extern struct {
    pitch: u64,
    width: u64,
    height: u64,
    bpp: u16,
    memory_model: u8,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
};

pub const Framebuffer = extern struct {
    address: [*]u8,
    width: u64,
    height: u64,
    pitch: u64,
    bpp: u16,
    memory_model: u8,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
    unused: [7]u8,
    edid_size: u64,
    edid: ?*const anyopaque,

    // 仅在响应 revision >= 1 时可读取。
    mode_count: u64,
    modes: ?[*]const *const VideoMode,
};

pub const FramebufferResponse = extern struct {
    revision: u64,
    framebuffer_count: u64,
    framebuffers: [*]const *const Framebuffer,
};

pub const MpInfo = extern struct {
    processor_id: u32,
    lapic_id: u32,
    reserved: u64,
    goto_addr: u64,
    extra_args: u64,
};

pub const MpResponse = extern struct {
    revision: u64,
    flags: u32,
    bsp_lapic_id: u32,
    cpu_count: u64,
    cpus: [*]const *MpInfo,
};

pub const MpRequest = extern struct {
    id: [4]u64 = .{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x95a67b819a1b857e, 0xa0b61b723b6a73e0 },
    revision: u64 = 0,
    response: ?*const MpResponse = null,
    flags: u64 = 0,
};

pub const DateResponce = extern struct {
    revision: u64,
    timestamp: i64,
};

comptime {
    if (@sizeOf(MpInfo) != 32 or
        @offsetOf(MpInfo, "goto_addr") != 16 or
        @sizeOf(MpResponse) != 32 or
        @sizeOf(MpRequest) != 56)
        @compileError("invalid Limine MP layout");
}

comptime {
    if (@sizeOf(Framebuffer) != 80 or
        @offsetOf(Framebuffer, "pitch") != 24 or
        @offsetOf(Framebuffer, "bpp") != 32 or
        @offsetOf(Framebuffer, "edid") != 56 or
        @sizeOf(FramebufferResponse) != 24)
    {
        @compileError("invalid Limine framebuffer layout");
    }
}
