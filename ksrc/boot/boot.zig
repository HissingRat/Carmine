const limine = @import("limine.zig");
const time = @import("../utils/time.zig");

export var requests_start: [4]u64 align(8) linksection(".limine_requests_start") = limine.requests_start;
export var base_revision: [3]u64 align(8) linksection(".limine_requests") = limine.revision_tag;
export var boot_time_request: limine.Request(limine.DateResponce) align(8) linksection(".limine_requests") = .{ .id = limine.boot_date_id };
export var fb_request: limine.Request(limine.FramebufferResponse) align(8) linksection(".limine_requests") = .{ .id = limine.framebuffer_id };
export var mp_request: limine.MpRequest align(8) linksection(".limine_requests") = .{};
export var memmap_request: limine.Request(limine.MemoryMapResponse) align(8) linksection(".limine_requests") = .{ .id = limine.memory_map_id };
export var hhdm_request: limine.Request(limine.HhdmResponse) align(8) linksection(".limine_requests") = .{ .id = limine.hhdm_id };
export var requests_end: [2]u64 align(8) linksection(".limine_requests_end") = limine.requests_end;

pub const bootInfo = struct {
    startup_time: ?time.UtcTime = undefined,
    mp: ?*const limine.MpResponse,
    memmap: *const limine.MemoryMapResponse,
    hhdm_offset: u64,
    framebuffer: *const limine.Framebuffer,
};

pub fn init() bootInfo {
    const revision: *volatile [3]u64 = &base_revision;
    if (revision[2] != 0) @panic("unsupported Limine base revision.");

    const date_resp = boot_time_request.response;
    const startup_time = if (date_resp) |resp| time.unixToUtc(resp.timestamp) else null;

    const memmap_resp = memmap_request.response;
    const memmap = if (memmap_resp) |resp| resp else @panic("unable to get memory map");

    const hhdm_resp = hhdm_request.response;
    const hhdm_offset = if (hhdm_resp) |resp| resp.offset else @panic("unable to get hhdm offset");

    const fb_resp = fb_request.response orelse @panic("framebuffer unavailable");
    if (fb_resp.framebuffer_count == 0)
        @panic("0 framebuffer available");
    const fb = fb_resp.framebuffers[0];

    return .{
        .startup_time = startup_time,
        .mp = @as(*volatile limine.MpRequest, &mp_request).response,
        .memmap = memmap,
        .hhdm_offset = hhdm_offset,
        .framebuffer = fb,
    };
}
