{
  zaneyos,
  pkgs,
  backupFiles ? [".config/mimeapps.list.backup"],
  ...
}: let
  backupFilesString = pkgs.lib.strings.concatStringsSep " " backupFiles;

  # Create the get-doom script as a dependency
  get-doom-script = pkgs.writeShellScriptBin "get-doom" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # --- Icons ---
    ICON_CHECK="✔"
    ICON_INFO="ℹ"
    ICON_ROCKET="🚀"

    # --- Helper Functions ---
    print_status() {
      echo
      echo "--- $ICON_INFO $1 ---"
    }

    print_success() {
      echo "--- $ICON_CHECK $1 ---"
    }

    print_banner() {
      echo "==============================="
      echo " Doom Emacs Installer $ICON_ROCKET"
      echo "==============================="
    }

    is_doom_installed() {
      local dir="$1"
      [[ -x "$dir/bin/doom" ]] && [[ -f "$dir/core/doom.el" || -f "$dir/lisp/doom.el" ]]
    }

    emacsdir_is_empty() {
      local dir="$1"
      [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]
    }

    find_existing_doom_dir() {
      local candidate
      for candidate in "$HOME/.emacs.d" "$HOME/.config/emacs"; do
        if is_doom_installed "$candidate"; then
          echo "$candidate"
          return 0
        fi
      done
      return 1
    }

    # --- Main Script ---
    print_banner
    if existing_dir="$(find_existing_doom_dir)"; then
      print_success "Doom Emacs is already installed at $existing_dir."
      exit 0
    fi

    EMACSDIR="$HOME/.emacs.d"

    if [[ -d "$EMACSDIR" ]]; then
      if emacsdir_is_empty "$EMACSDIR"; then
        print_status "Found empty $EMACSDIR; proceeding to install Doom Emacs into it..."
      else
        echo "Error: Found $EMACSDIR but it does not look like a Doom Emacs installation." >&2
        echo "Refusing to overwrite a non-empty directory. Move it away and re-run, e.g.:" >&2
        echo "  mv \"$EMACSDIR\" \"$EMACSDIR.bak\"" >&2
        exit 1
      fi
    fi

    print_status "Cloning Doom Emacs..."
    ${pkgs.git}/bin/git clone --depth 1 https://github.com/doomemacs/doomemacs "$EMACSDIR"
    print_success "Doom Emacs cloned."

    print_status "Running Doom install..."
    "$EMACSDIR/bin/doom" install
    print_success "Doom install complete."

    print_status "Running doom sync..."
    "$EMACSDIR/bin/doom" sync
    print_success "Doom sync complete."

    echo
    print_success "All done! Doom Emacs is ready to use."
  '';
