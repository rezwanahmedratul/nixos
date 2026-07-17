{
  config,
  pkgs,
  ...
}: let
  inherit (config.zaneyos) thunarEnable;
in {
  programs = {
    thunar = {
      enable = thunarEnable;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
  };
  environment.systemPackages = with pkgs; [
    ffmpegthumbnailer # Need For Video / Image Preview
  ];
}
