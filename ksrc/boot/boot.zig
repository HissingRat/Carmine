const limine = @import("limine.zig");

export var requests_start: [4]u64 align(8) linksection(".limine_requests_start") = limine.requests_start;
export var base_revision: [3]u64 align(8) linksection(".limine_requests") = limine.revision_tag;
export var framebuffer_request: limine.Request(limine.FramebufferResponse) align(8) linksection(".limine_requests") = .{ .id = limine.framebuffer_id };
export var mp_request: limine.MpRequest align(8) linksection(".limine_requests") = .{};
export var requests_end: [2]u64 align(8) linksection(".limine_requests_end") = limine.requests_end;

pub const bootInfo = struct {
    startup_time: u64 = undefined,
    mp: ?*const limine.MpResponse,
    framebuffer: *const limine.Framebuffer,
};

pub fn init() bootInfo {
    const revision: *volatile [3]u64 = &base_revision;
    if (revision[2] != 0) @panic("unsupported Limine base revision.");

    const fb_req: *volatile limine.Request(
        limine.FramebufferResponse,
    ) = &framebuffer_request;

    const fb_resp = fb_req.response orelse @panic("framebuffer unavailable");
    if (fb_resp.framebuffer_count == 0)
        @panic("0 framebuffer available");

    const fb = fb_resp.framebuffers[0];

    return .{
        .startup_time = 0,
        .mp = @as(*volatile limine.MpRequest, &mp_request).response,
        .framebuffer = fb,
    };
}
