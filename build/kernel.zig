const std = @import("std");

/// Add the freestanding kernel; image packaging belongs to the root build.
pub fn add(b: *std.Build, optimize: std.builtin.Optimize) *std.Build.Step.Compile {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_features_sub = std.Target.x86.featureSet(&.{ .mmx, .sse, .sse2, .avx, .avx2 }),
        .cpu_features_add = std.Target.x86.featureSet(&.{.soft_float}),
    });
    const kernel = b.addExecutable(.{
        .name = "carmine.elf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("ksrc/main.zig"),
            .target = target,
            .optimize = optimize,
            .code_model = .kernel,
            .red_zone = false,
            .pic = false,
            .stack_check = false,
            .stack_protector = false,
            .unwind_tables = .none,
        }),
        .use_llvm = true,
        .use_lld = true,
    });
    addASMFiles(b, kernel.root_module);
    kernel.entry = .{ .symbol_name = "_start" };
    kernel.setLinkerScript(b.path("linker.ld"));
    return kernel;
}

fn addASMFiles(b: *std.Build, module: *std.Build.Module) void {
    for ([_][]const u8{
        "ksrc/arch/x86_64/percpu/interrupts/interrupts.asm",
    }) |path|
        module.addCSourceFile(.{
            .file = b.path(path),
            .language = .assembly,
        });
}
