{inputs, ...}: {
  nixpkgs.overlays = [
    # Provide pkgs.google-antigravity via antigravity-nix overlay
    inputs.antigravity-nix.overlays.default

    # Fix Hyprland 0.56.1 build with glaze 8.0.0 in nixpkgs-unstable
    (_final: prev: {
      hyprland = prev.hyprland.overrideAttrs (old: {
        postPatch =
          (old.postPatch or "")
          + ''
            substituteInPlace CMakeLists.txt \
              --replace-fail "find_package(glaze 7...<8 QUIET)" "find_package(glaze REQUIRED)"
          '';
      });
    })

    # Build tumbler without EPUB thumbnailer (libgepub) to avoid webkitgtk
    (_final: prev: {
      xfce = prev.xfce // {
        tumbler = prev.xfce.tumbler.overrideAttrs (old: {
          buildInputs = prev.lib.remove prev.libgepub old.buildInputs;
        });
      };
    })
  ];
}
