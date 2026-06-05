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
  copilotVer = "1.388.0";
  copilotChatVer = "1.120.0";
  codeiumVer = "1.49.2";

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

  codeRunnerExts = extOrMarketplace {
    publisher = "formulahendry";
    name = "code-runner";
    version = codeRunnerVer;
    sha256 = "sha256-TI5K6n3QfJwgFz5xhpdZ+yzi9VuYGcSzdBckZ68DsUQ=";
  };

  # Continue.dev is not on OpenVSX so we fetch from marketplace
  # copilotExts = extOrMarketplace {
  #   publisher = "GitHub";
  #   name = "copilot";
  #   version = copilotVer;
  #   sha256 = "sha256-7RjK8+PNI+rIuRQfCwpvswAiz991dacRO2qYhcv1vhk="; # will be replaced on first build
  # };
  # copilotChatExts = extOrMarketplace {
  #   publisher = "GitHub";
  #   name = "copilot-chat";
  #   version = copilotChatVer;
  #   sha256 = "sha256-eFLfYMFxvgtZtmwLsxfneMjD4jOg8/Uk0Eu/6+A6odY="; # will be replaced on first build
  # };

  codeiumExts = extOrMarketplace {
    publisher = "Codeium";
    name = "codeium";
    version = codeiumVer;
    sha256 = "sha256-Nj7r596RWuUNkjn06q5yEaMAqphPXWx+8oIw/GtXwFc="; # will be replaced on first build
  };
in {
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;

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

          llvm-vs-code-extensions.vscode-clangd
          divyanshuagrawal.competitive-programming-helper

          vscjava.vscode-java-debug
          vscjava.vscode-java-dependency
          vscjava.vscode-java-pack
          vscjava.vscode-java-test
          vscjava.vscode-maven
          redhat.java

          ms-python.python
        ])
        ++ hyprlangExts
        ++ hyprlsExts
        ++ neroHyprlandExts
        ++ codeRunnerExts
        ++ tinymistExts
        # ++ copilotExts
        # ++ copilotChatExts;
        ++ codeiumExts;

      userSettings = lib.mkForce {
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

        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 1000;

        "git.autofetch" = true;
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;

        "redhat.telemetry.enabled" = false;
        "explorer.confirmDelete" = false;

        # "workbench.colorTheme" = "Catppuccin Mocha";
        # "workbench.iconTheme" = "catppuccin-mocha";

        "clangd.path" = "${pkgs.clang-tools}/bin/clangd";

        # Codeium keybinding (optional, default is Ctrl+Shift+L for chat)
        #"codeium.enableTabAutocomplete" = true;

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

  # Fix: symlink ~/.vscode-oss/extensions -> ~/.vscode/extensions
  home.activation.vscodiumExtensionsDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -L "$HOME/.vscode-oss/extensions" ]; then
      $DRY_RUN_CMD rm -rf "$HOME/.vscode-oss/extensions"
      $DRY_RUN_CMD ln -sf "$HOME/.vscode/extensions" "$HOME/.vscode-oss/extensions"
    fi
  '';

  home.packages = with pkgs; [
    jdk21
    clang-tools
  ];

  home.file.".config/VSCodium/User/snippets/cpp.json".text = ''
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
          "",
          "typedef vector<int> vi;",
          "typedef long long ll;",
          "typedef vector<ll> vl;",
          "typedef vector<vi> vvi;",
          "typedef vector<vl> vvl;",
          "typedef pair<int,int> pii;",
          "typedef pair<ll,ll> pll;",
          "typedef vector<pll> vpl;",
          "typedef map<int,int> mii;",
          "",
          "#define fastInput() ios_base::sync_with_stdio(0); cin.tie(0); cout.tie(0);",
          "#define el \"\\n\"",
          "#define pb push_back",
          "#define YES cout << \"YES\\n\"",
          "#define NO cout << \"NO\\n\"",
          "#define allr(a) a.rbegin(), a.rend()",
          "#define all(a) a.begin(), a.end()",
          "#define vin(v) for(auto &u : v) cin >> u",
          "#define vout(v) for(auto u : v) cout << u << \" \"",
          "#define F first",
          "#define S second",
          "#define sp ' '",
          "#define mem(a,b) memset(a,b,sizeof(a))",
          "#define gcd(a,b) __gcd(a,b)",
          "int const MOD = 1e9 + 7;",
          "",
          "void solve(){",
          "\t$0",
          "}",
          "",
          "int main(){",
          "\tfastInput();",
          "\t",
          "\tll t = 1;",
          "\tcin >> t;",
          "\twhile(t--){",
          "\t\tsolve();",
          "\t}",
          "\t",
          "\treturn 0;",
          "}"
        ],
        "description": "Competitive programming template with solve() and test cases"
      },
      "CP Single Main Template": {
        "prefix": "cpm",
        "body": [
          "#include <bits/stdc++.h>",
          "using namespace std;",
          "",
          "typedef vector<int> vi;",
          "typedef long long ll;",
          "typedef vector<ll> vl;",
          "typedef vector<vi> vvi;",
          "typedef vector<vl> vvl;",
          "typedef pair<int,int> pii;",
          "typedef pair<ll,ll> pll;",
          "typedef vector<pll> vpl;",
          "typedef map<int,int> mii;",
          "",
          "#define fastInput() ios_base::sync_with_stdio(0); cin.tie(0); cout.tie(0);",
          "#define el \"\\n\"",
          "#define pb push_back",
          "#define YES cout << \"YES\\n\"",
          "#define NO cout << \"NO\\n\"",
          "#define allr(a) a.rbegin(), a.rend()",
          "#define all(a) a.begin(), a.end()",
          "#define vin(v) for(auto &u : v) cin >> u",
          "#define vout(v) for(auto u : v) cout << u << \" \"",
          "#define F first",
          "#define S second",
          "#define sp ' '",
          "#define mem(a,b) memset(a,b,sizeof(a))",
          "#define gcd(a,b) __gcd(a,b)",
          "int const MOD = 1e9 + 7;",
          "",
          "int main(){",
          "\tfastInput();",
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
