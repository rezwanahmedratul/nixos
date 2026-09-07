# CachyOS kernel + v4l2loopback build issues (clang toolchain)

Last updated: 2025-09-05

## Overview

We use the CachyOS kernel to maintain ZFS compatibility without enabling allowBroken and to leverage Chaotic Nyx caches. On systems where the kernel is built with clang/LLVM, the out-of-tree v4l2loopback kernel module can fail to build under Nix due to a mix of Kbuild defaults (assuming gcc) and cc-wrapper flags that clang rejects. Additionally, the upstream derivation attempts to build and install a userspace utility (v4l2loopback-ctl) inside the kernel module environment, which lacks glibc headers.

This document captures the symptoms, root cause, and the fixes applied in ddubsOS to reliably build v4l2loopback against the Cachy (clang-built) kernel.

## Symptoms

During nixos-rebuild (or `zcli rebuild`) against linuxPackages_cachyos:

- gcc: command not found when Kbuild defaults to GCC
- gcc: unrecognized options (e.g., -mretpoline-external-thunk, -fsplit-lto-unit)
- clang: warning/error for -Werror,-Wunused-command-line-argument due to kernel CFLAGS
- After module compilation succeeds, installPhase fails trying to install the utils/v4l2loopback-ctl binary: missing crt1.o/crti.o and -lgcc_s in the kernel build env
- Harmless build-time warnings:
  - Missing System.map → depmod skipped at build; happens later on activation/boot
  - BTF/vmlinux not present; BTF generation skipped
  - Module signing notes; informational unless signing is enforced

## Root cause

- Toolchain mismatch: Kbuild assumes GCC unless told to use LLVM=1 and a specific CC/LD. When using clang via Nix cc-wrappers, additional multi-target flags can surface as “unused command line argument” warnings promoted to errors by kernel build rules.
- Userspace utilities built in a kernel module env: The upstream makefile tries to build and install `utils/v4l2loopback-ctl`. That target requires a normal userland build env (glibc, crt objects) and should not be part of a pure kernel-module build.

## Fix implemented in ddubsOS

1) Force the LLVM toolchain for the kernel module build

- Set stdenv to llvmPackages.stdenv for the override
- Export CC/LD with absolute paths and set makeFlags: LLVM=1 CC=clang LD=ld.lld
- Prefer unwrapped clang/lld to avoid extra wrapper flags
- Add EXTRA_CFLAGS to suppress unused-argument diagnostics under clang

2) Build only the kernel module; skip userspace utils entirely

- Restrict outputs to a single “out” output
- Override phases (or patch the Makefile) so the install step only runs `modules_install` for the .ko and does not attempt to install `v4l2loopback-ctl`

3) Result

- v4l2loopback.ko builds and installs against linuxPackages_cachyos
- Rebuild proceeds past the module stage; final verification pending at the time of writing

## Why skipping the userspace utility is OK

OBS and common use cases only require the kernel module to create loopback devices. The `v4l2loopback-ctl` tool can be packaged separately in a normal userland derivation if needed. Building it inside the kernel module derivation creates libc/linker issues and is unnecessary for primary functionality.

## Notes on warnings you may see

- Missing System.map / depmod skipped: Expected for many kernel module builds in Nix; depmod is usually run later (activation/boot). Not a blocker.
- BTF/vmlinux not found: Informational. If you require BTF, ensure the kernel dev outputs include vmlinux with BTF.
- Module signing messages: Informational unless your kernel enforces module signing. If enforcement is on, configure the appropriate signing key in your NixOS config.

## Rebuild

- Preferred: `zcli rebuild` (or `zcli rebuild -n` to preview)
- Traditional: `sudo nixos-rebuild switch --flake .#<profile>`

## Maintenance

- If Cachy kernel or nixpkgs changes break the override again:
  - Re-verify LLVM=1 CC=clang LD=ld.lld are honored (check the build log)
  - Ensure clang-unwrapped and lld-unwrapped are used if wrapper flags reappear
  - Keep EXTRA_CFLAGS with `-Wno-unused-command-line-argument`
  - Confirm no attempt is made to build/install `utils/v4l2loopback-ctl` in the module derivation

- If you need v4l2loopback-ctl:
  - Package it as a separate derivation that uses a normal stdenv and links against glibc

## Troubleshooting checklist

- Does the build log show `LLVM=1` and `CC=clang`? If not, pass them via `makeFlags` and export CC/LD.
- Do you see `unused command line argument` from clang? Add `-Wno-unused-command-line-argument` to EXTRA_CFLAGS.
- Does the build fail in the install phase looking for `v4l2loopback-ctl`? Patch make install to only run modules_install; do not install the ctl.
- Are you getting hard failures about module signing? Configure or disable enforced signing per your policy.

