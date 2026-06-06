{
  pkgs,
  inputs,
  ...
}: {
  home.packages.pkgs = [
    ab-download-manager;
  ];
}
