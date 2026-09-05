{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      dejavu_fonts
      font-awesome
      hackgen-nf-font
      ibm-plex
      inter
      material-icons
      maple-mono.NF
      minecraftia
      nerd-fonts.im-writing
      nerd-fonts.blex-mono
      nerd-fonts.iosevka-term
      nerd-fonts.lilex
      nerd-fonts.ubuntu
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-mono
      nerd-fonts.fira-code
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-monochrome-emoji
      roboto
      roboto-mono
      symbola
      terminus_font
    ];
  };
}
