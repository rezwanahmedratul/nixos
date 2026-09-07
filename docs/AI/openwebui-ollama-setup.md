English | [Español](./openwebui-ollama-setup.es.md)

# OpenWebUI + Ollama Setup
This document describes the OpenWebUI + Ollama integration added to ddubsOS for NVIDIA-enabled systems.

## What Was Added

### New Module
- **File**: `modules/services/openwebui-ollama.nix`
- **Purpose**: Provides a NixOS module to run OpenWebUI and Ollama using Docker containers with GPU support

### Profile Integration
The module has been integrated into:
- `profiles/nvidia/default.nix` - For desktop NVIDIA systems
- `profiles/nvidia-laptop/default.nix` - For NVIDIA laptop systems with PRIME

## Features

### Services Provided
1. **Ollama**: AI model inference engine
   - Runs on port 11434 (configurable)
   - Uses NVIDIA GPU acceleration via Docker
   - Persistent model storage in `/var/lib/openwebui-ollama/ollama`

2. **OpenWebUI**: Web interface for interacting with LLMs
   - Runs on port 3000 (configurable)
   - Connects to local Ollama instance
   - Persistent data storage in `/var/lib/openwebui-ollama/openwebui`

### Configuration Options
- `services.openwebui-ollama.enable` - Enable/disable the service
- `services.openwebui-ollama.openwebuiPort` - Port for web interface (default: 3000)
- `services.openwebui-ollama.ollamaPort` - Port for Ollama API (default: 11434)
- `services.openwebui-ollama.dataDir` - Data storage directory (default: /var/lib/openwebui-ollama)
- `services.openwebui-ollama.user` - Service user (default: openwebui)
- `services.openwebui-ollama.group` - Service group (default: openwebui)

### Technical Details
- Uses Docker with `--privileged` flag as requested
- Enables NVIDIA Container Toolkit for GPU access
- Creates dedicated system user/group for security
- Automatic container lifecycle management
- Firewall ports are automatically opened
- Includes docker and docker-compose in system packages

## Usage

### After System Rebuild
1. Access OpenWebUI at `http://localhost:3000` (or configured port)
2. The first time you use it, you may need to pull some models via Ollama
3. You can interact with the Ollama API directly at `http://localhost:11434`

### Managing Models
You can use the Ollama API directly or through the OpenWebUI interface:
```bash
# Example: Pull a model (run as the openwebui user or with docker)
docker exec ollama ollama pull llama2
```

### Service Management

#### Using the Management Script (Recommended)
A convenient management script `ollama-webui-manager` is automatically installed:

```bash
# Check status
ollama-webui-manager status

# Start/stop services
ollama-webui-manager start
ollama-webui-manager stop
ollama-webui-manager restart

# View logs
ollama-webui-manager logs        # both services
ollama-webui-manager logs ollama # just Ollama
ollama-webui-manager logs webui  # just OpenWebUI

# List available models
ollama-webui-manager models

# Test connections
ollama-webui-manager test

# Show help
ollama-webui-manager help
```

#### Using systemctl directly
```bash
# Check status
sudo systemctl status ollama-docker openwebui-docker

# Restart services
sudo systemctl restart ollama-docker openwebui-docker

# View logs
sudo journalctl -u ollama-docker -f
sudo journalctl -u openwebui-docker -f
```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   OpenWebUI     │────│     Ollama      │────│   NVIDIA GPU    │
│   (Port 3000)   │    │   (Port 11434)  │    │                 │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │
         │                        │
         ▼                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Engine                                │
│                  (with NVIDIA runtime)                          │
└─────────────────────────────────────────────────────────────────┘
```

## Notes
- The module is only enabled for `nvidia` and `nvidia-laptop` profiles
- Docker containers run with `--privileged` flag as requested
- Both services will automatically restart on failure
- Data persistence is maintained across container restarts
- The configuration follows NixOS best practices for service modules
