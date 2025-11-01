{
  description = "Ambxst by Axenide";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixgl, ... }: let
    linuxSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "i686-linux"
    ];

    forAllSystems = f:
      builtins.foldl' (acc: system: acc // { ${system} = f system; }) {} linuxSystems;
  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      lib = nixpkgs.lib;

      # Detect NixOS (nixos config only exists when NixOS imports us)
      isNixOS = pkgs ? config && pkgs.config ? nixosConfig;

      nixGL = nixgl.packages.${system}.nixGLDefault;

      wrapWithNixGL = pkg:
        if isNixOS then pkg else pkgs.symlinkJoin {
          name = "${pkg.pname or pkg.name}-nixGL";
          paths = [ pkg ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            for bin in $out/bin/*; do
              if [ -x "$bin" ]; then
                mv "$bin" "$bin.orig"
                makeWrapper ${nixGL}/bin/nixGL "$bin" --add-flags "$bin.orig"
              fi
            done
          '';
        };

      baseEnv = with pkgs; [
        (wrapWithNixGL quickshell)
        (wrapWithNixGL gpu-screen-recorder)
        (wrapWithNixGL mpvpaper)

        brightnessctl
        ddcutil

        wl-clipboard
        cliphist

        # nixGL solo en non-NixOS
        ] ++ (if isNixOS then [] else [ nixGL ])
        ++ (with pkgs; [
        mesa
        libglvnd
        egl-wayland
        wayland

        qt6.qtbase
        qt6.qtsvg
        qt6.qttools
        qt6.qtwayland
        qt6.qtdeclarative
        qt6.qtimageformats
        qt6.qtwebengine

        kdePackages.breeze-icons
        hicolor-icon-theme
        fuzzel
        wtype
        imagemagick
        matugen
        ffmpeg

        playerctl
        xdg-desktop-portal
        xdg-desktop-portal-hyprland

        pipewire
        wireplumber
      ]);

      envCore = pkgs.buildEnv {
        name = "ambxst-env-core";
        paths = baseEnv;
      };

      hyprFullDeps = with pkgs; [
        (wrapWithNixGL hyprland)
        uwsm
      ];

      envFull = pkgs.buildEnv {
        name = "ambxst-env-full";
        paths = baseEnv ++ hyprFullDeps;
      };

      # launcher
      launcher = pkgs.writeShellScriptBin "ambxst" ''
        exec ${lib.optionalString (!isNixOS) "${nixGL}/bin/nixGL "}${pkgs.quickshell}/bin/qs -p ${self}/shell.qml
      '';

      # Hyprland session scripts (nixGL removed automatically if NixOS)
      ambxrlandBin = pkgs.writeShellScriptBin "Ambxrland" ''
        exec ${lib.optionalString (!isNixOS) "${nixGL}/bin/nixGL "}${pkgs.hyprland}/bin/Hyprland -c ~/.config/hypr/hyprland.conf
      '';

      ambxrlandBinLower = pkgs.writeShellScriptBin "ambxrland" ''
        exec Ambxrland
      '';

      ambxrlandSession = pkgs.writeTextFile {
        name = "Ambxrland.desktop";
        destination = "/share/wayland-sessions/Ambxrland.desktop";
        text = ''
[Desktop Entry]
Name=Ambxrland
Comment=Ambxrland session (Hyprland)
Exec=Ambxrland
TryExec=Ambxrland
Type=Application
DesktopNames=Ambxrland
        '';
      };

      ambxrlandSessionUwsm = pkgs.writeTextFile {
        name = "Ambxrland-uwsm.desktop";
        destination = "/share/wayland-sessions/Ambxrland-uwsm.desktop";
        text = ''
[Desktop Entry]
Name=Ambxrland (uwsm)
Comment=Ambxrland with uwsm
Exec=uwsm start -- Ambxrland.desktop
TryExec=uwsm
Type=Application
DesktopNames=Ambxrland
        '';
      };

      core = pkgs.buildEnv {
        name = "ambxst-core";
        paths = [ envCore launcher ];
      };

      full = pkgs.buildEnv {
        name = "ambxst-full";
        paths = [
          envFull
          launcher
          ambxrlandBin
          ambxrlandBinLower
          ambxrlandSession
          ambxrlandSessionUwsm
        ];
      };
    in {
      default = full;
      ambxst-core = core;
      ambxst-full = full;
    });
  };
}
