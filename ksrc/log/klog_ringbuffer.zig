const std = @import("std");

export var early_log_buf: [64 * 1024]u8 align(4096) linksection(".init.logbuf") = undefined;

//TODO: 先搞定early内存管理系统
