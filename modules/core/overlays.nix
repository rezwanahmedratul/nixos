{...}: {
  nixpkgs.overlays = [
    # typescript-language-server 6.0.2 (used by nixvim/neovim) ships a stale
    # pnpm dependency hash in some nixpkgs revisions:
    #   declared: sha256-MUSxDMlbG21KSesGdEvqa2kEpuVfLlXRUX1qV/FGsSo=
    #   actual:   sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=
    # Upstream fixed this in NixOS/nixpkgs@ac7b1aa ("typescript-language-server:
    # fix pnpm hash"), but that commit is only on master and has not landed in
    # the nixos-unstable branch we track yet, so patch it locally for now.
    #
    # Guarded on purpose: this is a no-op on revisions where
    # typescript-language-server has no `pnpmDeps` (e.g. 5.3.0 on older
    # nixpkgs) or where the hash has already been corrected upstream.
    # TODO: remove this overlay once nixos-unstable contains ac7b1aa.

    (final: prev: {
      typescript-language-server = let
        ts = prev.typescript-language-server;
        deps = ts.pnpmDeps or null;
        badHash = "sha256-MUSxDMlbG21KSesGdEvqa2kEpuVfLlXRUX1qV/FGsSo=";
        goodHash = "sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=";
      in
        if deps != null && (deps.outputHash or null) == badHash
        then
          ts.overrideAttrs (old: {
            pnpmDeps = old.pnpmDeps.override {
              hash = goodHash;
            };
          })
        else ts;
    })
  ];
}
