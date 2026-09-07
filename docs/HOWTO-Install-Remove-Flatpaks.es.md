# HOWTO: Instalar y Eliminar Flatpaks en ddubsOS

Esta guía explica cómo se gestionan las aplicaciones Flatpak en ddubsOS y cómo agregarlas o eliminarlas. Se basa en la configuración en modules/core/flatpak.nix.

Resumen

- Los Flatpaks se declaran en modules/core/flatpak.nix bajo services.flatpak.packages.
- Agregar o eliminar una app requiere una reconstrucción del sistema para aplicar cambios.
- Por defecto, ddubsOS actualiza los Flatpaks automáticamente en las reconstrucciones (update.onActivation = true).

Dónde está la configuración

- Archivo: modules/core/flatpak.nix
- Atributos clave:
  - services.flatpak.enable = true;
  - services.flatpak.packages = [ ... ]; # lista de IDs de apps Flatpak
  - services.flatpak.update.onActivation = true; # actualiza Flatpaks al activar la nueva generación

Cómo agregar una app Flatpak

1. Abre modules/core/flatpak.nix.

Ejemplo: modules/core/flatpak.nix actual

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

2. Ubica la lista packages bajo services.flatpak.packages.
3. Agrega el ID de la aplicación Flatpak (tal como aparece en Flathub) al array.
   - IDs de ejemplo del config por defecto:
     - "com.github.tchx84.Flatseal" (Flatseal — gestionar permisos de Flatpak)
     - "io.github.flattool.Warehouse" (Warehouse — gestionar Flatpaks)
     - "com.obsproject.Studio" (OBS Studio — Flatpak oficial)

Nota: Para encontrar el ID correcto de Flatpak, busca la app en Flathub y copia el ID que aparece en su página (por ejemplo, org.mozilla.firefox): https://flathub.org

4. Guarda el archivo.
5. Reconstruye el sistema para instalar la nueva app:
   - zcli rebuild
   - o usa tu alias fr (flake rebuild)

Cómo eliminar una app Flatpak

1. Abre modules/core/flatpak.nix.
2. Elimina el ID de la app de services.flatpak.packages.
3. Guarda el archivo.
4. Reconstruye el sistema para desinstalarla de tu configuración declarativa:
   - zcli rebuild

Notas sobre OBS (ejemplo)

- La configuración incluye com.obsproject.Studio por defecto (Flatpak oficial).
- Si prefieres el paquete nativo de OBS, comenta la entrada del Flatpak y establece enableObs = true; en el variables.nix de tu host, según las notas en los comentarios.

Actualizaciones automáticas en reconstrucción

- update.onActivation = true significa que los Flatpaks se actualizarán cuando reconstruyas y actives la nueva generación. Esto ayuda a mantener los Flatpaks al día automáticamente.

Consejos

- Encuentra IDs de Flatpak en https://flathub.org buscando la app y copiando el ID (por ejemplo, org.mozilla.firefox).
- Después de reconstruir, puedes verificar instalaciones con:
  - flatpak list
- Puedes ajustar permisos y sandboxing con Flatseal (incluido por defecto).
