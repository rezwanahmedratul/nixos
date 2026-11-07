{ pkgs, ... }:

let
  screenrecord = pkgs.writeShellScriptBin "screenrecord" ''
    #!/usr/bin/env bash
    set -euo pipefail

    export PATH=${pkgs.lib.makeBinPath [
      pkgs.gpu-screen-recorder
      pkgs.ffmpeg
      pkgs.jq
      pkgs.slurp
      pkgs.hyprpicker
      pkgs.libnotify
      pkgs.v4l-utils
      pkgs.mpv
      pkgs.coreutils
      pkgs.procps
      pkgs.gnugrep
      pkgs.gnused
      pkgs.gawk
      pkgs.rofi
    ]}

    [[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs

    OUTPUT_DIR="''${XDG_VIDEOS_DIR:-''$HOME/Videos}"

    if [[ ! -d "$OUTPUT_DIR" ]]; then
      mkdir -p "$OUTPUT_DIR" || {
        notify-send "Screen Recording" "Screen recording directory does not exist: $OUTPUT_DIR"
        exit 1
      }
    fi

    RECORD_AUDIO="system"
    MICROPHONE_AUDIO="false"
    SELECTED_MIC_DEVICE=""
    SELECTED_MIC_LABEL=""
    WEBCAM="false"
    WEBCAM_DEVICE=""
    RESOLUTION=""
    STOP_RECORDING="false"
    USE_MENU=""
    CLI_MODE_SET="false"

    RECORDING_FILE="/tmp/screenrecord-file"

    for arg in "$@"; do
      case "$arg" in
        --with-microphone-audio)
          MICROPHONE_AUDIO="true"
          RECORD_AUDIO="mic_and_system"
          CLI_MODE_SET="true"
          ;;
        --without-microphone-audio)
          MICROPHONE_AUDIO="false"
          RECORD_AUDIO="system"
          CLI_MODE_SET="true"
          ;;
        --no-audio)
          MICROPHONE_AUDIO="false"
          RECORD_AUDIO="none"
          CLI_MODE_SET="true"
          ;;
        --mic-device=*)
          SELECTED_MIC_DEVICE="''${arg#*=}"
          ;;
        --with-webcam)
          WEBCAM="true"
          CLI_MODE_SET="true"
          ;;
        --webcam-device=*)
          WEBCAM_DEVICE="''${arg#*=}"
          ;;
        --resolution=*)
          RESOLUTION="''${arg#*=}"
          ;;
        --stop-recording)
          STOP_RECORDING="true"
          ;;
        --menu)
          USE_MENU="true"
          ;;
        --no-menu)
          USE_MENU="false"
          ;;
      esac
    done

    if [[ -z "$USE_MENU" ]]; then
      if [[ "$CLI_MODE_SET" == "true" || "$STOP_RECORDING" == "true" ]]; then
        USE_MENU="false"
      else
        USE_MENU="true"
      fi
    fi

    rofi_menu() {
      local title="$1"
      local rofi_cmd=(rofi -dmenu -i -p "$title" -mesg "$title")
      if [[ -f "$HOME/.config/rofi/config-long.rasi" ]]; then
        rofi_cmd+=(-config "$HOME/.config/rofi/config-long.rasi")
      fi
      "''${rofi_cmd[@]}"
    }

    select_microphone() {
      local mic_lines
      mic_lines=$(gpu-screen-recorder --list-audio-devices 2>/dev/null | grep -v "^default_output|" | grep -v "\.monitor" | grep -v "^default_input|" || true)
      local count
      count=$(echo "$mic_lines" | grep -c . || true)

      # If 1 or fewer specific microphones are present, default to system default without prompting
      if (( count <= 1 )); then
        SELECTED_MIC_DEVICE="default_input"
        SELECTED_MIC_LABEL="Default Microphone"
        return 0
      fi

      local options="⭐ System Default Microphone\n"
      declare -A mic_map
      mic_map["⭐ System Default Microphone"]="default_input"

      while IFS='|' read -r dev desc; do
        [[ -z "$dev" ]] && continue
        local clean_desc="''${desc:-$dev}"
        local label="🎙️ $clean_desc"
        if [[ -n "''${mic_map[$label]+_}" ]]; then
          label="🎙️ $clean_desc ($dev)"
        fi
        options+="''${label}\n"
        mic_map["$label"]="$dev"
      done <<< "$mic_lines"

      local chosen
      chosen=$(echo -e "$options" | sed '/^$/d' | rofi_menu "Select Microphone")
      [[ -z "$chosen" ]] && return 1

      SELECTED_MIC_DEVICE="''${mic_map[$chosen]:-default_input}"
      SELECTED_MIC_LABEL="$chosen"
      return 0
    }

    show_main_menu() {
      if pidof rofi >/dev/null 2>&1; then
        pkill rofi || true
      fi

      local options="🎙️ Record with Microphone (Voice + System Audio)\n🔊 Record Screen (System Audio Only)\n📷 Record Screen + Mic + Webcam\n🔇 Record Screen (No Audio)\n❌ Cancel"
      local chosen
      chosen=$(echo -e "$options" | rofi_menu "Screen Recording")

      case "$chosen" in
        *"Record with Microphone"*)
          RECORD_AUDIO="mic_and_system"
          MICROPHONE_AUDIO="true"
          WEBCAM="false"
          select_microphone || exit 0
          ;;
        *"System Audio Only"*)
          RECORD_AUDIO="system"
          MICROPHONE_AUDIO="false"
          WEBCAM="false"
          ;;
        *"Webcam"*)
          RECORD_AUDIO="mic_and_system"
          MICROPHONE_AUDIO="true"
          WEBCAM="true"
          select_microphone || exit 0
          ;;
        *"No Audio"*)
          RECORD_AUDIO="none"
          MICROPHONE_AUDIO="false"
          WEBCAM="false"
          ;;
        *)
          exit 0
          ;;
      esac
    }

    cleanup_webcam() {
      pkill -f "WebcamOverlay" 2>/dev/null || true
    }

    start_webcam_overlay() {
      cleanup_webcam

      if [[ -z "$WEBCAM_DEVICE" ]]; then
        WEBCAM_DEVICE=$(v4l2-ctl --list-devices 2>/dev/null | grep -m1 "/dev/video" | tr -d '\t')
      fi

      [[ -z "$WEBCAM_DEVICE" ]] && return

      scale=$(/run/current-system/sw/bin/hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .scale')
      target_width=$(awk "BEGIN {printf \"%.0f\", 360 * $scale}")

      ffplay -f v4l2 -framerate 30 "$WEBCAM_DEVICE" \
        -vf "crop=iw/2:ih,scale=''${target_width}:-1" \
        -window_title "WebcamOverlay" \
        -noborder -loglevel quiet &
    }

    default_resolution() {
      read -r width height < <(/run/current-system/sw/bin/hyprctl monitors -j | jq -r '.[] | select(.focused==true) | "\(.width) \(.height)"')
      if ((width > 3840 || height > 2160)); then
        echo "3840x2160"
      else
        echo "0x0"
      fi
    }

    get_rectangles() {
      ws=$(/run/current-system/sw/bin/hyprctl monitors -j | jq -r '.[] | select(.focused==true).activeWorkspace.id')

      /run/current-system/sw/bin/hyprctl monitors -j | jq -r --arg ws "$ws" '
        .[] | select(.activeWorkspace.id == ($ws|tonumber)) |
        "\(.x),\(.y) \(.width/.scale|floor)x\(.height/.scale|floor)"'

      /run/current-system/sw/bin/hyprctl clients -j | jq -r --arg ws "$ws" '
        .[] | select(.workspace.id == ($ws|tonumber)) |
        "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
    }

    select_capture_target() {
      rects=$(get_rectangles)

      hyprpicker -r -z >/dev/null 2>&1 &
      picker_pid=$!
      sleep 0.1

      selection=$(echo "$rects" | slurp 2>/dev/null)
      kill $picker_pid 2>/dev/null || true

      [[ -z "$selection" ]] && return 1

      sx=$(echo "$selection" | cut -d',' -f1)
      sy=$(echo "$selection" | cut -d',' -f2 | cut -d' ' -f1)
      sw=$(echo "$selection" | grep -o '[0-9]\+x' | tr -d x)
      sh=$(echo "$selection" | grep -o 'x[0-9]\+' | tr -d x)

      monitor=$(/run/current-system/sw/bin/hyprctl monitors -j | jq -r \
        --argjson x "$sx" --argjson y "$sy" \
        '.[] | select(.x==$x and .y==$y) | .name' | head -1)

      if [[ -n "$monitor" ]]; then
        echo "monitor:$monitor"
      else
        echo "region:''${sw}x''${sh}+''${sx}+''${sy}"
      fi
    }

    start_recording() {
      target=$(select_capture_target) || exit 0

      if [[ "$target" == monitor:* ]]; then
        args=(-w "''${target#monitor:}" -s "''${RESOLUTION:-$(default_resolution)}")
      else
        args=(-w "''${target#region:}")
      fi

      [[ "$WEBCAM" == "true" ]] && start_webcam_overlay

      filename="$OUTPUT_DIR/recording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"

      audio_args=()
      if [[ "$RECORD_AUDIO" == "none" ]]; then
        audio_args=()
      elif [[ "$RECORD_AUDIO" == "mic_and_system" ]]; then
        local mic="''${SELECTED_MIC_DEVICE:-default_input}"
        audio_args=(-a "default_output|$mic" -ac aac)
      else
        # default: system audio only
        audio_args=(-a "default_output" -ac aac)
      fi

      # start recording
      gpu-screen-recorder "''${args[@]}" -f 60 -o "$filename" "''${audio_args[@]}" &

      echo "$filename" > "$RECORDING_FILE"

      local notify_msg="Started recording: $filename"
      if [[ "$RECORD_AUDIO" == "mic_and_system" ]]; then
        if [[ -n "$SELECTED_MIC_LABEL" ]]; then
          notify_msg="Started recording ($SELECTED_MIC_LABEL):\n$filename"
        else
          notify_msg="Started recording with microphone:\n$filename"
        fi
      elif [[ "$RECORD_AUDIO" == "none" ]]; then
        notify_msg="Started recording (no audio):\n$filename"
      fi

      notify-send "Screen Recording" "$notify_msg"

      pkill -RTMIN+8 waybar 2>/dev/null || true
    }

    stop_recording() {
      pkill -SIGINT -f gpu-screen-recorder || true

      for _ in {1..20}; do
        if ! pgrep -f gpu-screen-recorder >/dev/null 2>&1; then
          break
        fi
        sleep 0.1
      done

      cleanup_webcam

      filename=$(cat "$RECORDING_FILE" 2>/dev/null || true)

      if [[ -n "$filename" && -f "$filename" ]]; then
        notify-send "Screen Recording" "Saved: $filename"
      fi

      rm -f "$RECORDING_FILE"
      pkill -RTMIN+8 waybar 2>/dev/null || true
    }

    if pgrep -f gpu-screen-recorder >/dev/null; then
      stop_recording
    elif [[ "$STOP_RECORDING" == "true" ]]; then
      exit 0
    else
      if [[ "$USE_MENU" == "true" ]]; then
        show_main_menu
      fi
      start_recording
    fi
  '';

in
{
  home.packages = [
    screenrecord
  ];
}
