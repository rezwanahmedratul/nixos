# HOWTO: Install and Remove Flatpaks on ddubsOS

This guide explains how Flatpak apps are managed in ddubsOS and how to add or remove them. It is based on the configuration in modules/core/flatpak.nix.

Summary

- Flatpaks are declared in modules/core/flatpak.nix under services.flatpak.packages.
- Adding or removing an app requires a system rebuild to apply changes.
- By default, ddubsOS updates Flatpaks automatically on rebuilds (update.onActivation = true).

Where the configuration lives

- File: modules/core/flatpak.nix
- Key attributes:
  - services.flatpak.enable = true;
  - services.flatpak.packages = [ ... ]; # list of Flatpak app IDs
  - services.flatpak.update.onActivation = true; # update Flatpaks on rebuild activation

How to add a Flatpak app

1. Open modules/core/flatpak.nix.

Example: current modules/core/flatpak.nix

```nix
{...}: {
  services = {
    flatpak = {
      enable = true;

      # List the Flatpak applications you want to install
      # Use the official Flatpak application ID (e.g., from flathub.org)
      packages = [
        "com.github.tchx84.Flatseal" # manage flatpak permissions
        #"com.rtosta.zapzap"          #whatsapp client
        "io.github.flattool.Warehouse" # Manage flatpaks
        "it.mijorus.gearlever" # Manage AppImages
        "io.github.freedoom.Phase1" # classic doom
        "io.github.freedoom.Phase2" # classic doom
        #"io.github.dvlv.boxbuddyrs" #GUI for distrobox but I use native package
        "com.github.k4zmu2a.spacecadetpinball"
        "de.schmidhuberj.tubefeeder" # watch YT videos
        # If you prefer the native OBS, comment this out
        # and set `enableObs=true;` in your hosts `variables.nix` file
        # Note the flatpak is the officialy support package
        "com.obsproject.Studio"
        # "io.github.chidiwilliams.Buzz"  # Local voice transcription 50-50
        # Add other Flatpak IDs here, e.g., "org.mozilla.firefox"
      ];

      # Optional: Automatically update Flatpaks when you run nixos-rebuild swit ch
      update.onActivation = true;
    };
  };
}
```

2. Locate the packages list under services.flatpak.packages.
3. Add the Flatpak application ID (as listed on Flathub) to the array.
   - Example IDs from the default config:
     - "com.github.tchx84.Flatseal" (Flatseal — manage Flatpak permissions)
     - "io.github.flattool.Warehouse" (Warehouse — manage Flatpaks)
       - "com.obsproject.Studio" (OBS Studio — official Flatpak)

Note: To find the correct Flatpak ID, search for the app on Flathub and copy the ID shown on its page (e.g., org.mozilla.firefox): https://flathub.org

4. Save the file.
5. Rebuild the system to install the new app:
   - zcli rebuild
   - or use your alias fr (flake rebuild)

How to remove a Flatpak app

1. Open modules/core/flatpak.nix.
2. Remove the app’s ID from services.flatpak.packages.
3. Save the file.
4. Rebuild the system to uninstall it from your declarative config:
   - zcli rebuild

Notes about OBS (example)

- The config includes com.obsproject.Studio by default (official Flatpak).
- If you prefer the native OBS package, comment out the Flatpak entry and set enableObs = true; in your host’s variables.nix as noted in comments.

Automatic updates on rebuild

- update.onActivation = true means Flatpaks will be updated when you rebuild and activate the new generation. This helps keep Flatpaks current automatically.

Tips

- Find Flatpak IDs on https://flathub.org by searching the app and copying the ID (e.g., org.mozilla.firefox).
- After rebuild, you can verify installs with:
  - flatpak list
- Permissions and sandboxing can be tuned with Flatseal (included by default).
