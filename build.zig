const std = @import("std");

pub fn build(b: *std.Build) void {
    const kernel = @import("build/kernel.zig").add(b, b.standardOptimizeOption(.{}));
    const install_kernel = b.addInstallArtifact(kernel, .{});
    b.getInstallStep().dependOn(&install_kernel.step);
    b.step("kernel", "Build the kernel only").dependOn(&install_kernel.step);

    const iso_cmd = b.addSystemCommand(&.{"python3"});
    iso_cmd.addFileArg(b.path("scripts/boot.py"));
    iso_cmd.addArgs(&.{ "iso", "--zig", b.graph.zig_exe, "--kernel" });
    iso_cmd.addFileArg(kernel.getEmittedBin());
    iso_cmd.addArg("--config");
    iso_cmd.addFileArg(b.path("boot/limine.conf"));
    iso_cmd.addArg("--output");
    const iso = iso_cmd.addOutputFileArg("carmine.iso");
    const install_iso = b.addInstallFile(iso, "carmine.iso");
    b.step("iso", "Build the bootable ISO").dependOn(&install_iso.step);

    inline for (.{ "run", "check" }) |mode| {
        const cmd = b.addSystemCommand(&.{"python3"});
        cmd.has_side_effects = true;
        if (std.mem.eql(u8, mode, "run")) cmd.stdio = .inherit;
        cmd.addFileArg(b.path("scripts/boot.py"));
        cmd.addArgs(&.{ mode, "--iso" });
        cmd.addFileArg(iso);
        cmd.step.dependOn(&install_iso.step);
        cmd.addPassthruArgs();
        b.step(mode, if (std.mem.eql(u8, mode, "run")) "Boot in QEMU" else "Verify kernel entry in QEMU").dependOn(&cmd.step);
    }
}
