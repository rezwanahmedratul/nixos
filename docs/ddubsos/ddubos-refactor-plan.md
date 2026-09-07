# ddubsOS Refactor Plan — 2025-09-06

Goal: Implement high-value structural improvements while preserving current install flows (manual and install-ddubsos.sh) and preparing ZCLI support for host management. This plan also defines versioning and documentation updates, including Spanish translations.

## Scope and principles
- Non-breaking by default. Refactors will be gated behind a feature branch (ddubos-refactor) and released after testing.
- Stable reference point: create Stable-v2.4 from main and set DDUBSOS_VERSION=2.4.
- Document and script changes to keep manual installs and install-ddubsos.sh behavior consistent.

## 1) Flake host architecture refactor
- Problem: flake.nix hard-codes host = "ixas" across all nixosConfigurations; other host folders exist but aren’t selected per output.
- Target: Generate one nixosConfigurations.<host> per host, wiring ./hosts/<host> and the appropriate GPU profile.

Approach options:
1) Map host -> profile
   - A single nixosConfigurations set, each entry adds hosts/<host> and profiles/<profile> determined by a mapping.
   - Pros: Deterministic. Cons: Requires maintaining the map.
2) Cartesian product hosts × profiles
   - Expose ddubsos.<host>-<profile> targets; installation chooses the one desired.
   - Pros: Flexible. Cons: Larger output set; naming may be verbose.

Proposed: Start with a host -> default profile mapping to match today’s usage. Allow override via an env var or CLI flag in install-ddubsos.sh.

Illustrative flake pattern:
```nix path=null start=null
# inside outputs = inputs @ { self, nixpkgs, ... }:
let
  system = "x86_64-linux";
  hosts = [ "ixas" "asus" "bubo" "ddubsos-vm" "default" "explorer" "macbook" "mini-intel" "pegasus" "prometheus" "xps15" ];
  defaultProfileFor = host: {
    ixas = "amd";
    asus = "nvidia";
    bubo = "intel";
    default = "vm";
  }.${host} or "amd";

  mkNixosConfig = { host, profile }: nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs username host profile; };
    modules = [
      ./modules/nix-caches.nix
      ./modules/core/overlays.nix
      ./profiles/${profile}
      ./hosts/${host}
      inputs.catppuccin.nixosModules.catppuccin
      nix-flatpak.nixosModules.nix-flatpak
    ];
  };
in {
  nixosConfigurations = nixpkgs.lib.genAttrs hosts (host:
    mkNixosConfig { inherit host; profile = defaultProfileFor host; }
  );
}
```

Install impact and mitigation:
- Manual: users will now build with e.g., nixos-rebuild switch --flake .#ixas. Document this.
- Script: update install-ddubsos.sh to accept --host and optional --profile, defaulting to detection/map.
  - If unset, prompt user with a safe default.
  - Ensure non-interactive mode via flags for CI.

ZCLI impact:
- Add commands: zcli host add <name>, zcli host rm <name>, zcli host rename <old> <new>
  - host add: scaffold hosts/<name>/{default.nix,hardware.nix,host-packages.nix,variables.nix} from templates.
  - host rm: safety checks (confirm, backup).
  - host rename: move directory, update references in flake.nix if needed.
- Add: zcli hostname set <name> to set networking.hostName declaratively (avoid hostnamectl impermanence).

## 2) Changing the hostname (declarative)
- Set or update networking.hostName in an appropriate module (e.g., hosts/<name>/default.nix or modules/core/system.nix if global) and rebuild. Avoid imperative hostnamectl for persistence.
- Provide zcli hostname set <name> which updates the correct file and runs a guarded rebuild (or prints instructions with --dry-run).

