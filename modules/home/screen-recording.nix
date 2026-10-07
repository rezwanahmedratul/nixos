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
      pkgs.gawk
    ]}

    [[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs

    OUTPUT_DIR="''${XDG_VIDEOS_DIR:-''$HOME/Videos}"

    if [[ ! -d "$OUTPUT_DIR" ]]; then
      notify-send "Screen recording directory does not exist: $OUTPUT_DIR"
      exit 1
    fi

    MICROPHONE_AUDIO="false"
    WEBCAM="false"
    WEBCAM_DEVICE=""
    RESOLUTION=""
    STOP_RECORDING="false"

    RECORDING_FILE="/tmp/screenrecord-file"

    for arg in "$@"; do
      case "$arg" in
        --with-microphone-audio) MICROPHONE_AUDIO="true" ;;
        --with-webcam) WEBCAM="true" ;;
        --webcam-device=*) WEBCAM_DEVICE="''${arg#*=}" ;;
        --resolution=*) RESOLUTION="''${arg#*=}" ;;
        --stop-recording) STOP_RECORDING="true" ;;
      esac
    done

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
      target=$(select_capture_target) || exit 1

      if [[ "$target" == monitor:* ]]; then
        args=(-w "''${target#monitor:}" -s "''${RESOLUTION:-$(default_resolution)}")
      else
        args=(-w "''${target#region:}")
      fi

      [[ "$WEBCAM" == "true" ]] && start_webcam_overlay

      filename="$OUTPUT_DIR/recording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"

      # ALWAYS record system audio
      audio_devices="default_output"

      # optional mic
      [[ "$MICROPHONE_AUDIO" == "true" ]] && audio_devices+="|default_input"

      audio_args=(-a "$audio_devices" -ac aac)

      # start recording
      gpu-screen-recorder "''${args[@]}" -f 60 -o "$filename" "''${audio_args[@]}" &

      echo "$filename" > "$RECORDING_FILE"

      notify-send "Screen Recording" "Started recording: $filename"

      pkill -RTMIN+8 waybar 2>/dev/null || true
    }

    stop_recording() {
      pkill -SIGINT -f gpu-screen-recorder || true
      sleep 1

      cleanup_webcam

      filename=$(cat "$RECORDING_FILE" 2>/dev/null || true)

      if [[ -f "$filename" ]]; then
        notify-send "Screen Recording" "Saved: $filename"
      fi

      rm -f "$RECORDING_FILE"
      pkill -RTMIN+8 waybar 2>/dev/null || true
    }

    if pgrep -f gpu-screen-recorder >/dev/null; then
      stop_recording
    elif [[ "$STOP_RECORDING" == "true" ]]; then
      exit 1
    else
      start_recording
    fi
  '';

in
{
  home.packages = [
    screenrecord
  ];
}