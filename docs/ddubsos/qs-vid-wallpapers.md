# qs-vid-wallpapers and qs-vid-wallpapers-apply

This document explains the video-oriented QS picker and its apply wrapper.

- Picker: qs-vid-wallpapers (installed from modules/home/scripts/qs-vid-wallpapers.nix)
- Apply wrapper: qs-vid-wallpapers-apply (installed from modules/home/scripts/qs-vid-wallpapers-apply.nix)

## What they do

- qs-vid-wallpapers is a Qt/QML thumbnail picker specialized for animated/video wallpapers. It scans your wallpaper directory, builds thumbnails using ffmpegthumbnailer (with ffmpeg fallback), and renders a searchable grid UI. It also provides a status header with a button to stop video-based mpvpaper sessions.
- qs-vid-wallpapers-apply runs the picker and applies the selected video to the desktop with mpvpaper.

## Key concepts and flow

1) Collect files
- Scans WALL_DIR (default: $HOME/Pictures/Wallpapers) recursively, following symlinks (`find -L`).
- Includes common video formats supported by mpv/mpvpaper: mp4, m4v, mp4v, mov, webm, avi, mkv, mpeg/mpg, wmv, avchd, flv, ogv, m2ts/ts, 3gp. Animated AVIF is also supported for thumbnailing and can be used with mpvpaper (optionally transcoded elsewhere).

2) Thumbnail cache
- Thumbnails are cached in VID_WALL_CACHE_DIR (default: $HOME/.cache/vidthumbs).
- Primary: ffmpegthumbnailer (fast). Fallback: ffmpeg still extraction with scaling and padding to a square.

3) JSON manifest
- Builds an inline JSON array of { path, name, thumb } and inlines it into the QML (same pattern as the image picker).

4) Status/controls header
- The header shows MPVPaper status: ACTIVE/INACTIVE — but only for video-based mpvpaper instances.
- Status badge: MPVPaper: ACTIVE is emphasized with a brighter, 3D pill-style badge to stand out; INACTIVE is dimmed.
- Video-only detection is robust: it inspects every mpvpaper process argument (ignoring `-o` and its value) and considers it video-active if any argument looks like a video file path.
- The "Stop Video Wallpaper" button kills only those mpvpaper processes that are playing video files and leaves image-only mpvpaper sessions (static wallpapers) running.
- After stopping, the UI waits briefly for processes to exit and relaunches so the header updates to INACTIVE without requiring the user to rerun the command.

5) QML UI
- A temporary QML file is generated and executed with Qt 6’s qml binary.
- The UI mirrors qs-wallpapers: search bar, grid of thumbnails with rounded corners, click to select.
- Audio toggle: default "Disable sound" is ON; clicking toggles audio. On selection, the picker prints two lines to console: SELECT:<path> and AUDIO:<ON|OFF>.
- The shell wrapper captures both and applies audio settings accordingly.

6) Output
- If a selection was made, qs-vid-wallpapers prints the path to stdout. If cancelled, nothing is printed.

7) Apply wrapper
- qs-vid-wallpapers-apply orchestrates the picker and then applies the selection using mpvpaper, stopping awww-daemon/hyprpaper/mpvpaper first to avoid conflicts, then launching mpvpaper on all outputs with appropriate video options (loop, no OSC/OSD). Audio is disabled unless AUDIO:ON is received from the picker.
- Currently, the qs-vid-wallpapers-apply wrapper targets the mpvpaper backend (the most appropriate for video). If desired, it can be extended to support additional backends or to delegate to the existing `awp` tool for monitor-specific or fill/stretch behaviors.

## Flags and environment

Picker (qs-vid-wallpapers):
- Flags: -d DIR (video dir), -t DIR (thumb cache), -s N (thumb size), -h (help)
- Env:
  - WALL_DIR: search directory (default: $HOME/Pictures/Wallpapers)
  - VID_WALL_CACHE_DIR: thumbnail cache (default: $HOME/.cache/vidthumbs)
  - VID_WALL_THUMB_SIZE: pixel size for thumbnails (default: 200)
  - QS_DEBUG: print diagnostics and run QML directly
  - QS_PERF: print timing info
  - QS_AUTO_QUIT: not typically used here; available for perf runs

Apply (qs-vid-wallpapers-apply):
- Flags:
  - --print-only: run picker and exit (for benchmarking/inspection)
  - --shell-only: skip QML (perf testing)
- Env:
  - WALLPAPER_BACKEND: default is mpvpaper (others not yet added in this wrapper)
  - QS_DEBUG / QS_PERF / QS_AUTO_QUIT propagated as needed

## Differences from the image picker

- Detection and control of running wallpaper processes:
  - qs-vid-wallpapers shows status and provides a stop button specifically for video-based mpvpaper sessions. This avoids disrupting static (image-only) sessions if a user prefers them.
- Thumbnail generation: video thumb generation uses ffmpegthumbnailer/ffmpeg instead of ImageMagick.
- Apply wrapper focus: qs-vid-wallpapers-apply is focused on mpvpaper since it’s the video wallpaper engine.

## Why two families (qs-wallpapers* vs qs-vid-wallpapers*)

- Static images and videos have different needs:
  - Different thumbnailing tools and performance characteristics.
  - Different runtime behavior (videos loop, consume CPU/GPU; images do not).
  - Different UX affordances (video-only status and kill button vs. plain image selection).
- Keeping them separate keeps each codepath focused, simpler to reason about, and easier to tune independently without regressions.

## Integration notes

- Hyprland window rules include entries to float and center the QML window by title:
  - "Wallpapers" (images) and "Video Wallpapers" (videos) are targeted separately.
  - Styling via windowrulev2: noborder, noshadow, noblur, rounding 12 for both titles.
- Window flags request frameless and no-drop-shadow (Qt.NoDropShadowWindowHint), and the UI uses more opaque backgrounds for readability on blurred setups.
- Recommended keybindings:
  - Image: `$mod+Shift+W` -> `qs-wallpapers-apply`
  - Video: Choose a convenient chord, e.g., `$mod+Shift+V` -> `qs-vid-wallpapers-apply`

## Troubleshooting

- Status shows INACTIVE while a video is running:
  - Ensure the running mpvpaper process includes the video file path as a distinct argument (the script searches all args, ignoring `-o` and its value). If the file is launched via a wrapper that hides the file path or uses a non-standard invocation, detection may not find it.
- Stop button does nothing:
  - Check permissions and that `pgrep`/`kill` are available; ensure the process owner matches the current user.
- No videos listed:
  - Verify WALL_DIR and supported extensions; symlinks are supported due to `find -L`.

## Future extensions

- Optional delegation to `awp` for advanced monitor selection and fill/stretch behaviors.
- Additional backends in the apply wrapper if desired.
- Persisted settings (last selection, monitor targeting) via a small state file if needed.

