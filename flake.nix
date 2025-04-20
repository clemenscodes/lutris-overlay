{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
  };
  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    inherit (pkgs) lib;
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [
            "steam"
            "steam-original"
            "steam-run"
            "steam-unwrapped"
          ];
      };
    };
    overlays = import ./overlays {inherit self system;};
    unwrapped-lutris = pkgs.lutris.override {
      extraPkgs = pkgs: [
        pkgs.winetricks
        pkgs.gamescope
        pkgs.mangohud
        pkgs.gamemode
        pkgs.wget
        pkgs.curl
        pkgs.zenity
        pkgs.samba
        pkgs.jansson
        pkgs.gnutls
        pkgs.python3
        pkgs.python313Packages.protobuf
        pkgs.protobuf
        pkgs.mesa
        pkgs.driversi686Linux.mesa
        pkgs.wineWow64Packages.stagingFull
        (
          pkgs.stdenv.mkDerivation {
            name = "winetricks-fix";
            phases = "installPhase";
            installPhase = ''
              mkdir -p $out/bin
              ln -s ${pkgs.wineWow64Packages.stagingFull}/bin/wine $out/bin/wine64
            '';
          }
        )
      ];
      extraLibraries = pkgs: [
        pkgs.samba
        pkgs.jansson
        pkgs.gnutls
        pkgs.libadwaita
        pkgs.gtk4
        pkgs.python3
        pkgs.python313Packages.protobuf
        pkgs.protobuf
        pkgs.mesa
        pkgs.driversi686Linux.mesa
      ];
      steamSupport = false;
    };
    wrapped-lutris = pkgs.writeShellApplication {
      name = "wrapped-lutris";
      runtimeInputs = [unwrapped-lutris];
      text = ''
        export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION="python"
        exec lutris "$@"
      '';
    };
    lutris = pkgs.stdenv.mkDerivation {
      name = "lutris";
      phases = "installPhase";
      installPhase = ''
        mkdir -p $out/{bin,share}
        ln -s ${unwrapped-lutris}/share/* $out/share
        ln -s ${wrapped-lutris}/bin/wrapped-lutris $out/bin/lutris
      '';
    };
  in {
    inherit overlays;
    packages = {
      ${system} = {
        inherit lutris;
        default = self.packages.${system}.lutris;
      };
    };
    devShells = {
      ${system} = {
        default = pkgs.mkShell {
          buildInputs = [
            self.packages.${system}.lutris
            pkgs.wineWow64Packages.stagingFull
            (
              pkgs.stdenv.mkDerivation {
                name = "winetricks-fix";
                phases = "installPhase";
                installPhase = ''
                  mkdir -p $out/bin
                  ln -s ${pkgs.wineWow64Packages.stagingFull}/bin/wine $out/bin/wine64
                '';
              }
            )
          ];
          shellHook = ''
            echo "Lutris configured..."
            echo "Run lutris -d to see debug output"
          '';
        };
      };
    };
  };
}
