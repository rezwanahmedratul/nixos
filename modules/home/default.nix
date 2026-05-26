{zaneyos, ...}: let
  inherit (zaneyos) barChoice waybarChoice;
  neovimConfig = zaneyos.neovimConfig or "nixvim";

  # Select bar module based on barChoice
  barModule =
    if barChoice == "noctalia"
    then ./noctalia.nix
    else waybarChoice;
in {
  imports =
    [
      ./terminals/alacritty.nix
      ./amfora.nix
      ./editors/antigravity.nix
      ./bash.nix
      ./bashrc-personal.nix
      ./overview.nix
      ./python.nix
      ./cli/bat.nix
      ./cli/btop.nix
      ./cli/bottom.nix
      ./cli/cava.nix
      ./editors/doom-emacs.nix
      ./editors/doom-emacs-install.nix
      ./emoji.nix
      ./editors/evil-helix.nix
      ./eza.nix
      ./fastfetch
      ./cli/fzf.nix
      ./cli/gh.nix
      ./terminals/ghostty.nix
      ./cli/git.nix
      ./gtk.nix
      ./cli/htop.nix
      ./hyprland
      ./terminals/kitty.nix
      ./cli/lazygit.nix
      ./obs-studio.nix
      ./editors/nano.nix
      ./rofi
      ./qt.nix
      ./scripts
      ./scripts/gemini-cli.nix
      ./stylix.nix
      ./swappy.nix
      ./swaync.nix
      ./tealdeer.nix
      ./terminals/tmux.nix
      ./virtmanager.nix
      ./editors/vscode.nix
      ./terminals/wezterm.nix
      barModule
      ./wlogout
      ./xdg.nix
      ./yazi
      #./zen-browser.nix
      ./zoxide.nix
      ./zsh
    ]
    ++ (
      if neovimConfig == "nixvim"
      then [./editors/nixvim.nix]
      else [./editors/nvf.nix]
    );
}
