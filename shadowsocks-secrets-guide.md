# Shadowsocks Secrets Migration & Troubleshooting Guide

This document provides a comprehensive post-mortem and implementation guide for extracting hardcoded credentials from `modules/core/shadowsocks.nix` into a Git-ignored secret file in a Nix Flake repository.

---

## 1. Initial Issue & Motivation

### The Problem
Originally, `modules/core/shadowsocks.nix` contained plain-text passwords embedded directly in the Nix configuration for three Shadowsocks client instances (`shadowsocks-1`, `shadowsocks-2`, `shadowsocks-3`).

#### Original Code Snippet (`modules/core/shadowsocks.nix`):
```nix
environment.etc = {
  "shadowsocks-1.json".text = ''
  {
    "server": "64.20.10.126",
    "server_port": 12348,
    "local_address": "127.0.0.1",
    "local_port": 1081,
    "password": "T8@qN5#vX3rB!1cE",
    "method": "chacha20-ietf-poly1305",
    "mode": "tcp_and_udp"
  }
  '';
  # ... repeated for shadowsocks-2 and shadowsocks-3 ...
};
```

### Risk & Goal
Hardcoding credentials directly in repository files creates a security vulnerability if the repository is committed or pushed to remote hosts. The goal was to extract passwords into a separate secret file (`shadowsocks-secrets.nix`) and exclude it from version control via `.gitignore`.

---

## 2. Refactoring Steps Taken

1. **Created Secret Storage (`modules/core/shadowsocks-secrets.nix`)**:
   Extracted the password into an untracked Nix file storing configuration attributes.

2. **Created Repository `.gitignore`**:
   Created `/home/ratul/nixos/.gitignore` to prevent secret files from being committed to Git:
   ```gitignore
   # Secrets
   modules/core/shadowsocks-secrets.nix
   *.secrets.nix
   ```

3. **Dynamic Import in `modules/core/shadowsocks.nix`**:
   Refactored `shadowsocks.nix` to dynamically import `shadowsocks-secrets.nix` if it exists, with a fallback placeholder (`CHANGE_ME`) if missing.

---

## 3. The Obstacle Faced (Root Cause Analysis)

### The Symptom
After applying the initial refactoring and running system rebuilds, the Shadowsocks proxies stopped working and could not establish connection to remote servers.

Inspecting the deployed config file at `/etc/static/shadowsocks-3.json` revealed:
```json
{
  "server": "208.240.24.65",
  "server_port": 12348,
  "local_address": "127.0.0.1",
  "local_port": 1083,
  "password": "CHANGE_ME",
  "method": "chacha20-ietf-poly1305",
  "mode": "tcp_and_udp"
}
```
The generated config contained the literal fallback string `"CHANGE_ME"` instead of the actual password from `shadowsocks-secrets.nix`.

### Technical Root Cause: Nix Flakes Pure Evaluation Mode
The failure occurred due to the interaction between **Git**, **.gitignore**, and **Nix Flakes**:

1. When `nixos-rebuild switch --flake .` is executed, Nix Flakes evaluates the repository in **pure evaluation mode** by default.
2. In pure mode, Nix copies only **Git-tracked** files into the evaluation store closure (`/nix/store/<hash>-source`).
3. Because `shadowsocks-secrets.nix` was listed in `.gitignore`, Git excluded it from the Flake source closure.
4. When `shadowsocks.nix` executed `builtins.pathExists ./shadowsocks-secrets.nix`, Nix searched inside `/nix/store/<hash>-source/modules/core/` where `shadowsocks-secrets.nix` did **not** exist.
5. `builtins.pathExists` returned `false`, triggering the fallback branch (`{ password = "CHANGE_ME"; }`) silently.

---

## 4. Final Solution & How We Fixed It

To resolve the issue while keeping `shadowsocks-secrets.nix` untracked and strictly in `.gitignore`, we implemented two fixes:

### 1. Robust Path Resolution & Per-Proxy Overrides (`modules/core/shadowsocks.nix`)
We updated `shadowsocks.nix` with candidate path discovery (`secretCandidates`) and per-proxy password override variables (`pass1`, `pass2`, `pass3`):

