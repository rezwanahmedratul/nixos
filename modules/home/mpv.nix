{
  config,
  pkgs,
  ...
}: {
  programs.mpv = {
    enable = true;

    bindings = {
      # ########## Playback ##########
      "SPACE" = "cycle pause";
      "q" = "quit";
      "f" = "cycle fullscreen";
      "m" = "cycle mute";
      "l" = "cycle loop-file";

      # ########## Seeking ##########
      "LEFT" = "seek -5";
      "RIGHT" = "seek 5";
      "UP" = "add volume 5";
      "DOWN" = "add volume -5";
      "Ctrl+LEFT" = "seek -60";
      "Ctrl+RIGHT" = "seek 60";
      "Shift+UP" = "add volume 1";
      "Shift+DOWN" = "add volume -1";

      # ########## Volume ##########
      "+" = "seek 5";
      "-" = "seek -5";
      "9" = "add volume -2";
      "0" = "add volume 2";

      # ########## Speed ##########
      "[" = "add speed -0.1";
      "]" = "add speed 0.1";
      "\\" = "set speed 1.0";

      # ########## Video Adjust ##########
      "b" = "add brightness 5";
      "B" = "add brightness -5";
      "c" = "add contrast 5";
      "C" = "add contrast -5";
      "s" = "add saturation 5";
      "S" = "add saturation -5";

      # ########## Subtitles ##########
      "v" = "cycle sub";
      "V" = "cycle sub down";
      "j" = "cycle sub-delay";
      "J" = "cycle sub-delay -1";
      "z" = "add sub-scale 0.1";
      "Z" = "add sub-scale -0.1";

      # ########## Audio Tracks ##########
      "a" = "cycle audio";
      "A" = "cycle audio down";

      # ########## Screenshots ##########
      "p" = "screenshot";
      "P" = "screenshot video";
    };
  };
}
