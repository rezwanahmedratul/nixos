{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    keyMode = "vi";
    baseIndex = 1;
    clock24 = false;

    extraConfig = ''
      set-option -g status-position top
      set -ga terminal-overrides ",*:RGB"
      set -g default-terminal "tmux-256color"
      set-option -g history-limit 5000
      set -g renumber-windows on
      set -g set-clipboard on

      # Start windows and panes at 1
      setw -g pane-base-index 1

      # Tokyonight Moon theme
      set -g status on
      set -g status-bg "#222436"
      set -g status-justify left
      set -g status-left-length 100
      set -g status-right-length 100

      # Messages
      set -g message-style "fg=#86e1fc,bg=#3a3f5a,align=centre"
      set -g message-command-style "fg=#86e1fc,bg=#3a3f5a,align=centre"

      # Panes
      set -g pane-border-style "fg=#3a3f5a"
      set -g pane-active-border-style "fg=#82aaff"

      # Windows
      set -g window-status-activity-style "fg=#c8d3f5,bg=#222436,none"
      set -g window-status-separator ""
      set -g window-status-style "fg=#c8d3f5,bg=#222436,none"

      # Current window
      set -g window-status-current-format "#[fg=#82aaff,bg=#222436] #I: #[fg=#c099ff,bg=#222436](✓) #[fg=#86e1fc,bg=#222436]#W"

      # Other windows
      set -g window-status-format "#[fg=#82aaff,bg=#222436] #I: #[fg=#c8d3f5,bg=#222436]#W"

      # Right side
      set -g status-right "#[fg=#82aaff,bg=#222436,nobold,nounderscore,noitalics]#[fg=#222436,bg=#82aaff,nobold,nounderscore,noitalics] #[fg=#c8d3f5,bg=#3a3f5a] #W #[fg=#c8d3f5,bg=#3a3f5a] #S "

      set -g status-left ""

      # Modes
      set -g clock-mode-colour "#82aaff"
      set -g mode-style "fg=#82aaff bg=#444a73 bold"
    '';
  };
}