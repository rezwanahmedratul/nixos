{zaneyos, ...}: let
  inherit
    (zaneyos)
    barChoice
    browser
    terminal
    ;

  # Noctalia-specific bindings (only included when barChoice == "noctalia")
  noctaliaBind =
    if barChoice == "noctalia"
    then [
      "ALT,SPACE, Noctalia Launcher, exec, noctalia msg panel-toggle launcher"
      "$modifier SHIFT,Return, Noctalia Launcher, exec, noctalia msg panel-toggle launcher"
      "$modifier,M, Noctalia Notifications, exec, noctalia msg panel-toggle control-center notifications"
      "$modifier CTRL,V, Noctalia Clipboard, exec, noctalia msg panel-toggle clipboard"
      "$modifier ALT,P, Noctalia Settings, exec, noctalia msg settings-toggle"
      "$modifier SHIFT,comma, Noctalia Settings, exec, noctalia msg settings-toggle"
      "$modifier, L, Noctalia Lock Screen, exec, noctalia msg session lock"
      "$modifier SHIFT,W, Noctalia Wallpaper, exec, noctalia msg panel-toggle wallpaper"
      "$modifier,P, Noctalia Power Menu, exec, noctalia msg panel-toggle session"
      "$modifier,C, Noctalia Control Center, exec, noctalia msg panel-toggle control-center"
      "$modifier ALT,S, Noctalia Screenshot Region, exec, noctalia msg screenshot-region"
      "$modifier SHIFT,R, Restart Noctalia shell, exec, restart.noctalia"
    ]
    else [];

  # Quickshell II specific bindings (only included when barChoice == "quickshell")
  quickshellBind =
    if barChoice == "quickshell"
    then [
      "ALT,SPACE, Quickshell Launcher, global, quickshell:searchToggleRelease"
      "$modifier,SPACE, Quickshell Launcher, global, quickshell:searchToggleRelease"
      "$modifier SHIFT,Return, Quickshell Launcher, global, quickshell:searchToggleRelease"
      "$modifier,N, Quickshell Right Sidebar, global, quickshell:sidebarRightToggle"
      "$modifier,A, Quickshell Left Sidebar, global, quickshell:sidebarLeftToggle"
      "$modifier CTRL,V, Quickshell Clipboard, global, quickshell:overviewClipboardToggle"
      "$modifier,Period, Quickshell Emoji Picker, global, quickshell:overviewEmojiToggle"
      "$modifier,Slash, Quickshell Cheatsheet, global, quickshell:cheatsheetToggle"
      "$modifier,K, Quickshell On-Screen Keyboard, global, quickshell:oskToggle"
      "$modifier,M, Quickshell Media Controls, global, quickshell:mediaControlsToggle"
      "$modifier,G, Quickshell Widget Overlay, global, quickshell:overlayToggle"
      "$modifier,J, Quickshell Toggle Bar, global, quickshell:barToggle"
      "CTRL ALT,Delete, Quickshell Session Menu, global, quickshell:sessionToggle"
      "$modifier CTRL,T, Quickshell Wallpaper Selector, global, quickshell:wallpaperSelectorToggle"
      "$modifier CTRL SHIFT,D, Quickshell Toggle Light/Dark, global, quickshell:toggleLightDark"
      "$modifier CTRL,P, Quickshell Cycle Panel Family, global, quickshell:panelFamilyCycle"
      "$modifier SHIFT,R, Restart Quickshell, exec, killall ydotool qs quickshell; qs -c ii &"
      "$modifier SHIFT,W, Quickshell Wallpaper Selector, global, quickshell:wallpaperSelectorToggle"
      "$modifier,P, Quickshell Session Menu, global, quickshell:sessionToggle"
      "$modifier,C, Quickshell Quick Toggles, global, quickshell:sidebarRightToggle"
      "$modifier ALT,S, Quickshell Screen Snip, global, quickshell:regionScreenshot"
      "$modifier SHIFT,X, Quickshell OCR, global, quickshell:regionOcr"
      "$modifier SHIFT,T, Quickshell Screen Translate, global, quickshell:screenTranslate"
      "$modifier SHIFT,S, Quickshell Region Record, global, quickshell:regionRecord"
    ]
    else [];

  # Rofi launcher bindings (only included when not noctalia and not quickshell)
  rofiBind =
    if barChoice != "noctalia" && barChoice != "quickshell"
    then [
      "$modifier,D, Rofi Launcher, exec, rofi-launcher"
      "$modifier SHIFT,Return, Rofi Launcher, exec, rofi-launcher"
    ]
    else [];

  # Rofi clipboard binding (only included when not noctalia and not quickshell)
  rofiClipboardBind =
    if barChoice != "noctalia" && barChoice != "quickshell"
    then [
      "$modifier,V, Clipboard History, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
    ]
    else [];

  # Wallpaper binding (only included when not noctalia and not quickshell)
  wallpaperBind =
    if barChoice != "noctalia" && barChoice != "quickshell"
    then [
      "$modifier SHIFT,W, QS Wallpaper Setter, exec, qs-wallpapers-apply"
    ]
    else [];

  # Overview binding
  overviewBind =
    if barChoice == "quickshell"
    then [
      "$modifier,Tab, Quickshell Overview, global, quickshell:overviewWorkspacesToggle"
    ]
    else [
      "$modifier,Tab, QS Overview, exec, qs ipc -c overview call overview toggle"
    ];
