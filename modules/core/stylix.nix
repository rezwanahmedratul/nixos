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
