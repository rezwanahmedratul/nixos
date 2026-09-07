[English](./HowTo-add-hardware-modules-to-host.md) | Español

# Añadir módulos de nixos-hardware por host (ejemplo: MacBookPro 8,1)

Esta guía muestra cómo habilitar módulos de hardware específicos de NixOS (de nixos-hardware) para un solo host en una configuración con flakes de ddubsOS. Usaremos como ejemplo el Apple MacBookPro 8,1, pero los pasos aplican a cualquier dispositivo listado en el repositorio nixos-hardware.

- Repositorio de módulos: https://github.com/NixOS/nixos-hardware
- Módulo de ejemplo: apple/macbook-pro/8-1 → atributo: nixos-hardware.nixosModules.apple-macbook-pro-8-1

## Requisitos previos
- Tu sistema usa flakes (ddubsOS lo hace).
- Agregaste nixos-hardware como input de flake (si no, ver Paso 1).

## Paso 1 — Asegura que nixos-hardware sea un input de flake
Agrega o confirma el input nixos-hardware en tu flake.nix. Usar la referencia del repo es suficiente (no necesitas agregar /master):

```nix path=null start=null
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };
}
```

Si cambiaste inputs, actualiza el archivo de bloqueo (lock file):

```bash path=null start=null
nix flake update nixos-hardware
# o
nix flake lock --update-input nixos-hardware
```

## Paso 2 — Importa el módulo de hardware para un host
Hay dos enfoques comunes y ambos son válidos. Elige uno.

### Opción A (recomendada): Importa en la lista modules del host (en outputs)
Agrega el módulo al arreglo modules de ese host específico en flake.nix.

```nix path=null start=null
{
  outputs = { self, nixpkgs, nixos-hardware, ... }:
  {
    nixosConfigurations = {
      macbook = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # MacBookPro 8,1 (Intel) corre Linux
        modules = [
          ./hosts/macbook/configuration.nix
          nixos-hardware.nixosModules.apple-macbook-pro-8-1
        ];
      };
    };
  };
}
```

### Opción B: Importa desde el configuration.nix del host
Pasa nixos-hardware a tus módulos mediante specialArgs e impórtalo dentro del archivo del host.

```nix path=null start=null
# flake.nix (partes relevantes)
{
  outputs = { self, nixpkgs, nixos-hardware, ... }:
  {
    nixosConfigurations.macbook = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit nixos-hardware; };
      modules = [ ./hosts/macbook/configuration.nix ];
    };
  };
}
```

```nix path=null start=null
# hosts/macbook/configuration.nix
{ config, pkgs, lib, nixos-hardware, ... }:
{
  imports = [
    nixos-hardware.nixosModules.apple-macbook-pro-8-1
  ];
}
```

### Importación alternativa por ruta (string)
Si prefieres rutas tipo string, también puedes hacer:

```nix path=null start=null
imports = [
  "${nixos-hardware}/apple/macbook-pro/8-1"
];
```

Nota: Igual necesitas tener nixos-hardware en alcance (por ejemplo, mediante specialArgs).

## Paso 3 — Aplica tu configuración
Compila y cambia a la configuración de ese host:

```bash path=null start=null
sudo nixos-rebuild switch --flake .#macbook
```

Si usas los helpers de ddubsOS:

```bash path=null start=null
zcli rebuild
```

## Cómo encontrar el nombre de módulo correcto
- Navega el directorio del repositorio nixos-hardware que coincide con tu modelo.
- Convierte su ruta en el atributo nixosModules reemplazando slashes por guiones y quitando caracteres especiales. Ejemplo:
  - Ruta: apple/macbook-pro/8-1
  - Atributo: nixos-hardware.nixosModules.apple-macbook-pro-8-1

En caso de duda, también puedes importar por ruta (string) como se mostró arriba.

## Actualizar nixos-hardware más adelante
Mantén los módulos de hardware al día actualizando el input:

```bash path=null start=null
nix flake update nixos-hardware
```

## Consejos de verificación
- Primero un dry run:

```bash path=null start=null
sudo nixos-rebuild dry-run --flake .#macbook
```

- Tras aplicar, confirma que funcionalidades específicas del equipo (trackpad, retroiluminación, sensores) mejoren directamente.
- Si mantienes un variables.nix por host, deja allí toggles de hardware para mayor claridad.

## Solución de problemas
- Nombre de atributo incorrecto: usa la forma de importación por ruta ("${nixos-hardware}/...") para verificar, o revisa el nombre del directorio en el repo.
- Sistema incorrecto: asegúrate de que system coincide con tu CPU (por ejemplo, "x86_64-linux" para MacBookPro 8,1 con Intel).
- Conflictos con opciones existentes: si otro módulo define las mismas opciones, verifica el orden de importación—los módulos que van después suelen prevalecer.

## Ejemplo de estructura de directorios (simplificada)

```text path=null start=null
.
├─ flake.nix
└─ hosts/
   └─ macbook/
      ├─ configuration.nix
      └─ variables.nix   # opcional, para toggles específicos del host
```

