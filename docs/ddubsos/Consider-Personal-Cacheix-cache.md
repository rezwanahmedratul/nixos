# Considering a Personal Cachix Cache for ddubsOS (Public)

Audience: ddubsOS users and contributors (including NixOS newcomers)
Scope: Public cache for faster builds; no private secrets or access controls

---

Why you might want a Cachix cache
- Faster rebuilds on your machines and for users of your project. Heavy derivations (e.g., Hyprland from source) are pulled as binaries instead of recompiled.
- Consistent experience across machines and CI; one place builds, everyone downloads.
- Friendly on-boarding for new NixOS users who may not want to wait for long source builds.

How Cachix works (in 60 seconds)
- Nix produces build outputs in /nix/store.
- Cachix uploads those outputs (plus dependency closures) to a binary cache.
- Other machines configured to trust your cache can fetch those outputs by hash, skipping local compilation.

Quick-start (public cache)
1) Install the CLI
   - nix profile install nixpkgs#cachix

2) Create a cache
   - Sign in at https://app.cachix.org (GitHub/GitLab/Email) and create a new public cache (e.g., ddubsos)
   - Copy the “Public signing key”; we’ll add it to the flake for auto-setup

3) Allow consumers to use the cache automatically (recommended)
   - Add to your flake.nix nixConfig so users don’t need manual setup:

```
# flake.nix (top-level)
nixConfig = {
  extra-substituters = [
    "https://ddubsos.cachix.org"
  ];
  extra-trusted-public-keys = [
    "ddubsos.cachix.org-1:REPLACE_WITH_PUBLIC_KEY"
  ];
};
```

4) Publish builds
   - Push a single build result:
     - nix build .#nixosConfigurations.<HOST>.config.system.build.toplevel
     - cachix push ddubsos ./result
   - Or publish everything you build on this machine (useful during development):
     - cachix watch-store ddubsos
     - Then run your normal nix builds; anything added to /nix/store is uploaded

Automation options
- Developer workstations
  - Put cachix watch-store ddubsos in a dedicated terminal while working
  - Or add a small script/alias (e.g., zcli cache start) to spawn it
- CI (GitLab)
  - Store CACHIX_AUTH_TOKEN as a masked CI variable
  - Minimal job example:

```
cache:
  stage: build
  image: nixos/nix:2.21.2
  variables:
    NIX_CONFIG: extra-experimental-features = nix-command flakes
  script:
    - nix profile install nixpkgs#cachix
    - cachix use ddubsos
    - cachix authtoken "$CACHIX_AUTH_TOKEN"
    - nix build .#nixosConfigurations.<HOST>.config.system.build.toplevel --accept-flake-config
    - cachix push ddubsos ./result
```

Best practices for open projects
- Keep flake.lock under version control; tag stable releases. Reproducibility + cache hits improve dramatically.
- Use public caches for simplicity; no auth needed for consumers.
- Document cache usage in README (“Using the binary cache” section) so new users benefit immediately.
- Consider prebuilding common targets (e.g., ddubsos-vm, popular hosts) via CI to maximize cache usefulness.

Pros
- Huge speedups for first-time builds and upgrades
- Less resource usage on user machines (CPU, memory, battery)
- Scales across your machines and contributors

Cons / trade-offs
- Requires pushing artifacts (bandwidth + storage at provider)
- CI adds complexity (but pays off quickly)
- Cache misses still occur when inputs change (flake.lock bumps)

Costs
- Public caches on Cachix are free within generous limits (subject to provider policies). For large projects or heavy usage, paid plans may apply—check https://cachix.org/pricing for current details.
- Running CI that builds and pushes artifacts consumes CI minutes; on GitLab/GitHub you may have a free tier plus paid options.

Security notes (for public caches)
- Do not commit or print CACHIX_AUTH_TOKEN. Keep it in CI secrets or local keychains.
- Consumers only need the public key in nixConfig. They never need your auth token.

Migration plan for ddubsOS (when/if you decide to enable it)
- Step 1: Create the ddubsos public cache and add it to flake.nix nixConfig
- Step 2: Add a README section “Using the ddubsOS binary cache” (copy of nixConfig and `cachix use ddubsos`)
- Step 3: Add a simple GitLab CI job to build ddubsos-vm and push to cache on main merges
- Step 4: Optionally add watch-store instructions for contributors who want to help populate the cache

FAQ
- Do users need Cachix installed? No, not to consume. Nix will pull from the cache if configured in nixConfig. Cachix CLI is only required to push.
- Will this speed up all builds? It speeds up builds that match the same store paths (same flake.lock, same options). Uncached or changed paths still build locally.
- Can I delete items from the cache? Yes, via the Cachix UI/CLI (subject to retention policies). Typically not needed for public project caches.

Further reading
- Cachix docs: https://docs.cachix.org
- Nix cache overview: https://nixos.org/manual/nix/stable/package-management/binary-caches

