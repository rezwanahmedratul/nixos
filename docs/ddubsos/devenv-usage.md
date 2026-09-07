English | [Español](./devenv-usage.es.md)

# 🛠️ DevEnv Usage Guide for ddubsos
This guide explains how to use the newly integrated `devenv` support in ddubsos for creating reproducible development environments.

## 🚀 What is DevEnv?

**DevEnv** is a fast, declarative development environment tool that:
- Creates isolated, reproducible project environments
- Integrates seamlessly with direnv for automatic loading
- Supports multiple programming languages
- Enables per-project dependencies and services
- Works consistently across different machines

## ✅ Installation Status

DevEnv is **already installed** in ddubsos with:
- ✅ `devenv` command available system-wide
- ✅ `direnv` configured and integrated
- ✅ Development templates available
- ✅ Shell aliases for convenience

## 🎯 Quick Start

### 1. Enable Development Environment Module (Optional)

To enable additional development tools and direnv integration:

```nix
# In your host's home.nix or modules/home/default.nix
programs.dev-env.enable = true;
```

### 2. Create a New Project Environment

```bash
# Create a new project directory
mkdir my-python-project
cd my-python-project

# Initialize devenv
devenv init

# This creates:
# - devenv.nix (environment configuration)
# - .envrc (direnv integration)
# - devenv.lock (dependency lock file)
```

### 3. Configure Your Environment

Edit `devenv.nix`:

```nix
{ pkgs, ... }:

{
  # Environment variables
  env.GREETING = "Hello from devenv!";

  # Packages available in this environment
  packages = with pkgs; [ 
    python311
    python311Packages.pip
    python311Packages.virtualenv
    nodejs
    git
  ];

  # Language-specific configuration
  languages.python = {
    enable = true;
    version = "3.11";
    venv.enable = true;
  };

  # Scripts available in the environment
  scripts.hello.exec = "echo $GREETING";
  scripts.dev.exec = "python app.py";

  # Services (databases, etc.)
  services.postgres.enable = true;

  # Shell hook when entering environment
  enterShell = ''
    echo "🐍 Python development environment activated!"
    python --version
  '';

  # Pre-commit hooks
  pre-commit.hooks = {
    black.enable = true;
    flake8.enable = true;
  };
}
```

### 4. Activate the Environment

```bash
# Allow direnv to load the environment
direnv allow

# Or manually enter the environment
devenv shell
```

## 📋 Using Templates

ddubsos includes ready-to-use templates:

### Python Template
```bash
# Copy the Python template
cp ~/.local/share/devenv-templates/python/devenv.nix .
cp ~/.local/share/devenv-templates/.envrc-example .envrc

# Allow direnv
direnv allow
```

### Node.js Template  
```bash
# Copy the Node.js template
cp ~/.local/share/devenv-templates/nodejs/devenv.nix .
cp ~/.local/share/devenv-templates/.envrc-example .envrc

# Allow direnv
direnv allow
```

### Rust Template
```bash
# Copy the Rust template
cp ~/.local/share/devenv-templates/rust/devenv.nix .
cp ~/.local/share/devenv-templates/.envrc-example .envrc

# Allow direnv  
direnv allow
```

## 🔧 Convenient Aliases

When the dev-env module is enabled, these aliases are available:

```bash
denv              # devenv
denv-init         # devenv init
denv-shell        # devenv shell  
denv-up           # devenv up
denv-info         # devenv info
denv-gc           # devenv gc
```

## 💡 Common Use Cases

### Web Development
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

### Data Science
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

### DevOps/Infrastructure
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

## 🔄 Workflow

1. **Enter Project**: `cd my-project` (environment loads automatically)
2. **Install Dependencies**: Use language-specific tools (pip, npm, cargo, etc.)
3. **Run Scripts**: `hello`, `dev`, `test`, etc.
4. **Exit**: `cd ..` (environment unloads automatically)

## 🏗️ Advanced Features

### Multiple Services
```nix
services = {
  postgres.enable = true;
  redis.enable = true;
  elasticsearch.enable = true;
};
```

### Environment Variables from Files
```nix
# In .envrc
dotenv_if_exists .env.local
dotenv_if_exists .env
```

### Custom Processes
```nix
processes = {
  web.exec = "python manage.py runserver";
  worker.exec = "celery worker";
  scheduler.exec = "celery beat";
};
```

## 🐛 Troubleshooting

### Environment Not Loading
```bash
# Check direnv status
direnv status

# Reload environment
direnv reload

# Allow environment
direnv allow
```

### Package Not Found
```bash
# Search for packages
nix search nixpkgs python311Packages.requests

# Check what's available
devenv info
```

### Clean Up Environments
```bash
# Clean up old environments
devenv gc

# Remove environment completely
rm -rf .devenv devenv.lock
```

## 📖 Additional Resources

- [DevEnv Documentation](https://devenv.sh/)
- [Nix Package Search](https://search.nixos.org/packages)
- [Direnv Documentation](https://direnv.net/)

## 🎉 Benefits

✅ **Reproducible**: Same environment on every machine  
✅ **Isolated**: Project dependencies don't conflict  
✅ **Fast**: Automatic loading and caching  
✅ **Declarative**: Environment as code  
✅ **Team-friendly**: Share environments via git  
✅ **Language-agnostic**: Works with any language  

Happy coding! 🚀
