# Main Ambxst package
{
  pkgs,
  lib,
  self,
  system,
  quickshell,
  ambxstLib,
}:

let
  quickshellPkg = quickshell.packages.${system}.default;

  # Import sub-packages
  ttf-phosphor-icons = import ./phosphor-icons.nix { inherit pkgs; };

  # Import modular package lists
  corePkgs = import ./core.nix { inherit pkgs quickshellPkg; };
  toolsPkgs = import ./tools.nix { inherit pkgs; };
  mediaPkgs = import ./media.nix { inherit pkgs; };
  appsPkgs = import ./apps.nix { inherit pkgs; };
  fontsPkgs = import ./fonts.nix { inherit pkgs ttf-phosphor-icons; };
  tesseractPkgs = import ./tesseract.nix { inherit pkgs; };

  # Combine all packages (NixOS-specific deps handled by the module)
  baseEnv = corePkgs ++ toolsPkgs ++ mediaPkgs ++ appsPkgs ++ fontsPkgs ++ tesseractPkgs;

  envAmbxst = pkgs.buildEnv {
    name = "Ambxst-env";
    paths = baseEnv;
  };

  # Create fontconfig configuration to find bundled fonts
  fontconfigConf = pkgs.makeFontsConf {
    fontDirectories = fontsPkgs;
  };
in
pkgs.stdenv.mkDerivation {
  pname = "Ambxst";
  version = lib.removeSuffix "\n" (builtins.readFile ../../version);
  src = lib.cleanSource self;
  dontBuild = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];
  propagateBuildInputs = [ envAmbxst ];

  installPhase = ''
    mkdir -p $out/share/ambxst-shell
    mkdir -p $out/bin
    cp -r . $out/share/ambxst-shell

    makeWrapper $out/share/ambxst-shell/cli.sh $out/bin/ambxst \
        --prefix QML2_IMPORT_PATH : "${envAmbxst}/lib/qt-6/qml" \
        --prefix PATH : "${envAmbxst}/bin" \
        --set FONTCONFIG_FILE "${fontconfigConf}" \
        --set AMBXST_QS "${quickshellPkg}/bin/qs"
  '';

  meta.mainProgram = "ambxst";
}