in
  pkgs.writeShellScriptBin "zcli" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    # --- Program info ---
    #
    # zcli - NixOS System Management CLI
    # ==================================
    #
    #    Purpose: NixOS system management utility for ZaneyOS distribution
    #     Author: Don Williams (ddubs) & Zaney
    # Start Date: June 7th, 2025
    #    Version: 1.0.3
    #
    # Architecture:
    # - Nix-generated shell script using writeShellScriptBin
    # - Configuration via Nix parameters (profile, backupFiles)
    # - Uses 'nh' tool for NixOS operations, 'inxi' for diagnostics
    # - Git integration for host configuration versioning
    #
    # Helper Functions:
    # verify_hostname()     - Validates current hostname against flake.nix host variable
    #                        Exits with error if mismatch or missing host directory
    # detect_gpu_profile()  - Parses lspci output to identify GPU hardware
    #                        Returns: nvidia/nvidia-laptop/amd-hybrid/amd/intel/vm/empty
    # handle_backups()      - Removes files listed in BACKUP_FILES array from $HOME
    # parse_nh_args()      - Parses command-line arguments for nh operations
    # print_help()         - Outputs command usage and available operations
    #
    # Command Functions:
    # cleanup              - Interactive cleanup of old generations via 'nh clean'
    # diag                 - Generate system report using 'inxi --full'
    # list-gens           - Display user/system generations via nix-env and nix profile
    # rebuild             - NixOS rebuild using 'nh os switch'
    # rebuild-boot        - NixOS rebuild for next boot using 'nh os boot'
    # trim                - SSD optimization via 'sudo fstrim -v /'
    # update              - Flake update + rebuild using 'nh os switch --update'
    # update-host         - Modify flake.nix host/profile variables via sed
    # add-host            - Add new host configuration
    # del-host            - Delete host configuration
    # doom [sub]          - Doom Emacs management (install/status/remove/update)
    #
    # Variables:
    # PROJECT             - Base directory name (ddubsos/zaneyos)
    # PROFILE             - Hardware profile from Nix parameter
    # BACKUP_FILES        - Array of backup file paths to clean
    # FLAKE_NIX_PATH      - Path to flake.nix for host/profile updates
    #


    # --- Configuration ---
    PROJECT="zaneyos"   # ddubos or zaneyos
    VERSION="1.0.3"
    BACKUP_FILES_STR="${backupFilesString}"
    FLAKE_DIR="$HOME/$PROJECT"
    FLAKE_NIX_PATH="$FLAKE_DIR/flake.nix"

    read -r -a BACKUP_FILES <<< "$BACKUP_FILES_STR"

    # --- Helper Functions ---
    verify_hostname() {
      local current_hostname
      current_hostname="$(${pkgs.nettools}/bin/hostname)"

      if [ ! -f "$FLAKE_NIX_PATH" ]; then
        echo "Error: Flake.nix not found at $FLAKE_NIX_PATH" >&2
        exit 1
      fi

      # Check if a matching host folder exists under hosts/
      local folder="$FLAKE_DIR/hosts/$current_hostname"
      if [ ! -d "$folder" ]; then
        echo "Error: Matching host not found in $PROJECT. Missing: $folder" >&2
        echo "Hint: Run 'zcli update-host' to create it (copies hosts/default) or run 'zcli update-host $current_hostname <profile>'." >&2
        exit 1
      fi
    }

    print_help() {
      echo "ZaneyOS CLI Utility -- version $VERSION"
      echo ""
      echo "Usage: zcli [command] [options]"
      echo ""
      echo "Commands:"
      echo "  Host management:"
      echo "    add-host        - Create host from template and add to flake.nix hosts list."
      echo "                     (Opt: zcli add-host [hostname] [profile])"
      echo "    del-host        - Remove host directory and prune from flake.nix hosts list."
      echo "                     (Usage: zcli del-host [hostname])"
      echo "    list-hosts      - Show current hosts from flake.nix (prints the hosts array)."
      echo "    update-host     - Auto set host and profile in flake.nix."
      echo "                     (Opt: zcli update-host [hostname] [profile])"
      echo ""
      echo "  Build and updates:"
      echo "    rebuild         - Rebuild the NixOS system configuration."
      echo "    rebuild-boot    - Rebuild and set as boot default (activates on next restart)."
      echo "    update          - Update the flake and rebuild the system."
      echo ""
      echo "  Maintenance:"
      echo "    cleanup         - Clean up old system generations. Can specify a number to keep."
      echo "    diag            - Create a system diagnostic report (saved to ~/diag.txt)."
      echo "    list-gens       - List user and system generations."
      echo "    trim            - Trim filesystems to improve SSD performance."
      echo ""
      echo "  Doom Emacs:"
      echo "    doom install    - Install Doom Emacs using get-doom script."
      echo "    doom status     - Check if Doom Emacs is installed."
      echo "    doom remove     - Remove Doom Emacs installation."
      echo "    doom update     - Update Doom Emacs (runs doom upgrade + sync)."
      echo ""
      echo "Options for rebuild, rebuild-boot, and update commands:"
      echo "  --dry, -n        - Show what would be done without doing it"
      echo "  --ask, -a        - Ask for confirmation before proceeding"
      echo "  --cores N        - Limit build to N cores (useful for VMs)"
      echo "  --verbose, -v    - Show verbose output"
      echo "  --no-nom         - Don't use nix-output-monitor"
      echo ""
      echo "  help             - Show this help message."
    }

    handle_backups() {
      if [ ''${#BACKUP_FILES[@]} -eq 0 ]; then
        echo "No backup files configured to check."
        return
      fi

      echo "Checking for backup files to remove..."
      for file_path in "''${BACKUP_FILES[@]}"; do
        full_path="$HOME/$file_path"
        if [ -f "$full_path" ]; then
          echo "Removing stale backup file: $full_path"
          rm "$full_path"
        fi
      done
    }

    detect_gpu_profile() {
      local detected_profile=""
      local has_nvidia=false
      local has_intel=false
      local has_amd=false
      local has_vm=false
      # Prefer hypervisor detection first to avoid misclassifying VMs as AMD
      if ${pkgs.systemd}/bin/systemd-detect-virt -q; then
        echo "vm"
        return
      fi

      if ${pkgs.pciutils}/bin/lspci &> /dev/null; then # Check if lspci is available
        if ${pkgs.pciutils}/bin/lspci | ${pkgs.gnugrep}/bin/grep -qi 'vga\|3d\|display'; then
          while read -r line; do
            if echo "$line" | ${pkgs.gnugrep}/bin/grep -Eq '\[10de:'; then
              has_nvidia=true
            elif echo "$line" | ${pkgs.gnugrep}/bin/grep -Eq '\[1002:'; then
              has_amd=true
            elif echo "$line" | ${pkgs.gnugrep}/bin/grep -Eq '\[8086:'; then
              has_intel=true
            elif echo "$line" | ${pkgs.gnugrep}/bin/grep -Eq '\[(1af4|15ad|80ee|1b36|1414|1234|1013):'; then
              has_vm=true
            elif echo "$line" | ${pkgs.gnugrep}/bin/grep -qi 'nvidia'; then
              has_nvidia=true
            elif echo "$line" | ${pkgs.gnugrep}/bin/grep -qi 'amd\|ati\|advanced micro devices'; then
              has_amd=true
            elif echo "$line" | ${pkgs.gnugrep}/bin/grep -qi 'intel'; then
              has_intel=true
            elif echo "$line" | ${pkgs.gnugrep}/bin/grep -qi 'virtio\|vmware\|virtualbox\|qxl\|hyper-v\|microsoft corporation\|parallels\|qemu\|bochs\|cirrus\|svga\|virtual'; then
              has_vm=true
            fi
          done < <(${pkgs.pciutils}/bin/lspci -nn | ${pkgs.gnugrep}/bin/grep -i 'vga\|3d\|display')

          if $has_vm; then
            detected_profile="vm"
          elif $has_nvidia && $has_intel; then
            detected_profile="nvidia-laptop"
          elif $has_nvidia && $has_amd; then
            detected_profile="amd-hybrid"
          elif $has_nvidia; then
            detected_profile="nvidia"
          elif $has_amd; then
            detected_profile="amd"
          elif $has_intel; then
            detected_profile="intel"
          fi
        fi
      else
        echo "Warning: lspci command not found. Cannot auto-detect GPU profile." >&2
      fi
      echo "$detected_profile" # Return the detected profile
    }

    # --- Helper function to parse additional arguments ---
    parse_nh_args() {
      local args_string=""
      local options_selected=()
      shift # Remove the main command (rebuild, rebuild-boot, update)

      while [[ $# -gt 0 ]]; do
        case $1 in
          --dry|-n)
            args_string="$args_string --dry"
            options_selected+=("dry run mode (showing what would be done)")
            shift
            ;;
          --ask|-a)
            args_string="$args_string --ask"
            options_selected+=("confirmation prompts enabled")
            shift
            ;;
          --cores)
            if [[ -n $2 && $2 =~ ^[0-9]+$ ]]; then
              args_string="$args_string -- --cores $2"
              options_selected+=("limited to $2 CPU cores")
              shift 2
            else
              echo "Error: --cores requires a numeric argument" >&2
              exit 1
            fi
            ;;
          --verbose|-v)
            args_string="$args_string --verbose"
            options_selected+=("verbose output enabled")
            shift
            ;;
          --no-nom)
            args_string="$args_string --no-nom"
            options_selected+=("nix-output-monitor disabled")
            shift
            ;;
          --)
            shift
            args_string="$args_string -- $*"
            options_selected+=("additional arguments: $*")
            break
            ;;
          -*)
            echo "Warning: Unknown flag '$1' - passing through to nh" >&2
            args_string="$args_string $1"
            options_selected+=("unknown flag '$1' passed through")
            shift
            ;;
          *)
            echo "Error: Unexpected argument '$1'" >&2
            exit 1
            ;;
        esac
      done

      # Print friendly confirmation of selected options to stderr so it doesn't interfere with return value
      if [[ ''${#options_selected[@]} -gt 0 ]]; then
        echo "Options selected:" >&2
        for option in "''${options_selected[@]}"; do
          echo "  ✓ $option" >&2
        done
        echo >&2
      fi

      # Return only the args string
      echo "$args_string"
    }

    # Resolve the nixosConfigurations target name for nh
    get_nh_target() {
      local current_hostname
      current_hostname="$(${pkgs.nettools}/bin/hostname)"
      if [ -d "$FLAKE_DIR/hosts/$current_hostname" ]; then
        echo "$current_hostname"
      elif [ -d "$FLAKE_DIR/hosts/default" ]; then
        echo "default"
      else
        echo ""
      fi
    }

    # --- flake.nix host list helpers ---
    hosts_block() {
      ${pkgs.gnused}/bin/sed -n '/^\s*hosts\s*=\s*\[/,/\];/p' "$FLAKE_NIX_PATH"
    }

    list_hosts_from_flake() {
      hosts_block | ${pkgs.gnugrep}/bin/grep -o '"[^"]\+"' | ${pkgs.coreutils}/bin/tr -d '"'
    }

    ensure_host_in_flake_hosts() {
      local h="$1"
      if ! list_hosts_from_flake | ${pkgs.gnugrep}/bin/grep -qx "$h"; then
        echo "Adding '$h' to flake hosts list..."
        ${pkgs.gnused}/bin/sed -i '/^\s*hosts\s*=\s*\[/a\      \"'"$h"'\"' "$FLAKE_NIX_PATH"
      fi
    }

    remove_host_from_flake_hosts() {
      local h="$1"
      ${pkgs.gnused}/bin/sed -i '/^\s*hosts\s*=\s*\[/,/\];/ { /^\s*"'"$h"'"\s*$/d }' "$FLAKE_NIX_PATH"
    }

    # --- Main Logic ---
    if [ "$#" -eq 0 ]; then
      echo "Error: No command provided." >&2
      print_help
      exit 1
    fi

    case "$1" in
      cleanup)
        echo "Warning! This will remove old generations of your system."
        read -p "How many generations to keep (default: all)? " keep_count

        if [ -z "$keep_count" ]; then
          read -p "This will remove all but the current generation. Continue (y/N)? " -n 1 -r
          echo
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            ${pkgs.nh}/bin/nh clean all -v
          else
            echo "Cleanup cancelled."
          fi
        else
          read -p "This will keep the last $keep_count generations. Continue (y/N)? " -n 1 -r
          echo
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            ${pkgs.nh}/bin/nh clean all -k "$keep_count" -v
          else
            echo "Cleanup cancelled."
          fi
        fi

        ;;
      diag)
        echo "Generating system diagnostic report..."
        ${pkgs.inxi}/bin/inxi --full > "$HOME/diag.txt"
        echo "Diagnostic report saved to $HOME/diag.txt"
        ;;
      help)
        print_help
        ;;
      list-gens)
        echo "--- User Generations ---"
        ${pkgs.nix}/bin/nix-env --list-generations || echo "Could not list user generations."
        echo ""
        echo "--- System Generations ---"
        ${pkgs.nix}/bin/nix profile history --profile /nix/var/nix/profiles/system || echo "Could not list system generations."
        ;;
      list-hosts)
        if [ ! -f "$FLAKE_NIX_PATH" ]; then
          echo "Error: flake.nix not found at $FLAKE_NIX_PATH" >&2
          exit 1
        fi
        echo "Hosts defined in flake.nix:"
        list_hosts_from_flake | ${pkgs.coreutils}/bin/sort | ${pkgs.coreutils}/bin/uniq
        ;;
      rebuild)
        verify_hostname
        handle_backups

        # Parse additional arguments
        extra_args=$(parse_nh_args "$@")

        target="$(get_nh_target)"
        if [ -z "$target" ]; then
          echo "Error: Could not resolve flake config (no hosts/$(${pkgs.nettools}/bin/hostname) or hosts/default)." >&2
          exit 1
        fi

        echo "Starting NixOS rebuild for config: $target"
        if eval "${pkgs.nh}/bin/nh os switch --diff always --hostname \"$target\" $extra_args"; then
          echo "Rebuild finished successfully"
        else
          echo "Rebuild Failed" >&2
          exit 1
        fi
        ;;
      rebuild-boot)
        verify_hostname
        handle_backups

        # Parse additional arguments
        extra_args=$(parse_nh_args "$@")

        target="$(get_nh_target)"
        if [ -z "$target" ]; then
          echo "Error: Could not resolve flake config (no hosts/$(${pkgs.nettools}/bin/hostname) or hosts/default)." >&2
          exit 1
        fi

        echo "Starting NixOS rebuild (boot) for config: $target"
        echo "Note: Configuration will be activated on next reboot"
        if eval "${pkgs.nh}/bin/nh os boot --diff always --hostname \"$target\" $extra_args"; then
          echo "Rebuild-boot finished successfully"
          echo "New configuration set as boot default - restart to activate"
        else
          echo "Rebuild-boot Failed" >&2
          exit 1
        fi
        ;;
      trim)
        echo "Running 'sudo fstrim -v /' may take a few minutes and impact system performance."
        read -p "Enter (y/Y) to run now or enter to exit (y/N): " -n 1 -r
        echo # move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          echo "Running fstrim..."
          sudo ${pkgs.util-linux}/bin/fstrim -v /
          echo "fstrim complete."
        else
          echo "Trim operation cancelled."
        fi
        ;;
      update)
        verify_hostname
        handle_backups

        # Parse additional arguments
        extra_args=$(parse_nh_args "$@")

        target="$(get_nh_target)"
        if [ -z "$target" ]; then
          echo "Error: Could not resolve flake config (no hosts/$(${pkgs.nettools}/bin/hostname) or hosts/default)." >&2
          exit 1
        fi

        echo "Updating flake and rebuilding system for config: $target"
        if eval "${pkgs.nh}/bin/nh os switch --diff always --hostname \"$target\" --update $extra_args"; then
          echo "Update and rebuild finished successfully"
        else
          echo "Update and rebuild Failed" >&2
          exit 1
        fi
        ;;
      update-host)
        target_hostname=""
        target_profile=""

        if [ "$#" -eq 3 ]; then # zcli update-host <hostname> <profile>
          target_hostname="$2"
          target_profile="$3"
        elif [ "$#" -eq 1 ]; then # zcli update-host (auto-detect)
          echo "Attempting to auto-detect hostname and GPU profile..."
          target_hostname=$(${pkgs.nettools}/bin/hostname)
          target_profile=$(detect_gpu_profile)

          if [ -z "$target_profile" ]; then
            echo "Error: Could not auto-detect a specific GPU profile. Please provide it manually." >&2
            echo "Usage: zcli update-host [hostname] [profile]" >&2
            exit 1
          fi
          echo "Auto-detected Hostname: $target_hostname"
          echo "Auto-detected Profile: $target_profile"
        else
          echo "Error: Invalid number of arguments for 'update-host'." >&2
          echo "Usage: zcli update-host [hostname] [profile]" >&2
          exit 1
        fi

        echo "Preparing host '$target_hostname' (profile: $target_profile)..."

        # Ensure host directory exists (copy from hosts/default if missing)
        if [ ! -d "$FLAKE_DIR/hosts/$target_hostname" ]; then
          echo "Creating $FLAKE_DIR/hosts/$target_hostname from hosts/default..."
          ${pkgs.coreutils}/bin/cp -r "$FLAKE_DIR/hosts/default" "$FLAKE_DIR/hosts/$target_hostname"
        fi

        # Update variables.nix (hostName and gpuProfile)
        host_vars_file="$FLAKE_DIR/hosts/$target_hostname/variables.nix"
        if [ -f "$host_vars_file" ]; then
          ${pkgs.gnused}/bin/sed -i "s/\(hostName[[:space:]]*=\)[[:space:]]*\"[^\"]*\"/\1 \"$target_hostname\"/" "$host_vars_file"
          ${pkgs.gnused}/bin/sed -i "s/\(gpuProfile[[:space:]]*=\)[[:space:]]*\"[^\"]*\"/\1 \"$target_profile\"/" "$host_vars_file"
        else
          echo "Error: missing $host_vars_file" >&2
          exit 1
        fi

        # Ensure the host appears in the flake 'hosts' array
        ensure_host_in_flake_hosts "$target_hostname"

        echo "Host '$target_hostname' is ready. You can now run: zcli rebuild"
        ;;
      add-host)
        hostname=""
        profile_arg=""

        if [ "$#" -ge 2 ]; then
          hostname="$2"
        fi
        if [ "$#" -eq 3 ]; then
          profile_arg="$3"
        fi

        if [ -z "$hostname" ]; then
          read -p "Enter the new hostname: " hostname
        fi

        if [ -d "$HOME/$PROJECT/hosts/$hostname" ]; then
          echo "Error: Host '$hostname' already exists." >&2
          exit 1
        fi

        echo "Copying default host configuration..."
        ${pkgs.coreutils}/bin/cp -r "$HOME/$PROJECT/hosts/default" "$HOME/$PROJECT/hosts/$hostname"

        detected_profile=""
        if [[ -n "$profile_arg" && "$profile_arg" =~ ^(intel|amd|nvidia|nvidia-laptop|amd-hybrid|vm)$ ]]; then
          detected_profile="$profile_arg"
        else
          echo "Detecting GPU profile..."
          detected_profile=$(detect_gpu_profile)
          echo "Detected GPU profile: $detected_profile"
          read -p "Is this correct? (y/n) " -n 1 -r
          echo
          if [[ $REPLY =~ ^[Nn]$ ]]; then
            read -p "Enter the correct profile (intel, amd, nvidia, nvidia-laptop, amd-hybrid, vm): " new_profile
            while [[ ! "$new_profile" =~ ^(intel|amd|nvidia|nvidia-laptop|amd-hybrid|vm)$ ]]; do
              echo "Invalid profile. Please enter one of the following: intel, amd, nvidia, nvidia-laptop, amd-hybrid, vm"
              read -p "Enter the correct profile: " new_profile
            done
            detected_profile=$new_profile
          fi
        fi

        echo "Setting profile to '$detected_profile'..."
        ${pkgs.gnused}/bin/sed -i "s/profile = .*/profile = \"$detected_profile\";/" "$HOME/$PROJECT/hosts/$hostname/default.nix"

        read -p "Generate new hardware.nix? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          echo "Generating hardware.nix..."
          sudo nixos-generate-config --show-hardware-config > "$HOME/$PROJECT/hosts/$hostname/hardware.nix"
          echo "hardware.nix generated."
        fi

        # Ensure the host appears in flake.nix hosts list
        ensure_host_in_flake_hosts "$hostname"

        echo "Adding new host to git..."
        ${pkgs.git}/bin/git -C "$HOME/$PROJECT" add .
        echo "hostname: $hostname added"
        ;;
      del-host)
        hostname=""
        if [ "$#" -eq 2 ]; then
          hostname="$2"
        else
          read -p "Enter the hostname to delete: " hostname
        fi

        if [ ! -d "$HOME/$PROJECT/hosts/$hostname" ]; then
          echo "Error: Host '$hostname' does not exist." >&2
          exit 1
        fi

        read -p "Are you sure you want to delete the host '$hostname'? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          echo "Deleting host '$hostname'..."
          ${pkgs.coreutils}/bin/rm -rf "$HOME/$PROJECT/hosts/$hostname"
          # Remove from flake.nix hosts list as well
          remove_host_from_flake_hosts "$hostname"
          ${pkgs.git}/bin/git -C "$HOME/$PROJECT" add .
          echo "hostname: $hostname removed"
        else
          echo "Deletion cancelled."
        fi
        ;;
      doom)
        if [ "$#" -lt 2 ]; then
          echo "Error: doom command requires a subcommand." >&2
          echo "Usage: zcli doom [install|status|remove|update]" >&2
          exit 1
        fi

        # Ensure we're acting on a valid host and we can locate variables.nix
        verify_hostname
        current_hostname="$(hostname)"
        host_vars_file="$HOME/$PROJECT/hosts/$current_hostname/variables.nix"

        if [ ! -f "$host_vars_file" ]; then
          echo "Error: Host variables file not found: $host_vars_file" >&2
          echo "Please ensure your host folder exists and contains variables.nix." >&2
          exit 1
        fi

        is_doom_enabled() {
          # Return 0 if doomEmacsEnable = true; appears (ignoring leading spaces)
          ${pkgs.gnugrep}/bin/grep -Eq '^[[:space:]]*doomEmacsEnable[[:space:]]*=[[:space:]]*true[[:space:]]*;' "$host_vars_file"
        }

        ensure_doom_enabled() {
          # If the variable is present but false, flip it; if missing, append it
          if ${pkgs.gnugrep}/bin/grep -Eq '^[[:space:]]*doomEmacsEnable[[:space:]]*=' "$host_vars_file"; then
            ${pkgs.gnused}/bin/sed -i 's/^[[:space:]]*doomEmacsEnable[[:space:]]*=.*/  doomEmacsEnable = true;/' "$host_vars_file"
          else
            echo "" >> "$host_vars_file"
            echo "  # Enabled by zcli doom on $(date)" >> "$host_vars_file"
            echo "  doomEmacsEnable = true;" >> "$host_vars_file"
          fi
        }

        find_doom_emacsdir() {
          local candidate
          local doom_path
          local doom_real
          local doom_root

          for candidate in "$HOME/.emacs.d" "$HOME/.config/emacs"; do
            if [ -x "$candidate/bin/doom" ] && { [ -f "$candidate/core/doom.el" ] || [ -f "$candidate/lisp/doom.el" ]; }; then
              echo "$candidate"
              return 0
            fi
          done

          if doom_path="$(command -v doom 2>/dev/null)"; then
            doom_real="$(${pkgs.coreutils}/bin/readlink -f "$doom_path" 2>/dev/null || true)"
            if [ -z "$doom_real" ]; then
              doom_real="$doom_path"
            fi
            doom_root="$(${pkgs.coreutils}/bin/dirname "$(${pkgs.coreutils}/bin/dirname "$doom_real")")"
            if [ -x "$doom_root/bin/doom" ] && { [ -f "$doom_root/core/doom.el" ] || [ -f "$doom_root/lisp/doom.el" ]; }; then
              echo "$doom_root"
              return 0
            fi
          fi

          return 1
        }

        doom_subcommand="$2"
        case "$doom_subcommand" in
          install)
            if ! is_doom_enabled; then
              echo "✗ Doom Emacs is disabled for host '$current_hostname' (doomEmacsEnable = false)." >&2
              echo "To enable, set doomEmacsEnable = true; in:" >&2
              echo "  $host_vars_file" >&2
              echo "and rebuild your system before installing Doom." >&2
              echo
              read -p "Enable Doom for this host now and rebuild? (y/N) " -n 1 -r
              echo
              if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Enabling Doom Emacs in $host_vars_file..."
                ensure_doom_enabled
                echo "Rebuilding system so user modules are applied..."
                target="$(get_nh_target)"
                if [ -z "$target" ]; then
                  echo "Error: Could not resolve flake config (no hosts/$(${pkgs.nettools}/bin/hostname) or hosts/default)." >&2
                  exit 1
                fi
                if ${pkgs.nh}/bin/nh os switch --diff always --hostname "$target"; then
                  echo "Rebuild complete. Proceeding with Doom installation."
                else
                  echo "Error: Rebuild failed. Please fix the build and re-run 'zcli doom install'." >&2
                  exit 1
                fi
              else
                echo "Aborting. Please enable doomEmacsEnable and rebuild before installing." >&2
                exit 1
              fi
            fi
            echo "Installing Doom Emacs..."
            ${get-doom-script}/bin/get-doom
            ;;
          status)
            if doom_emacsdir="$(find_doom_emacsdir)"; then
              doom_bin="$doom_emacsdir/bin/doom"
              echo "✔ Doom Emacs appears installed at $doom_emacsdir"
              if [ -f "$HOME/.doom.d/init.el" ]; then
                echo "  • User config found: $HOME/.doom.d/init.el"
              else
                echo "  • Warning: User config (~/.doom.d) not found"
              fi
              echo "Version information:"
              "$doom_bin" version 2>/dev/null || echo "Could not get version information"
            else
              if [ -d "$HOME/.emacs.d" ]; then
                if [ -z "$(ls -A "$HOME/.emacs.d" 2>/dev/null)" ]; then
                  echo "✗ Found empty ~/.emacs.d (not a valid Doom installation)"
                else
                  echo "✗ ~/.emacs.d exists but Doom was not detected"
                fi
              elif [ -d "$HOME/.config/emacs" ]; then
                if [ -z "$(ls -A "$HOME/.config/emacs" 2>/dev/null)" ]; then
                  echo "✗ Found empty ~/.config/emacs (not a valid Doom installation)"
                else
                  echo "✗ ~/.config/emacs exists but Doom was not detected"
                fi
              else
                echo "✗ Doom Emacs is not installed"
              fi
              echo "Run 'zcli doom install' to install it"
            fi
            ;;
          remove)
            if ! doom_emacsdir="$(find_doom_emacsdir)"; then
              echo "Doom Emacs is not installed"
              exit 0
            fi

            echo "Warning: This will completely remove Doom Emacs at $doom_emacsdir and all your configuration!"
            read -p "Are you sure you want to continue? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
              echo "Removing Doom Emacs..."
              ${pkgs.coreutils}/bin/rm -rf "$doom_emacsdir"
              echo "✔ Doom Emacs has been removed"
            else
              echo "Removal cancelled"
            fi
            ;;
          update)
            if ! doom_emacsdir="$(find_doom_emacsdir)"; then
              echo "Error: Doom Emacs is not installed correctly. Run 'zcli doom install' first." >&2
              exit 1
            fi

            doom_bin="$doom_emacsdir/bin/doom"
            echo "Updating Doom Emacs at $doom_emacsdir..."
            "$doom_bin" upgrade
            "$doom_bin" sync
            echo "✔ Doom Emacs update complete"
            ;;
          *)
            echo "Error: Invalid doom subcommand '$doom_subcommand'" >&2
            echo "Usage: zcli doom [install|status|remove|update]" >&2
            exit 1
            ;;
        esac
        ;;
      *)
        echo "Error: Invalid command '$1'" >&2
        print_help
        exit 1
        ;;
    esac
  ''
