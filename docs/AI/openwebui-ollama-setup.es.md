[English](./openwebui-ollama-setup.md) | Español

# Configuración de OpenWebUI + Ollama
Este documento describe la integración de OpenWebUI + Ollama añadida a ddubsOS para sistemas con NVIDIA.

## Qué se ha Añadido

### Nuevo Módulo
- **Archivo**: `modules/services/openwebui-ollama.nix`
- **Propósito**: Proporciona un módulo de NixOS para ejecutar OpenWebUI y Ollama usando contenedores Docker con soporte para GPU.

### Integración en Perfiles
El módulo ha sido integrado en:
- `profiles/nvidia/default.nix` - Para sistemas de escritorio con NVIDIA
- `profiles/nvidia-laptop/default.nix` - Para sistemas portátiles con NVIDIA y PRIME

## Características

### Servicios Proporcionados
1. **Ollama**: Motor de inferencia de modelos de IA
   - Se ejecuta en el puerto 11434 (configurable)
   - Utiliza la aceleración de la GPU de NVIDIA a través de Docker
   - Almacenamiento persistente de modelos en `/var/lib/openwebui-ollama/ollama`

2. **OpenWebUI**: Interfaz web para interactuar con LLMs
   - Se ejecuta en el puerto 3000 (configurable)
   - Se conecta a la instancia local de Ollama
   - Almacenamiento persistente de datos en `/var/lib/openwebui-ollama/openwebui`

### Opciones de Configuración
- `services.openwebui-ollama.enable` - Habilita/deshabilita el servicio
- `services.openwebui-ollama.openwebuiPort` - Puerto para la interfaz web (por defecto: 3000)
- `services.openwebui-ollama.ollamaPort` - Puerto para la API de Ollama (por defecto: 11434)
- `services.openwebui-ollama.dataDir` - Directorio de almacenamiento de datos (por defecto: /var/lib/openwebui-ollama)
- `services.openwebui-ollama.user` - Usuario del servicio (por defecto: openwebui)
- `services.openwebui-ollama.group` - Grupo del servicio (por defecto: openwebui)

### Detalles Técnicos
- Utiliza Docker con el flag `--privileged` como se solicitó
- Habilita el NVIDIA Container Toolkit para el acceso a la GPU
- Crea un usuario/grupo de sistema dedicado por seguridad
- Gestión automática del ciclo de vida de los contenedores
- Los puertos del firewall se abren automáticamente
- Incluye docker y docker-compose en los paquetes del sistema

## Uso

### Después de Reconstruir el Sistema
1. Accede a OpenWebUI en `http://localhost:3000` (o el puerto configurado)
2. La primera vez que lo uses, puede que necesites descargar algunos modelos a través de Ollama
3. Puedes interactuar con la API de Ollama directamente en `http://localhost:11434`

### Gestión de Modelos
Puedes usar la API de Ollama directamente o a través de la interfaz de OpenWebUI:
```bash
# Ejemplo: Descargar un modelo (ejecutar como el usuario openwebui o con docker)
docker exec ollama ollama pull llama2
```

### Gestión del Servicio

#### Usando el Script de Gestión (Recomendado)
Un práctico script de gestión `ollama-webui-manager` se instala automáticamente:

```bash
# Comprobar el estado
ollama-webui-manager status

# Iniciar/detener servicios
ollama-webui-manager start
ollama-webui-manager stop
ollama-webui-manager restart

# Ver los registros
ollama-webui-manager logs        # ambos servicios
ollama-webui-manager logs ollama # solo Ollama
ollama-webui-manager logs webui  # solo OpenWebUI

# Listar los modelos disponibles
ollama-webui-manager models

# Probar las conexiones
ollama-webui-manager test

# Mostrar la ayuda
ollama-webui-manager help
```

#### Usando systemctl directamente
```bash
# Comprobar el estado
sudo systemctl status ollama-docker openwebui-docker

# Reiniciar los servicios
sudo systemctl restart ollama-docker openwebui-docker

# Ver los registros
sudo journalctl -u ollama-docker -f
sudo journalctl -u openwebui-docker -f
```

## Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   OpenWebUI     │────│     Ollama      │────│   GPU NVIDIA    │
│   (Puerto 3000) │    │   (Puerto 11434)│    │                 │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │
         │                        │
         ▼                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Motor de Docker                              │
│                  (con el runtime de NVIDIA)                     │
└─────────────────────────────────────────────────────────────────┘
```

## Notas
- El módulo solo está habilitado para los perfiles `nvidia` y `nvidia-laptop`
- Los contenedores de Docker se ejecutan con el flag `--privileged` como se solicitó
- Ambos servicios se reiniciarán automáticamente en caso de fallo
- La persistencia de los datos se mantiene entre reinicios de los contenedores
- La configuración sigue las mejores prácticas de NixOS para los módulos de servicio
