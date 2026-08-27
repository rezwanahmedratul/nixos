{inputs, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
      # Temporary hotfix: dwarfs 0.14.0 / bundled folly fails on GCC with missing
      # std::memcpy/std::memset (cstring) and treats warnings as errors.
      # Needed by gearlever. Pin fmt_11 and patch Exception.h to include <cstring>.
      dwarfs =
        (prev.dwarfs.override {
          fmt = prev.fmt_11;
        }).overrideAttrs (old: {
          postPatch =
            (old.postPatch or "")
            + ''
              if [ -f folly/folly/lang/Exception.h ]; then
                sed -i '1i#include <cstring>' folly/folly/lang/Exception.h
              fi
            '';
          cmakeFlags = (old.cmakeFlags or []) ++ ["-DENABLE_WERROR=OFF"];
        });

      # obs-move-transition fails on OBS 32.2.1+ due to deprecated declarations
      # being treated as errors (-Werror).
      obs-studio-plugins = prev.obs-studio-plugins // {
        obs-move-transition = prev.obs-studio-plugins.obs-move-transition.overrideAttrs (old: {
          NIX_CFLAGS_COMPILE =
            (old.NIX_CFLAGS_COMPILE or "")
            + " -Wno-error=deprecated-declarations";
        });
      };
    })
  ];
}
