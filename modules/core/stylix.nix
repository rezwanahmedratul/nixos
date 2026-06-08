{
  pkgs,
  host,
  ...
}: let
  inherit (import ../../hosts/${host}/variables.nix) stylixImage;
in {
  # Styling Options
  stylix = {
    enable = true;
    image = stylixImage;
    # base16Scheme = "gruvbox-dark-medium";

    targets.kmscon.enable = false;
    # base16Scheme = {
    #   base00 = "282828";
    #   base01 = "3c3836";
    #   base02 = "504945";
    #   base03 = "665c54";
    #   base04 = "bdae93";
    #   base05 = "d5c4a1";
    #   base06 = "ebdbb2";
    #   base07 = "fbf1c7";
    #   base08 = "fb4934";
    #   base09 = "fe8019";
    #   base0A = "fabd2f";
    #   base0B = "b8bb26";
    #   base0C = "8ec07c";
    #   base0D = "83a598";
    #   base0E = "d3869b";
    #   base0F = "d65d0e";
    # };

    # catpuccin mocha base16Scheme

    base16Scheme = {
      base00 = "1e1e2e"; # base
      base01 = "181825"; # mantle
      base02 = "313244"; # surface0
      base03 = "45475a"; # surface1
      base04 = "585b70"; # surface2
      base05 = "cdd6f4"; # text
      base06 = "f5e0dc"; # rosewater
      base07 = "b4befe"; # lavender
      base08 = "f38ba8"; # red
      base09 = "fab387"; # peach
      base0A = "f9e2af"; # yellow
      base0B = "a6e3a1"; # green
      base0C = "94e2d5"; # teal
      base0D = "89b4fa"; # blue
      base0E = "cba6f7"; # mauve
      base0F = "f2cdcd"; # flamingo
    };

    polarity = "dark";
    opacity.terminal = 0.6;
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 23;
    };
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrains Mono";
      };
      sansSerif = {
        package = pkgs.montserrat;
        name = "Montserrat";
      };
      serif = {
        package = pkgs.montserrat;
        name = "Montserrat";
      };
      sizes = {
        applications = 12;
        terminal = 10;
        desktop = 11;
        popups = 10;
      };
    };
    # opacity = {
    #   applications = 0.1;
    #   popups = 1.0;
    #   terminal = 1.0;
    #   desktop = 0.1;
    # };
  };
}