```nix
{ config, pkgs, lib, ... }:

let
  secretCandidates = [
    ./shadowsocks-secrets.nix
    /home/ratul/nixos/modules/core/shadowsocks-secrets.nix
    /etc/nixos/modules/core/shadowsocks-secrets.nix
  ];

  findSecret = paths:
    if paths == [] then null
    else if builtins.pathExists (builtins.head paths)
      then import (builtins.head paths)
      else findSecret (builtins.tail paths);

  secrets = let found = findSecret secretCandidates; in
    if found != null then found else { password = "CHANGE_ME"; };

  pass1 = secrets.password1 or secrets.password;
  pass2 = secrets.password2 or secrets.password;
  pass3 = secrets.password3 or secrets.password;

  mkSS = { name, server, localPort }: {
    description = "Shadowsocks Client (${name})";
    after = [ "network.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.shadowsocks-rust}/bin/sslocal -c /etc/${name}.json";
      Restart = "always";
      RestartSec = 5;
    };
  };
in
{
  environment.etc = {
    "shadowsocks-1.json".text = ''
    {
      "server": "64.20.10.126",
      "server_port": 12348,
      "local_address": "127.0.0.1",
      "local_port": 1081,
      "password": "${pass1}",
      "method": "chacha20-ietf-poly1305",
      "mode": "tcp_and_udp"
    }
    '';

    "shadowsocks-2.json".text = ''
    {
      "server": "64.20.10.49",
      "server_port": 12348,
      "local_address": "127.0.0.1",
      "local_port": 1082,
      "password": "${pass2}",
      "method": "chacha20-ietf-poly1305",
      "mode": "tcp_and_udp"
    }
    '';

    "shadowsocks-3.json".text = ''
    {
      "server": "208.240.24.65",
      "server_port": 12348,
      "local_address": "127.0.0.1",
      "local_port": 1083,
      "password": "${pass3}",
      "method": "chacha20-ietf-poly1305",
      "mode": "tcp_and_udp"
    }
    '';
  };

  systemd.services = {
    shadowsocks-1 = mkSS { name = "shadowsocks-1"; server = "64.20.10.126"; localPort = 1081; };
    shadowsocks-2 = mkSS { name = "shadowsocks-2"; server = "64.20.10.49"; localPort = 1082; };
    shadowsocks-3 = mkSS { name = "shadowsocks-3"; server = "208.240.24.65"; localPort = 1083; };
  };
}
```

### 2. Secret File Definition (`modules/core/shadowsocks-secrets.nix`)
```nix
{
  # Default password for all Shadowsocks proxies
  password = "T8@qN5#vX3rB!1cE";

  # Optional per-proxy password overrides:
  # password1 = "T8@qN5#vX3rB!1cE";
  # password2 = "T8@qN5#vX3rB!1cE";
  # password3 = "T8@qN5#vX3rB!1cE";
}
```

### 3. Execution Rule: Rebuilding with `--impure`
To allow Nix Flakes to read gitignored disk files during rebuild, pass the `--impure` flag:

```bash
# Standard NixOS rebuild
sudo nixos-rebuild switch --flake . --impure

# Or using nh / zcli wrappers
nh os switch . -- --impure
zcli rebuild --impure
```

---

## 5. Verification Command

You can verify that Flake evaluation correctly injects your secrets without modifying your live system:

```bash
nix eval --impure .#nixosConfigurations.intel.config.environment.etc."shadowsocks-3.json".text
```

#### Output:
```json
"{\n  \"server\": \"208.240.24.65\",\n  \"server_port\": 12348,\n  \"local_address\": \"127.0.0.1\",\n  \"local_port\": 1083,\n  \"password\": \"T8@qN5#vX3rB!1cE\",\n  \"method\": \"chacha20-ietf-poly1305\",\n  \"mode\": \"tcp_and_udp\"\n}\n"
```

---

## Summary Checklist

| Task | File / Command | Status |
| :--- | :--- | :---: |
| Extract secret credentials | `modules/core/shadowsocks-secrets.nix` | Completed |
| Add secret patterns to `.gitignore` | `.gitignore` | Completed |
| Update core module path resolution | `modules/core/shadowsocks.nix` | Completed |
| Rebuild system with `--impure` | `sudo nixos-rebuild switch --flake . --impure` | Ready |
