{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    wine-overlays = {
      url = "github:clemenscodes/wine-overlays";
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
      overlays = [
        (final: prev: let
          inherit (inputs.wine-overlays.packages.${system}) wine-11_4 winetricks-compat-11_4;
        in {
          wine = wine-11_4;
          winetricks-compat = winetricks-compat-11_4;
        })
      ];
    };
    overlays = import ./overlays {inherit self system;};
    unwrapped-lutris =
      (pkgs.lutris.override {
        lutris-unwrapped = pkgs.lutris-unwrapped.overrideAttrs (_: rec {
          version = "0.5.22";
          src = pkgs.fetchFromGitHub {
            owner = "lutris";
            repo = "lutris";
            tag = "v${version}";
            hash = "sha256-4mNknvfJQJEPZjQoNdKLQcW4CI93D6BUDPj8LtD940A=";
          };
        });
      }).override {
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
          pkgs.vulkan-tools
          pkgs.wine
          pkgs.winetricks-compat
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
        steamSupport = true;
      };
    lutris = pkgs.symlinkJoin {
      name = "lutris";
      paths = [unwrapped-lutris];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/lutris \
          --set PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION "python"
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
            pkgs.wine
            pkgs.winetricks-compat
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
