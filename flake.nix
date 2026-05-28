{
  description = "ZaneyOS";

  inputs = {
    systems.url = "github:nix-systems/default-linux";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    stylix = {
      url = "github:danth/stylix/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak?ref=latest";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Checking nixvim to see if it's better
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
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
    synfetch = {
      url = "github:SXSLVT/synfetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nixvim,
    nix-flatpak,
    systems,
    ...
  } @ inputs: let
    username = "dwilliams";

    forAllSystems = nixpkgs.lib.genAttrs (import systems);

    # Deduplicate nixosConfigurations while preserving the top-level 'profile'
    mkNixosConfig = host:
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          inherit username;
        };
        modules = [
          ./modules/core
          ./modules/drivers
          ./hosts/${host}
          ./profiles
        ];
      };

    hosts = [
      "zos-nix-mirror"
      "zaneyos-next"
      "default"
      "zaneyos-24-vm"
      "zaneyos-oem"
    ];
  in {
    nixosConfigurations = builtins.listToAttrs (map (host: {
        name = host;
        value = mkNixosConfig host;
      })
      hosts);

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
