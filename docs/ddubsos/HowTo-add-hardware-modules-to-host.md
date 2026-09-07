English | [Español](./HowTo-add-hardware-modules-to-host.es.md)

# Add nixos-hardware modules per host (example: MacBookPro 8,1)

This guide shows how to enable hardware-specific NixOS modules (from nixos-hardware) for a single host in a flake-based ddubsOS setup. We’ll use the Apple MacBookPro 8,1 as an example, but the steps apply to any device listed in the nixos-hardware repository.

- Repo of modules: https://github.com/NixOS/nixos-hardware
- Example module we’ll use: apple/macbook-pro/8-1 → attribute: nixos-hardware.nixosModules.apple-macbook-pro-8-1

## Prerequisites
- Your system uses flakes (ddubsOS does).
- You’ve added nixos-hardware as a flake input (if not, see Step 1).

## Step 1 — Ensure nixos-hardware is a flake input
Add or confirm the nixos-hardware input in your flake.nix. Using the plain repo reference is sufficient (no need to append /master):

```nix path=null start=null
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };
}
```

If you changed inputs, update the lock file:

```bash path=null start=null
nix flake update nixos-hardware
# or
nix flake lock --update-input nixos-hardware
```

## Step 2 — Import the hardware module for one host
There are two common, equally valid approaches. Pick one.

### Option A (recommended): Import in the host’s modules list (in outputs)
Add the module to the modules array for that specific host in flake.nix.

```nix path=null start=null
{
  outputs = { self, nixpkgs, nixos-hardware, ... }:
  {
    nixosConfigurations = {
      macbook = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Intel MacBookPro 8,1 runs Linux
        modules = [
          ./hosts/macbook/configuration.nix
          nixos-hardware.nixosModules.apple-macbook-pro-8-1
        ];
      };
    };
  };
}
```

### Option B: Import from within the host’s configuration.nix
Pass nixos-hardware into your modules via specialArgs and import it inside the host file.

```nix path=null start=null
# flake.nix (relevant parts)
{
  outputs = { self, nixpkgs, nixos-hardware, ... }:
  {
    nixosConfigurations.macbook = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit nixos-hardware; };
      modules = [ ./hosts/macbook/configuration.nix ];
    };
  };
}
```

```nix path=null start=null
# hosts/macbook/configuration.nix
{ config, pkgs, lib, nixos-hardware, ... }:
{
  imports = [
    nixos-hardware.nixosModules.apple-macbook-pro-8-1
  ];
}
```

### Alternative import by path (string)
If you prefer string paths, you can also do:

```nix path=null start=null
imports = [
  "${nixos-hardware}/apple/macbook-pro/8-1"
];
```

Note: You still need nixos-hardware in scope (e.g., via specialArgs).

## Step 3 — Apply your configuration
Build and switch for just that host target:

```bash path=null start=null
sudo nixos-rebuild switch --flake .#macbook
```

If you use ddubsOS helpers:

```bash path=null start=null
zcli rebuild
```

## How to find the right module name
- Browse the nixos-hardware repo directory that matches your device model.
- Convert its path to the nixosModules attribute by replacing slashes with dashes and removing special characters. Example:
  - Path: apple/macbook-pro/8-1
  - Attribute: nixos-hardware.nixosModules.apple-macbook-pro-8-1

If in doubt, you can also import by path (string) as shown above.

## Updating nixos-hardware later
Keep hardware modules current by updating the input:

```bash path=null start=null
nix flake update nixos-hardware
```

## Verification tips
- Dry run first:

```bash path=null start=null
sudo nixos-rebuild dry-run --flake .#macbook
```

- After switching, confirm device-specific features (trackpad, backlight, sensors) behave better out-of-the-box.
- If you maintain per-host variables.nix, keep hardware-specific toggles there for clarity.

## Troubleshooting
- Wrong attribute name: Use the path import form ("${nixos-hardware}/...") to verify, or double-check the directory name in the repo.
- Wrong system: Ensure system matches your CPU (e.g., "x86_64-linux" for Intel-based MacBookPro 8,1).
- Conflicts with existing options: If another module sets the same options, ensure the import order is correct—later modules typically win.

## Example directory layout (simplified)

```text path=null start=null
.
├─ flake.nix
└─ hosts/
   └─ macbook/
      ├─ configuration.nix
      └─ variables.nix   # optional, for host-specific toggles
```

