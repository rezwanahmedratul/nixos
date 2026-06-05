{
  pkgs,
  ...
}: {
  programs.zed-editor = {
    enable = true;

    extensions = [
      "nix"
      "toml"
      "bash"
      "json"
      "markdown"
      "typst"
      "cpp"
      "python"
      "java"
    ];

    userSettings = {
      autosave = "on_focus_change";
      format_on_save = true;

      vim_mode = false;

      terminal = {
        shell = {
          program = "${pkgs.zsh}/bin/zsh";
        };
      };

      features = {
        copilot = false;
      };

      # -----------------------
      # Language formatting
      # -----------------------
      languages = {
        Nix = {
          formatter = {
            external = {
              command = "alejandra";
              arguments = ["-"];
            };
          };
        };

        Typst = {
          formatter = {
            external = {
              command = "typstfmt";
              arguments = ["-"];
            };
          };
        };
      };

      # -----------------------
      # LSP configuration
      # -----------------------
      lsp = {
        nixd = {
          binary.path = "nixd";
        };

        bash-language-server = {
          binary.path = "bash-language-server";
        };

        clangd = {
          binary.path = "clangd";
        };

        pyright = {
          binary.path = "pyright-langserver";
        };

        jdtls = {
          binary.path = "jdtls";
        };

        tinymist = {
          binary.path = "tinymist";
        };
      };
    };
  };

  nixpkgs.config.allowUnfree = true;
}