{lib, ...}: {
  nix.settings = {
    substituters = lib.mkAfter [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://ryotunes.cachix.org"
    ];
    trusted-public-keys = lib.mkAfter [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "ryotunes.cachix.org-1:QNocajCsVm/IAMb8LPOWJi72XwqiexW9ec0UqeXLpGs="
    ];
  };
}
