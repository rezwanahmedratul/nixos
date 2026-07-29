{
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.lib) attrByPath;

  # Versions
  hyprlangVer = "0.0.3";
  hyprlsVer = "0.5.2";
  neroHyprlandVer = "0.0.2";
  codeRunnerVer = "0.12.2";
  tinymistVer = "0.14.16";
  typstPreviewVer = "0.11.14";
  sqlExtsVer = "1.43.0";
  #geminiVer = "2.87.0";
  cppExtsThemesVer = "2.0.0";
  cppExtsDevToolsVer = "0.5.13";
  chatgptVer = "26.429.30905";

  # Helper function
  extOrMarketplace = {
    publisher,
    name,
    version ? null,
    sha256 ? null,
  }: let
    fromOpenVSX = attrByPath [publisher name] null pkgs.vscode-extensions;
  in
    if fromOpenVSX != null
    then [fromOpenVSX]
    else if version == null
    then []
    else
      pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          inherit name publisher version;
          sha256 =
            if sha256 == null
            then pkgs.lib.fakeSha256
            else sha256;
        }
      ];

  # Hyprland related
  hyprlangExts = extOrMarketplace {
    publisher = "fireblast";
    name = "hyprlang-vscode";
    version = hyprlangVer;
    sha256 = "sha256-iMCyomgMGGUXaVqq1l7bgyvFgZa/W/eWHaqkA5RmExE=";
  };

  hyprlsExts = extOrMarketplace {
    publisher = "ewen-lbh";
    name = "vscode-hyprls";
    version = hyprlsVer;
    sha256 = "sha256-IU8P1BfZfAkLMbSROTJRdP9EgrM7dExpeQUyfLGjPNo=";
  };

  neroHyprlandExts = extOrMarketplace {
    publisher = "amarcos1337";
    name = "nero-hyprland";
    version = neroHyprlandVer;
    sha256 = "sha256-3RiSYmJK/xODCvUi9c2xtvEIWSBABVHk6QYCAFoqsa8=";
  };

  tinymistExts = extOrMarketplace {
    publisher = "myriad-dreamin";
    name = "tinymist";
    version = tinymistVer;
    sha256 = pkgs.lib.fakeSha256;
  };

  typstPreviewExts = extOrMarketplace {
    publisher = "mgt19937";
    name = "typst-preview";
    version = typstPreviewVer;
    sha256 = pkgs.lib.fakeSha256;
  };

  sqlExts = extOrMarketplace {
    publisher = "ms-mssql";
    name = "mssql";
    version = sqlExtsVer;
    sha256 = "sha256-rzBnBZ9Dy7nQOOCL4Cd3GdiI8UrZiLMzbpAElu8103I=";
  };

  # geminiCodeAssistExts = extOrMarketplace {
  #   publisher = "google";
  #   name = "geminicodeassist";
  #   version = geminiVer;
  #   sha256 = "sha256-wgsG/8Vph3rtn3oA1B8W1T1VK6U3emnE0bgqlsAPjjc=";
  # };

  # chatGPTExts = extOrMarketplace {
  #   publisher = "openai";
  #   name = "chatgpt";
  #   version = chatgptVer;
  #   sha256 = "sha256-KspK1d7bQpO+LipstEpWafcz/eYG1fiuLSszw4nYjE8=";
  # };

  # codeRunnerExts = extOrMarketplace {
  #   publisher = "formulahendry";
  #   name = "code-runner";
  #   version = codeRunnerVer;
  #   sha256 = pkgs.lib.fakeSha256;
  # };

  cppExtraExts = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "cpptools-themes";
      publisher = "ms-vscode";
      version = cppExtsThemesVer;
      sha256 = "sha256-YWA5UsA+cgvI66uB9d9smwghmsqf3vZPFNpSCK+DJxc=";
    }
    {
      name = "cpp-devtools";
      publisher = "ms-vscode";
      version = cppExtsDevToolsVer;
      sha256 = "sha256-g8ZXdEgKB6okJEVXvFQMGz5oDMsOh5mWzl50B/etVjw=";
    }
    {
      publisher = "formulahendry";
      name = "code-runner";
      version = codeRunnerVer;
      sha256 = "sha256-TI5K6n3QfJwgFz5xhpdZ+yzi9VuYGcSzdBckZ68DsUQ=";
    }
  ];
