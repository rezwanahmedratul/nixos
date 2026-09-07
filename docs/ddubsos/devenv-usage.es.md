[English](./devenv-usage.md) | Español

# 🛠️ Guía de Uso de DevEnv para ddubsos
Esta guía explica cómo utilizar el soporte `devenv` recién integrado en ddubsos para crear entornos de desarrollo reproducibles.

## 🚀 ¿Qué es DevEnv?

**DevEnv** es una herramienta rápida y declarativa para entornos de desarrollo que:
- Crea entornos de proyecto aislados y reproducibles
- Se integra perfectamente con direnv para una carga automática
- Soporta múltiples lenguajes de programación
- Permite dependencias y servicios por proyecto
- Funciona de manera consistente en diferentes máquinas

## ✅ Estado de la Instalación

DevEnv ya está **instalado** en ddubsos con:
- ✅ Comando `devenv` disponible en todo el sistema
- ✅ `direnv` configurado e integrado
- ✅ Plantillas de desarrollo disponibles
- ✅ Alias de shell para mayor comodidad

## 🎯 Inicio Rápido

### 1. Habilitar el Módulo de Entorno de Desarrollo (Opcional)

Para habilitar herramientas de desarrollo adicionales y la integración con direnv:

```nix
# En el home.nix de tu host o en modules/home/default.nix
programs.dev-env.enable = true;
```

### 2. Crear un Nuevo Entorno de Proyecto

```bash
# Crear un nuevo directorio de proyecto
mkdir mi-proyecto-python
cd mi-proyecto-python

# Inicializar devenv
devenv init

# Esto crea:
# - devenv.nix (configuración del entorno)
# - .envrc (integración con direnv)
# - devenv.lock (archivo de bloqueo de dependencias)
```

### 3. Configurar tu Entorno

Edita `devenv.nix`:

```nix
{ pkgs, ... }:

{
  # Variables de entorno
  env.GREETING = "¡Hola desde devenv!";

  # Paquetes disponibles en este entorno
  packages = with pkgs; [ 
    python311
    python311Packages.pip
    python311Packages.virtualenv
    nodejs
    git
  ];

  # Configuración específica del lenguaje
  languages.python = {
    enable = true;
    version = "3.11";
    venv.enable = true;
  };

  # Scripts disponibles en el entorno
  scripts.hello.exec = "echo $GREETING";
  scripts.dev.exec = "python app.py";

  # Servicios (bases de datos, etc.)
  services.postgres.enable = true;

  # Hook de shell al entrar en el entorno
  enterShell = ''
    echo "🐍 ¡Entorno de desarrollo de Python activado!"
    python --version
  '';

  # Hooks de pre-commit
  pre-commit.hooks = {
    black.enable = true;
    flake8.enable = true;
  };
}
```

### 4. Activar el Entorno

```bash
# Permitir que direnv cargue el entorno
direnv allow

# O entrar manualmente en el entorno
devenv shell
```

## 📋 Usando Plantillas

ddubsos incluye plantillas listas para usar:

### Plantilla de Python
```bash
# Copiar la plantilla de Python
cp ~/.local/share/devenv-templates/python/devenv.nix .
cp ~/.local/share/devenv-templates/.envrc-example .envrc

# Permitir direnv
direnv allow
```

### Plantilla de Node.js  
```bash
# Copiar la plantilla de Node.js
cp ~/.local/share/devenv-templates/nodejs/devenv.nix .
cp ~/.local/share/devenv-templates/.envrc-example .envrc

# Permitir direnv
direnv allow
```

### Plantilla de Rust
```bash
# Copiar la plantilla de Rust
cp ~/.local/share/devenv-templates/rust/devenv.nix .
cp ~/.local/share/devenv-templates/.envrc-example .envrc

# Permitir direnv  
direnv allow
```

## 🔧 Alias Convenientes

Cuando el módulo dev-env está habilitado, estos alias están disponibles:

```bash
denv              # devenv
denv-init         # devenv init
denv-shell        # devenv shell  
denv-up           # devenv up
denv-info         # devenv info
denv-gc           # devenv gc
```

## 💡 Casos de Uso Comunes

### Desarrollo Web
```nix
{ pkgs, ... }:

{
  packages = with pkgs; [ nodejs yarn ];
  
  languages.javascript = {
    enable = true;
    npm.enable = true;
    yarn.enable = true;
  };
  
  services.postgres.enable = true;
  services.redis.enable = true;
  
  scripts.dev.exec = "npm run dev";
  scripts.build.exec = "npm run build";
}
```

### Ciencia de Datos
```nix
{ pkgs, ... }:

{
  packages = with pkgs; [ 
    python311
    python311Packages.jupyter
    python311Packages.pandas
    python311Packages.numpy
    python311Packages.matplotlib
  ];
  
  languages.python = {
    enable = true;
    version = "3.11";
    venv.enable = true;
  };
  
  scripts.notebook.exec = "jupyter lab";
}
```

### DevOps/Infraestructura
```nix
{ pkgs, ... }:

{
  packages = with pkgs; [
    terraform
    ansible
    kubectl
    docker-compose
    aws-cli
  ];
  
  env.KUBECONFIG = "./.kube/config";
  
  scripts.deploy.exec = "terraform apply";
  scripts.test.exec = "ansible-playbook test.yml";
}
```

## 🔄 Flujo de Trabajo

1. **Entrar al Proyecto**: `cd mi-proyecto` (el entorno se carga automáticamente)
2. **Instalar Dependencias**: Usa herramientas específicas del lenguaje (pip, npm, cargo, etc.)
3. **Ejecutar Scripts**: `hello`, `dev`, `test`, etc.
4. **Salir**: `cd ..` (el entorno se descarga automáticamente)

## 🏗️ Funciones Avanzadas

### Múltiples Servicios
```nix
services = {
  postgres.enable = true;
  redis.enable = true;
  elasticsearch.enable = true;
};
```

### Variables de Entorno desde Archivos
```nix
# En .envrc
dotenv_if_exists .env.local
dotenv_if_exists .env
```

### Procesos Personalizados
```nix
processes = {
  web.exec = "python manage.py runserver";
  worker.exec = "celery worker";
  scheduler.exec = "celery beat";
};
```

## 🐛 Solución de Problemas

### El Entorno no se Carga
```bash
# Verificar el estado de direnv
direnv status

# Recargar el entorno
direnv reload

# Permitir el entorno
direnv allow
```

### Paquete no Encontrado
```bash
# Buscar paquetes
nix search nixpkgs python311Packages.requests

# Verificar qué está disponible
devenv info
```

### Limpiar Entornos
```bash
# Limpiar entornos antiguos
devenv gc

# Eliminar el entorno por completo
rm -rf .devenv devenv.lock
```

## 📖 Recursos Adicionales

- [Documentación de DevEnv](https://devenv.sh/)
- [Búsqueda de Paquetes de Nix](https://search.nixos.org/packages)
- [Documentación de Direnv](https://direnv.net/)

## 🎉 Beneficios

✅ **Reproducible**: Mismo entorno en cada máquina  
✅ **Aislado**: Las dependencias del proyecto no entran en conflicto  
✅ **Rápido**: Carga y almacenamiento en caché automáticos  
✅ **Declarativo**: Entorno como código  
✅ **Amigable para equipos**: Comparte entornos a través de git  
✅ **Agnóstico del lenguaje**: Funciona con cualquier lenguaje  

¡Feliz codificación! 🚀
