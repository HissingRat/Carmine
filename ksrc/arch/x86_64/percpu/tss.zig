/// https://wiki.osdev.org/Task_State_Segment

// 不要用packed struct, 否则size会变成 112 bytes而非 104 bytes
pub const PerCpuTss = extern struct {
    reserved0: u32 = 0,

    rsp0: u64 align(4) = 0,
    rsp1: u64 align(4) = 0,
    rsp2: u64 align(4) = 0,

    reserved1: u64 align(4) = 0,

    ist1: u64 align(4) = 0,
    ist2: u64 align(4) = 0,
    ist3: u64 align(4) = 0,
    ist4: u64 align(4) = 0,
    ist5: u64 align(4) = 0,
    ist6: u64 align(4) = 0,
    ist7: u64 align(4) = 0,

    reserved2: u64 align(4) = 0,
    reserved3: u16 = 0,
    iomap_base: u16 = @sizeOf(PerCpuTss),
};

comptime {
    if (@sizeOf(PerCpuTss) != 104)
        @compileError("Invalid TSS size");

    if (@offsetOf(PerCpuTss, "rsp0") != 4)
        @compileError("Invalid RSP0 offset");

    if (@offsetOf(PerCpuTss, "ist1") != 36)
        @compileError("Invalid IST1 offset");

    if (@offsetOf(PerCpuTss, "iomap_base") != 102)
        @compileError("Invalid I/O bitmap offset");
}