in {
  programs.vscode = {
    enable = true;

    profiles.default = {
      extensions =
        (with pkgs.vscode-extensions; [
          catppuccin.catppuccin-vsc
          bbenoist.nix
          kamadorueda.alejandra
          jeff-hykin.better-nix-syntax
          mads-hartmann.bash-ide-vscode
          tamasfe.even-better-toml
          zainchen.json
          shd101wyy.markdown-preview-enhanced

          # c/cpp extensions
          ms-vscode.cpptools-extension-pack
          ms-vscode.cpptools
          ms-vscode.cmake-tools
          ms-vscode.makefile-tools
          divyanshuagrawal.competitive-programming-helper

          # Java Extensions
          #vscjava.vscode-gradle
          vscjava.vscode-java-debug
          vscjava.vscode-java-dependency
          vscjava.vscode-java-pack
          vscjava.vscode-java-test
          vscjava.vscode-maven
          redhat.java

          # python
          ms-python.python
          #github.copilot
        ])
        ++ hyprlangExts
        ++ hyprlsExts
        ++ neroHyprlandExts
        # ++ sqlExts
        #++ codeRunnerExts
        ++ cppExtraExts
        #++ chatGPTExts
        #++ geminiCodeAssistExts
        ++ tinymistExts;

      userSettings = lib.mkForce {
        # Java settings for NixOS
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
        "java.debug.settings.console" = "integratedTerminal";
        "code-runner.runInTerminal" = true;
        "code-runner.saveFileBeforeRun" = true;

        "chat.disableAIFeatures" = false;
        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 1000;

        "git.autofetch" = true;
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;

        "redhat.telemetry.enabled" = true;
        "explorer.confirmDelete" = false;

        "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.iconTheme" = "catppuccin-mocha";
        # "workbench.colorTheme" = "Stylix";
        # "workbench.iconTheme" = "Stylix";

        "workbench.activityBar.compact" = "true";

        "terminal.integrated.profiles.linux" = {
          "bash" = {
            "path" = "bash";
            "icon" = "terminal-bash";
          };

          "zsh" = {
            "path" = "/etc/profiles/per-user/ratul/bin/zsh";
          };

          "fish" = {
            "path" = "fish";
          };

          "tmux" = {
            "path" = "tmux";
            "icon" = "terminal-tmux";
          };

          "pwsh" = {
            "path" = "pwsh";
            "icon" = "terminal-powershell";
          };
        };
      };
    };
  };

  # Java runtime (IMPORTANT)
  home.packages = with pkgs; [
    jdk21
  ];

  # C++ snippets
  home.file.".config/Code/User/snippets/cpp.json".text = ''
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
        ],
        "description": "Basic CP boilerplate"
      },

      "CP Solve Template": {
        "prefix": "cpp",
        "body": [
          "#include <bits/stdc++.h>",
          "using namespace std;",
          "typedef long long ll;",
          "#define YES cout << \"YES\\n\"",
          "#define NO cout << \"NO\\n\"",
          "#define vin(v) for(auto &u : v) cin >> u",
          "#define vout(v) for(ll i = 0; i < (ll)v.size(); i++) cout << v[i] << (i + 1 == (ll)v.size() ? '\\n' : ' ')",
          "#define sp ' '",
          "",
          "void solve(){",
          "\t$0",
          "}",
          "",
          "int main(){",
          "\tios_base::sync_with_stdio(0); cin.tie(0); cout.tie(0);",
          "",
          "\tll t = 1;",
          "\tcin >> t;",
          "\twhile(t--){",
          "\t\tsolve();",
          "\t}",
          "",
          "\treturn 0;",
          "}"
        ],
        "description": "Competitive programming template with solve()"
      },

      "CP Single Main Template": {
        "prefix": "cpm",
        "body": [
          "#include <bits/stdc++.h>",
          "using namespace std;",
          "typedef long long ll;",
          "#define YES cout << \"YES\\n\"",
          "#define NO cout << \"NO\\n\"",
          "#define vin(v) for(auto &u : v) cin >> u",
          "#define vout(v) for(ll i = 0; i < (ll)v.size(); i++) cout << v[i] << (i + 1 == (ll)v.size() ? '\\n' : ' ')",
          "#define sp ' '",
          "",
          "int main(){",
          "\tios_base::sync_with_stdio(0); cin.tie(0); cout.tie(0);",
          "",
          "\t$0",
          "",
          "\treturn 0;",
          "}"
        ],
        "description": "Competitive programming single main template"
      }
    }
  '';

  nixpkgs.config.allowUnfree = true;
}