## 3) Linter/formatter and checks
- Choose alejandra for Nix formatting; optionally add treefmt-nix for multi-language formatting (Nix, JSON, Markdown) and pre-commit hooks.
- Add formatter and checks to flake.nix:
```nix path=null start=null
outputs = inputs @ { self, nixpkgs, ... }:
let
  systems = [ "x86_64-linux" ];
  forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
in {
  formatter = forAllSystems (pkgs: pkgs.alejandra);
  checks = forAllSystems (pkgs: {
    formatting = pkgs.runCommand "formatting" { buildInputs = [ pkgs.alejandra ]; } ''
      alejandra --check .
      touch $out
    '';
  });
}
```
- Document usage: nix fmt and nix flake check.

## 4) Home Manager: useGlobalPkgs — deferred
- Decision: Disabled (hmUseGlobalPkgs = false) due to issues encountered during testing.
- Guidance: Do not enable at this time. Revisit in a future iteration once overlays and HM module interactions are fully hardened.

## 5) Versioning and migration plan
- Establish Stable-v2.4 branch from main with DDUBSOS_VERSION=2.4.
- Use Stable-v2.4 as the minimum baseline for future upgrades.
- Migration notes (to draft in docs/upgrade-from-2.4.md):
  - If upgrading from < 2.4, first switch to Stable-v2.4, rebuild, and validate.
  - From 2.4 → refactored flake: document new flake output names (#<host>), install script flags, and zcli changes.
  - Provide a zcli migrate command that checks stateVersion values, warns about deprecated options, and guides manual steps if needed.

## 6) Documentation changes (README, FAQ, docs/*, wiki) and Spanish updates
- README.md / README.es.md
  - Update version banners to reflect Stable v2.4 (done in Stable-v2.4 branch).
  - Add a short “Selecting a host” section showing nixos-rebuild switch --flake .#<host>.
  - Add note about install script flags: --host and --profile.
- FAQ.md / FAQ.es.md
  - Update version mention to v2.4; add entries for host selection, hostname changes, and useGlobalPkgs pros/cons.
- docs/*
  - Add docs/ddubos-deep-analysis-YYYY-MM-DD.md (done) and docs/ddubos-refactor-plan.md (this file).
  - Draft docs/upgrade-from-2.4.md (to be created during refactor).
  - Update existing guides where flake attribute names or commands change.
- Wiki
  - Mirror the above changes; ensure both English and Spanish pages updated.
- Translation process
  - Maintain .md and .es.md pairs.
  - Use consistent version banners and dates in both languages.

## 7) Script-level changes
- install-ddubsos.sh
  - Add flags: --host <name>, --profile <amd|intel|nvidia|nvidia-laptop|vm>, --non-interactive.
  - Detect GPU when --profile is absent; default from mapping; prompt unless non-interactive.
  - Build using nixos-rebuild or nh targeting .#<host>.
- zcli (ddubsOS version)
  - Add: host add|rm|rename; hostname set; settings update for host/profile; dry-run support.

## 8) CI and release hygiene
- Add flake checks to CI (GitHub/GitLab CI). Required checks: build flake, alejandra --check, optionally run-of select hosts.
- Tag releases when cutting a stable branch; consider semantic versioning.

## 9) Rollout plan
- Phase 1 (branch: ddubos-refactor):
  - Implement flake host mapping, add formatter, draft docs/upgrade-from-2.4.md.
  - Update install script (flags + behavior) and prepare zcli changes (scaffolding + help).
  - Smoke test at least two hosts and two profiles.
- Phase 2 (PR to main):
  - After reviews and tests, merge; then cut Stable-v2.5.

## 10) Open questions
- Do we want cartesian outputs (host-profile) or keep a mapping?
- Which hosts are considered “blessed” for CI builds?

## Additional suggestions
- Consider sops-nix or agenix for secrets.
- Consider direnv + nix-direnv for dev ergonomics.
- Explore nix-fast-build or cachix for faster local builds.
- Consider nixos-anywhere for remote provisioning.
- Evaluate system.autoUpgrade with flake pinning and notifications.

