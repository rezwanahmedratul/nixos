{
  description = "ZaneyOS";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nvf.url = "github:notashelf/nvf";
    stylix.url = "github:danth/stylix/master";
    nix-flatpak.url = "github:gmodena/nix-flatpak?ref=latest";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Checking nixvim to see if it's better
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Google Antigravity (IDE)
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nixvim,
    nix-flatpak,
    alejandra,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    host = "zaneyos-24-vm";
    profile = "vm";
    username = "dwilliams";

    # Deduplicate nixosConfigurations while preserving the top-level 'profile'
    mkNixosConfig = gpuProfile:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit username;
          inherit host;
          inherit profile; # keep using the let-bound profile for modules/scripts
        };
        modules = [
          ./modules/core/overlays.nix
          ./profiles/${gpuProfile}
          nix-flatpak.nixosModules.nix-flatpak
        ];
      };
  in {
    nixosConfigurations = {
      amd = mkNixosConfig "amd";
      nvidia = mkNixosConfig "nvidia";
      nvidia-laptop = mkNixosConfig "nvidia-laptop";
      amd-nvidia-hybrid = mkNixosConfig "amd-nvidia-hybrid";
      intel = mkNixosConfig "intel";
      vm = mkNixosConfig "vm";
    };

    formatter.x86_64-linux = inputs.alejandra.packages.x86_64-linux.default;
  };
}