in {
  wayland.windowManager.hyprland.settings = {
    bindd =
      noctaliaBind
      ++ quickshellBind
      ++ rofiBind
      ++ rofiClipboardBind
      ++ wallpaperBind
      ++ overviewBind
      ++ [
        # ============= WORKSPACE OVERVIEW =============
        "$modifier CTRL,D, Toggle Dock, exec, dock"
        # ============= TERMINALS =============
        "$modifier,Return, Terminal, exec, ${terminal}"
        # ============= APPLICATION LAUNCHERS =============
        "$modifier,K, Keybinds Search Tool, exec, qs-keybinds"
        "$modifier CTRL,C, Cheatsheets Viewer, exec, qs-cheatsheets"
        "$modifier SHIFT,K, Keybinds Search Tool, exec, qs-keybinds"
        "$modifier SHIFT,D, Discord, exec, discord"
        "$modifier ALT,W, Web Search, exec, web-search"
        "$modifier SHIFT,N, Notification Reset, exec, swaync-client -rs"
        "$modifier,B, Web Browser, exec, ${browser}"
        "$modifier,Y, File Manager, exec, kitty -e yazi"
        "$modifier,F, File Manager, exec, nautilus"
        "$modifier,E, Emoji Picker, exec, emopicker9000"
        "$modifier,S, Screenshot, exec, screenshootin"

        "$modifier CTRL,Z, Open NixOS in VS Code, exec, code ~/nixos"
        "$modifier CTRL,C, Open Competitive Programming in VS Code, exec, code ~/Github/CP"
        "$modifier ALT,C, Competitive Programming Mode, exec, cp-session"
        #"$modifier CTRL,R, Rebuild Nix Config, exec, ghostty -e zsh -ic 'fr'"
        "$modifier ALT, P, Power Off, exec, poweroff"
        "$modifier ALT, R, Reboot, exec, reboot"

        # ============= SCREENSHOTS =============
        "$modifier CTRL,S, Screenshot Output, exec, hyprshot -m output -o $HOME/Pictures/ScreenShots"
        "$modifier SHIFT,S, Screenshot Window, exec, hyprshot -m window -o $HOME/Pictures/ScreenShots"
        "$modifier ALT,S, Screenshot Region, exec, hyprshot -m region -o $HOME/Pictures/ScreenShots"
        "$modifier SHIFT,Z, Screenshot Region Clipboard, exec, hyprshot -m region --clipboard-only"
        "$modifier SHIFT, A, Grab Text from Region, exec, ocr-region"

        "$modifier CTRL,R, Screen Recorder, exec, screenrecord"
        "$modifier,O, OBS Studio, exec, obs"

        "$modifier ALT,C, Color Picker, exec, hyprpicker -a"
        "$modifier,G, GIMP, exec, gimp"
        "$modifier SHIFT,T, Dropdown Terminal, exec, sh -lc 'DropTerminal'"
        "$modifier,T, Thunar, exec, thunar"
        "$modifier ALT,M, Audio Control, exec, pavucontrol"

        # ============= WINDOW MANAGEMENT =============
        "$modifier,X, Kill Active Window, killactive,"
        "$modifier,P, Pseudo Tile, pseudo,"
        "$modifier SHIFT,I, Toggle Split, layoutmsg, togglesplit"
        "$modifier,F11, Fullscreen, fullscreen,"
        "$modifier,Space, Toggle Floating, togglefloating,"
        "$modifier,F, Maximize Window, fullscreen, 1"

        # ============= WORKSPACE NAVIGATION =============
        "$modifier,1, Workspace 1, workspace, 1"
        "$modifier,2, Workspace 2, workspace, 2"
        "$modifier,3, Workspace 3, workspace, 3"
        "$modifier,4, Workspace 4, workspace, 4"
        "$modifier,5, Workspace 5, workspace, 5"
        "$modifier,6, Workspace 6, workspace, 6"
        "$modifier,7, Workspace 7, workspace, 7"
        "$modifier,8, Workspace 8, workspace, 8"
        "$modifier,9, Workspace 9, workspace, 9"
        "$modifier,0, Workspace 10, workspace, 10"

        # Move Active Window To Workspace
        "$modifier SHIFT,1, Move Window to Workspace 1, movetoworkspace, 1"
        "$modifier SHIFT,2, Move Window to Workspace 2, movetoworkspace, 2"
        "$modifier SHIFT,3, Move Window to Workspace 3, movetoworkspace, 3"
        "$modifier SHIFT,4, Move Window to Workspace 4, movetoworkspace, 4"
        "$modifier SHIFT,5, Move Window to Workspace 5, movetoworkspace, 5"
        "$modifier SHIFT,6, Move Window to Workspace 6, movetoworkspace, 6"
        "$modifier SHIFT,7, Move Window to Workspace 7, movetoworkspace, 7"
        "$modifier SHIFT,8, Move Window to Workspace 8, movetoworkspace, 8"
        "$modifier SHIFT,9, Move Window to Workspace 9, movetoworkspace, 9"
        "$modifier SHIFT,0, Move Window to Workspace 10, movetoworkspace, 10"

        # ============= FOCUS MOVEMENT =============
        "$modifier,left, Focus Left, movefocus, l"
        "$modifier,right, Focus Right, movefocus, r"
        "$modifier,up, Focus Up, movefocus, u"
        "$modifier,down, Focus Down, movefocus, d"
        "$modifier,h, Focus Left, movefocus, l"
        "$modifier,l, Focus Right, movefocus, r"
        "$modifier,k, Focus Up, movefocus, u"
        "$modifier,j, Focus Down, movefocus, d"

        # Move Active Window
        "$modifier SHIFT,left, Move Window Left, movewindow, l"
        "$modifier SHIFT,right, Move Window Right, movewindow, r"
        "$modifier SHIFT,up, Move Window Up, movewindow, u"
        "$modifier SHIFT,down, Move Window Down, movewindow, d"
        "$modifier SHIFT,h, Move Window Left, movewindow, l"
        "$modifier SHIFT,l, Move Window Right, movewindow, r"
        "$modifier SHIFT,k, Move Window Up, movewindow, u"
        "$modifier SHIFT,j, Move Window Down, movewindow, d"

        # ============= SPECIAL WORKSPACE (SCRATCHPAD) =============
        "$modifier,S, Toggle Special Workspace, togglespecialworkspace, magic"
        "$modifier SHIFT,U, Move to Special Workspace, movetoworkspace, special:magic"

        # ============= SCROLL THROUGH WORKSPACES =============
        "$modifier,mouse_down, Next Workspace, workspace, e+1"
        "$modifier,mouse_up, Previous Workspace, workspace, e-1"

        # ============= HARDWARE CONTROLS =============
        # Volume Keys
        ",XF86AudioLowerVolume, Volume Down, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioRaiseVolume, Volume Up, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioMute, Mute Audio, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, Mute Mic, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

        # Brightness Keys
        ",XF86MonBrightnessDown, Brightness Down, exec, brightnessctl set 5%-"
        ",XF86MonBrightnessUp, Brightness Up, exec, brightnessctl set +5%"

        # Media Keys
        ",XF86AudioPlay, Play/Pause Media, exec, playerctl play-pause"
        ",XF86AudioNext, Next Track, exec, playerctl next"
        ",XF86AudioPrev, Previous Track, exec, playerctl previous"
      ];
    bindm = [
      "$modifier,mouse:272,movewindow"
      "$modifier,mouse:273,resizewindow"
    ];
  };
}
