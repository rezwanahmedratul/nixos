{
  zaneyos,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (zaneyos) extraMonitorSettings;
  keyboardLayout = zaneyos.keyboardLayout;
  keyboardVariant = zaneyos.keyboardVariant;
  toLua = lib.generators.toLua { };

  # Treat only known US-based variants as implying layout = "us".
  usVariants = [
    "dvorak"
    "colemak"
    "workman"
    "intl"
    "us-intl"
    "altgr-intl"
  ];
  normalizeUSVariant = v: if v == "us-intl" then "intl" else v;

  # If layout itself is a US variant (e.g., "dvorak", "us-intl"), normalize it
  layoutFromLayout = if builtins.elem keyboardLayout usVariants then "us" else keyboardLayout;
  variantFromLayout =
    if builtins.elem keyboardLayout usVariants then normalizeUSVariant keyboardLayout else "";

  # If the provided variant is a US variant, force layout to us; otherwise keep layout
  layoutFromVariant = if builtins.elem keyboardVariant usVariants then "us" else layoutFromLayout;
  variantFinal =
    if builtins.elem keyboardVariant usVariants then
      normalizeUSVariant keyboardVariant
    else if variantFromLayout != "" then
      variantFromLayout
    else
      keyboardVariant;

  hyprKbLayout = layoutFromVariant;
  hyprKbVariant = variantFinal;

  bindSettings =
    (import ./binds.nix { inherit zaneyos; }).wayland.windowManager.hyprland.settings or { };
  binddEntries = bindSettings.bindd or [ ];
  bindmEntries = bindSettings.bindm or [ ];

  envEntries = ((import ./env.nix { }).wayland.windowManager.hyprland.settings.env or [ ]);
  execOnceEntries = (
    (import ./exec-once.nix { inherit zaneyos; }).wayland.windowManager.hyprland.settings.exec-once
      or [ ]
  );
  animationSettings = (
    (import zaneyos.animChoice { }).wayland.windowManager.hyprland.settings.animations or { }
  );
  windowRulesHyprlang = (
    (import ./windowrules.nix { }).wayland.windowManager.hyprland.extraConfig or ""
  );

  monitorLines = [
    "monitor=,preferred,auto,auto"
    "monitor=Virtual-1,1920x1080@60,auto,1"
  ]
  ++ builtins.filter (line: line != "") (
    map lib.strings.trim (lib.splitString "\n" extraMonitorSettings)
  );

  zaneyosLuaConfig = {
    modifier = "SUPER";
    keyboard = {
      layout = hyprKbLayout;
      variant = hyprKbVariant;
    };
    theme = {
      base01 = config.lib.stylix.colors.base01;
      base08 = config.lib.stylix.colors.base08;
      base0C = config.lib.stylix.colors.base0C;
    };
    env = envEntries;
    execOnce = execOnceEntries;
    bindd = binddEntries;
    bindm = bindmEntries;
    monitorLines = monitorLines;
    animation = {
      enabled = animationSettings.enabled or true;
      bezier = animationSettings.bezier or [ ];
      animation = animationSettings.animation or [ ];
    };
    windowRulesHyprlang = windowRulesHyprlang;
  };
in
{
  home.packages = with pkgs; [
    awww
    grim
    slurp
    wl-clipboard
    swappy
    ydotool
    hyprpolkitagent
    hyprshot
    hyprshutdown
    hyprpicker
    #hyprland-qtutils # needed for banners and ANR messages
  ];
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];
  # Place Files Inside Home Directory
  home.file = {
    "Pictures/Wallpapers" = {
      source = ../../../wallpapers;
      recursive = true;
    };
    ".face.icon".source = ./face.jpg;
    ".config/face.jpg".source = ./face.jpg;
  };
  wayland.windowManager.hyprland = {
    configType = "lua";
    enable = true;
    package = pkgs.hyprland;
    systemd = {
      enable = true;
      enableXdgAutostart = true;
      variables = [ "--all" ];
    };
    xwayland = {
      enable = true;
    };
    extraConfig = ''
      require("zaneyos.vars")
      require("zaneyos.settings")
      require("zaneyos.monitors")
      require("zaneyos.env")
      require("zaneyos.animations")
      require("zaneyos.window_rules")
      require("zaneyos.startup")
      require("zaneyos.keybinds")
    '';
    extraLuaFiles = {
      "zaneyos.vars" = {
        autoLoad = false;
        content = ''
          ZANEYOS = ${toLua zaneyosLuaConfig}
        '';
      };
      "zaneyos.settings" = {
        autoLoad = false;
        content = ./lua/settings.lua;
      };
      "zaneyos.monitors" = {
        autoLoad = false;
        content = ./lua/monitors.lua;
      };
      "zaneyos.env" = {
        autoLoad = false;
        content = ./lua/env.lua;
      };
      "zaneyos.animations" = {
        autoLoad = false;
        content = ./lua/animations.lua;
      };
      "zaneyos.window_rules" = {
        autoLoad = false;
        content = ./lua/window_rules.lua;
      };
      "zaneyos.startup" = {
        autoLoad = false;
        content = ./lua/startup.lua;
      };
      "zaneyos.keybinds" = {
        autoLoad = false;
        content = ./lua/keybinds.lua;
      };
    };
  };
}
