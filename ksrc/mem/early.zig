const std = @import("std");
const klogger = @import("../log/klogger.zig");
const bootInfo = @import("../boot/boot.zig").bootInfo;

const MemRegion = struct { base: u64, length: u64 };
const MemType = struct {
    regions: []MemRegion,
    size: u64,
};
const EarlyMem = struct { memory: MemType, reserved: MemType };

const page_size: usize = 4096;
const reserved_capacity: usize = 16;
var reserved_index: usize = 0;

pub fn init(info: bootInfo) void {
    const memmap = info.memmap;

    var usable_count: usize = 0;
    var usable_size: usize = 0;
    for (memmap.slice()) |slice| {
        if (slice.kind != .usable or slice.length == 0)
            continue;
        usable_count += 1;
        usable_size += slice.length;
    }

    const memory_offset = std.mem.alignForward(u64, @sizeOf(EarlyMem), @alignOf(MemRegion));
    const reserved_offset = memory_offset + usable_count * @sizeOf(MemRegion);
    const metadata_bytes = reserved_offset + reserved_capacity * @sizeOf(MemRegion);
    const reserved_bytes = std.mem.alignForward(u64, metadata_bytes, page_size);

    for (memmap.slice()) |slice| {
        if (slice.kind != .usable or slice.length < reserved_bytes)
            continue;

        const phys_start = std.mem.alignForward(u64, slice.base, page_size);
        const required = phys_start - slice.base + reserved_bytes;
        if (slice.length < required)
            continue;

        const virt_start = phys_start + info.hhdm_offset;
        const mem_start = virt_start + memory_offset;
        const reserved_start = virt_start + reserved_offset;

        const early: *EarlyMem = @ptrFromInt(virt_start);
        const memory_ptr: [*]MemRegion = @ptrFromInt(mem_start);
        const reserved_ptr: [*]MemRegion = @ptrFromInt(reserved_start);

        const memory = memory_ptr[0..usable_count];
        const reserved = reserved_ptr[0..reserved_capacity];
        var i: usize = 0;
        for (memmap.slice()) |s| {
            if (s.kind == .usable and s.length != 0) {
                memory[i] = .{ .base = s.base, .length = s.length };
                i += 1;
            }
        }

        reserved[0] = .{ .base = phys_start, .length = reserved_bytes };
        reserved_index += 1;

        early.* = .{
            .memory = .{ .regions = memory, .size = usable_size },
            .reserved = .{ .regions = reserved, .size = reserved_bytes },
        };

        var ranges = freeRanges(early);
        while (ranges.next()) |region| {
            klogger.kprintf("free: base=0x{x}, length=0x{x}\n", .{
                region.base, region.length,
            });
        }
        return;
    }
    @panic("no usable region for early memory.");
}

const RegionIterator = struct {
    memory: []MemRegion,
    reserved: []MemRegion,

    mem_index: usize = 0,
    reserved_index: usize = 0,
    cursor: usize = 0,

    fn next(this: *RegionIterator) ?MemRegion {
        while (this.mem_index < this.memory.len) {
            const mem = this.memory[this.mem_index];
            const start = @max(mem.base, this.cursor);
            var end = mem.base + mem.length;

            if (start >= end) {
                this.mem_index += 1;
                continue;
            }

            if (this.reserved_index < this.reserved.len) {
                const reserved = this.reserved[this.reserved_index];
                const res_start = reserved.base;
                const res_end = res_start + reserved.length;

                if (reserved.length == 0 or res_end <= start) {
                    this.reserved_index += 1;
                    continue;
                }

                if (res_start <= start) {
                    this.cursor = res_end;
                    this.reserved_index += 1;
                    continue;
                }

                end = @min(end, res_start);
            }

            this.cursor = end;
            return .{ .base = start, .length = end - start };
        }
        return null;
    }
};

fn freeRanges(early: *EarlyMem) RegionIterator {
    return .{ .memory = early.memory.regions, .reserved = early.reserved.regions[0..reserved_index] };
}
