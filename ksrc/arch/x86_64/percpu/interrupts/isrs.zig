pub const isr_table_size: usize = 32;
pub extern const isr_table: [isr_table_size]usize;

const INT: u4 = 0xE;
const TRAP: u4 = 0xF;

// https://wiki.osdev.org/Interrupt_Descriptor_Table#IDT_items
pub fn gate_type(vec: u64) u4 {
    return switch (vec) {
        0, 2, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31 => INT,
        1, 3, 4 => TRAP,
        else => INT,
    };
}

pub fn ist(vec: u64) u3 {
    return switch (vec) {
        1 => 1,  // #DB
        2 => 2,  // NMI
        8 => 3,  // #DF
        18 => 4, // #MC
        else => 0,
    };
}
