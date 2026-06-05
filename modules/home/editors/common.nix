{ pkgs, lib, ... }:

let
  inherit (pkgs.lib) attrByPath;

  versions = {
    hyprlang = "0.0.3";
    hyprls = "0.5.2";
    neroHyprland = "0.0.2";
    codeRunner = "0.12.2";
    tinymist = "0.14.16";
    typstPreview = "0.11.14";

    cppThemes = "2.0.0";
    cppDevTools = "0.4.6";
  };

  extOrMarketplace = { publisher, name, version ? null, sha256 ? null }:
    let
      fromOpenVSX = attrByPath [ publisher name ] null pkgs.vscode-extensions;
    in
      if fromOpenVSX != null then
        [ fromOpenVSX ]
      else if version == null then
        []
      else
        pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            inherit name publisher version;
            sha256 = if sha256 == null then pkgs.lib.fakeSha256 else sha256;
          }
        ];

  # -------------------------
  # Core extension groups
  # -------------------------

  base = with pkgs.vscode-extensions; [
    catppuccin.catppuccin-vsc
    bbenoist.nix
    kamadorueda.alejandra
    jeff-hykin.better-nix-syntax
    mads-hartmann.bash-ide-vscode
    tamasfe.even-better-toml
    zainchen.json
    shd101wyy.markdown-preview-enhanced

    ms-vscode.cpptools-extension-pack
    ms-vscode.cpptools
    ms-vscode.cmake-tools
    ms-vscode.makefile-tools
    divyanshuagrawal.competitive-programming-helper

    vscjava.vscode-java-debug
    vscjava.vscode-java-dependency
    vscjava.vscode-java-pack
    vscjava.vscode-java-test
    vscjava.vscode-maven
    redhat.java

    ms-python.python
  ];

  hyprlang = extOrMarketplace {
    publisher = "fireblast";
    name = "hyprlang-vscode";
    version = versions.hyprlang;
    sha256 = "sha256-iMCyomgMGGUXaVqq1l7bgyvFgZa/W/eWHaqkA5RmExE=";
  };

  hyprls = extOrMarketplace {
    publisher = "ewen-lbh";
    name = "vscode-hyprls";
    version = versions.hyprls;
    sha256 = "sha256-IU8P1BfZfAkLMbSROTJRdP9EgrM7dExpeQUyfLGjPNo=";
  };

  nero = extOrMarketplace {
    publisher = "amarcos1337";
    name = "nero-hyprland";
    version = versions.neroHyprland;
    sha256 = "sha256-3RiSYmJK/xODCvUi9c2xtvEIWSBABVHk6QYCAFoqsa8=";
  };

  cppExtra = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "cpptools-themes";
      publisher = "ms-vscode";
      version = versions.cppThemes;
      sha256 = "sha256-YWA5UsA+cgvI66uB9d9smwghmsqf3vZPFNpSCK+DJxc=";
    }
    {
      name = "cpp-devtools";
      publisher = "ms-vscode";
      version = versions.cppDevTools;
      sha256 = "sha256-K2UCUI7Y3jcJLYeRORSs+nWH+SqDujz8CDP7yWy/aG4=";
    }
  ];

  optional = {
    tinymist = extOrMarketplace {
      publisher = "myriad-dreamin";
      name = "tinymist";
      version = versions.tinymist;
      sha256 = pkgs.lib.fakeSha256;
    };

    typst = extOrMarketplace {
      publisher = "mgt19937";
      name = "typst-preview";
      version = versions.typstPreview;
      sha256 = pkgs.lib.fakeSha256;
    };

    codeRunner = extOrMarketplace {
      publisher = "formulahendry";
      name = "code-runner";
      version = versions.codeRunner;
      sha256 = pkgs.lib.fakeSha256;
    };
  };

in {
  # 🔥 SINGLE SOURCE OF TRUTH (AUTO-SYNC)
  extensions =
    base
    ++ hyprlang
    ++ hyprls
    ++ nero
    ++ cppExtra
    ++ optional.tinymist
    ++ optional.typst
    ++ optional.codeRunner;

  settings = pkgs.jdk21: {
    "java.jdt.ls.java.home" = "${pkgs.jdk21}/lib/openjdk";

    "java.configuration.runtimes" = [
      {
        name = "JavaSE-21";
        path = "${pkgs.jdk21}/lib/openjdk";
        default = true;
      }
    ];

    "java.import.gradle.java.home" = "${pkgs.jdk21}/lib/openjdk";
    "java.import.maven.java.home" = "${pkgs.jdk21}/lib/openjdk";

    "code-runner.runInTerminal" = true;
    "code-runner.saveFileBeforeRun" = true;

    "files.autoSave" = "afterDelay";
    "files.autoSaveDelay" = 1000;

    "git.autofetch" = true;
    "git.enableSmartCommit" = true;

    "workbench.colorTheme" = "Catppuccin Mocha";
    "workbench.iconTheme" = "catppuccin-mocha";
  };

  cppSnippets = ''
{
  "CP Basic Boilerplate": {
    "prefix": "cpb",
    "body": [
      "#include <bits/stdc++.h>",
      "using namespace std;",
      "",
      "int main(){",
      "\t$0",
      "\treturn 0;",
      "}"
    ]
  }
}
'';
}