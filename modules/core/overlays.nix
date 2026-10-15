{...}: {
  # TypeScript support was removed from this configuration, so the
  # typescript-language-server pnpm hash overlay that used to live here is no
  # longer needed. Overlays list intentionally left empty; the module is still
  # imported from flake.nix, so add future overlays here.
  nixpkgs.overlays = [];
}
