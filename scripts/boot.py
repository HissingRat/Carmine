#!/usr/bin/env python3
"""Package the minimal kernel and run it with QEMU (host-side tooling only)."""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import time

ROOT = Path(__file__).resolve().parent.parent
VERSION = "12.9.6"
SHA256 = "b38aabb042b0c0f9f562b7741be3c1204838d7bbacfa78bb411c674bd5b984ee"
MARKER = b"Carmine: kernel entered\n"


def run_tool(command):
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if result.returncode:
        raise SystemExit(result.stdout.decode(errors="replace"))


def limine(zig):
    cache = ROOT / ".cache"
    cache.mkdir(exist_ok=True)
    archive = cache / f"limine-{VERSION}.tar.gz"
    if not archive.exists():
        url = f"https://github.com/Limine-Bootloader/Limine/releases/download/v{VERSION}/limine-binary.tar.gz"
        partial = archive.with_suffix(".tmp")
        subprocess.run(["curl", "-fL", "--retry", "3", url, "-o", str(partial)], check=True)
        partial.replace(archive)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != SHA256:
        raise SystemExit(f"Limine checksum mismatch; remove {archive} and retry")
    directory = cache / f"limine-{VERSION}"
    if not directory.exists():
        with tempfile.TemporaryDirectory(dir=cache) as staging:
            with tarfile.open(archive) as tar:
                tar.extractall(staging, filter="data")
            (Path(staging) / "limine-binary").rename(directory)
    tool = directory / "limine"
    if not tool.exists():
        subprocess.run([zig, "cc", "-O2", str(directory / "limine.c"), "-o", str(tool)], check=True)
    return directory


def make_iso(args):
    bootloader = limine(args.zig)
    output = Path(args.output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="carmine-iso-") as tmp:
        root = Path(tmp)
        boot = root / "boot"
        boot.mkdir()
        shutil.copy2(args.kernel, boot / "carmine.elf")
        shutil.copy2(args.config, boot / "limine.conf")
        for name in ("limine-bios.sys", "limine-bios-cd.bin", "limine-uefi-cd.bin"):
            shutil.copy2(bootloader / name, boot / name)
        efi = root / "EFI" / "BOOT"
        efi.mkdir(parents=True)
        shutil.copy2(bootloader / "BOOTX64.EFI", efi)
        run_tool([
            "xorriso", "-as", "mkisofs", "-R", "-r", "-J",
            "-b", "boot/limine-bios-cd.bin", "-no-emul-boot",
            "-boot-load-size", "4", "-boot-info-table", "-hfsplus",
            "-apm-block-size", "2048", "--efi-boot", "boot/limine-uefi-cd.bin",
            "-efi-boot-part", "--efi-boot-image", "--protective-msdos-label",
            str(root), "-o", str(output),
        ])
        run_tool([str(bootloader / "limine"), "bios-install", str(output)])


def qemu_command(iso):
    return [
        "qemu-system-x86_64", "-accel", "tcg", "-m", "128M",
        "-cdrom", iso, "-boot", "d", "-no-reboot", "-no-shutdown",
        "-monitor", "none", "-net", "none",
    ]


def check(iso):
    with tempfile.TemporaryDirectory(prefix="carmine-check-") as tmp:
        log = Path(tmp) / "debug.log"
        command = qemu_command(iso) + ["-display", "none", "-debugcon", f"file:{log}"]
        with subprocess.Popen(command, stderr=subprocess.PIPE) as process:
            try:
                deadline = time.monotonic() + 30
                while time.monotonic() < deadline:
                    if process.poll() is not None:
                        raise SystemExit("QEMU exited before kernel entry: " + process.stderr.read().decode())
                    if log.exists() and MARKER in log.read_bytes():
                        print("PASS: Limine entered the x86_64 Carmine kernel.")
                        return
                    time.sleep(0.1)
                raise SystemExit("FAIL: no kernel boot marker within 30 seconds")
            finally:
                if process.poll() is None:
                    process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="mode", required=True)
    iso = commands.add_parser("iso")
    for name in ("zig", "kernel", "config", "output"):
        iso.add_argument(f"--{name}", required=True)
    for name in ("run", "check"):
        command = commands.add_parser(name)
        command.add_argument("--iso", required=True)
        if name == "run":
            command.add_argument("--headless", action="store_true")
    args = parser.parse_args()
    if args.mode == "iso":
        make_iso(args)
    elif args.mode == "check":
        check(args.iso)
    else:
        command = qemu_command(args.iso) + ["-serial", "stdio"]
        if args.headless:
            command += ["-display", "none"]
        os.execvp(command[0], command)


if __name__ == "__main__":
    main()
