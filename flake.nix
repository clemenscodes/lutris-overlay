{
  nixConfig = {
    extra-substituters = ["https://nix-gaming.cachix.org"];
    extra-trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
  };
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    wine-overlays = {
      url = "github:clemenscodes/wine-overlays";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
  };
  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    overlays = import ./overlays {inherit self system;};
    unwrapped-lutris = pkgs.lutris.override {
      extraPkgs = pkgs: [
        pkgs.winetricks
        pkgs.gamescope
        pkgs.mangohud
        pkgs.wget
        pkgs.curl
        pkgs.zenity
        pkgs.samba
        pkgs.jansson
        pkgs.gnutls
        pkgs.python3
        pkgs.python313Packages.protobuf
        pkgs.protobuf
        pkgs.libsForQt5.kdialog
        pkgs.mesa
        pkgs.driversi686Linux.mesa
        inputs.wine-overlays.packages.${system}.wine-wow64-staging-10_4
        inputs.wine-overlays.packages.${system}.wine-wow64-staging-winetricks-10_4
      ];
      extraLibraries = pkgs: [
        pkgs.samba
        pkgs.jansson
        pkgs.gnutls
        pkgs.python3
        pkgs.python313Packages.protobuf
        pkgs.protobuf
        pkgs.mesa
        pkgs.driversi686Linux.mesa
        pkgs.dxvk
        pkgs.vkd3d
        pkgs.vkd3d-proton
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
          buildInputs = [self.packages.${system}.lutris];
          shellHook = ''
            echo "Lutris configured..."
            echo "Run lutris -d to see debug output"
          '';
        };
      };
    };
  };
}
