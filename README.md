# Carmine

## 环境

- Zig **0.17.1**（见 `.zigversion`）
- `qemu-system-x86_64`、`xorriso`、Python 3.12+、`curl`
- 首次构建 ISO 需要联网；脚本下载固定版本的 Limine、校验 SHA-256，并缓存到 `.cache/`。

macOS 可通过 `brew install qemu xorriso python` 安装辅助工具。

## 构建与启动

```sh
zig build                         # 内核：zig-out/bin/carmine.elf
zig build kernel                  # 显式仅构建内核，不下载 Limine 或生成 ISO
zig build iso                     # 启动镜像：zig-out/carmine.iso
zig build run                     # 启动 QEMU 窗口
zig build run -- --headless        # 无窗口启动，Ctrl+C 退出
zig build check                   # 自动验证内核启动，完成后关闭 QEMU
```
ISO 同时包含 BIOS 和 x86_64 UEFI 引导文件；上述命令默认使用 QEMU BIOS。

协议及镜像布局参考 [Limine 协议](https://github.com/Limine-Bootloader/limine-protocol/blob/trunk/PROTOCOL.md)
和 [Limine 使用说明](https://github.com/Limine-Bootloader/Limine/blob/v12.9.6/USAGE.md)。
