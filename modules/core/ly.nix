{
  host,
  lib,
  ...
}: let
  # Import the host-specific variables.nix
  vars = import ../../hosts/${host}/variables.nix;
  useLy = vars.displayManager == "tui";
in {
  config = lib.mkIf useLy {
    # Prefer ly when TUI is selected; avoid greetd conflicts
    services.greetd.enable = lib.mkDefault false;

    services.displayManager.ly = {
      enable = true;
      settings = {
        #animation = "matrix";
        bigclock = true;
        # --- Color Settings (0xAARRGGBB) ---
        # Background color of dialog box (Black)
        bg = "0x00000000";
        # Foreground text color (Cyan: #00FFFF)
        fg = "0x0000FFFF";
        # Border color (Red: #FF0000)
        border_fg = "0x00FF0000";
        # Error message color (Red)
        error_fg = "0x00FF0000";
        # Clock color (Purple: #800080)
        clock_color = "#800080";
      };
    };
  };
}
