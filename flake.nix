{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    umu = {
      url = "github:Open-Wine-Components/umu-launcher?dir=packaging/nix";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
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
    pkgs = import nixpkgs {inherit system;};
    overlays = import ./overlays {inherit self system;};
    umu = inputs.umu.packages.${system}.default.override {
      extraPkgs = pkgs: [];
      extraLibraries = pkgs: [];
      withMultiArch = true;
      withTruststore = true;
      withDeltaUpdates = true;
    };
    lutris = pkgs.lutris.override {
      extraPkgs = pkgs: [
        inputs.wine-overlays.packages.${system}.wine-wow64-staging-10_4
        inputs.wine-overlays.packages.${system}.wine-wow64-staging-winetricks-10_4
        pkgs.winetricks
        pkgs.gamescope
        pkgs.mangohud
        pkgs.wget
        pkgs.curl
        pkgs.zenity
        pkgs.libsForQt5.kdialog
        pkgs.vulkan-tools
        umu
      ];
      extraLibraries = pkgs: [
        pkgs.samba
        pkgs.jansson
        pkgs.gnutls
        pkgs.python3
        pkgs.python313Packages.protobuf
        pkgs.protobuf
      ];
      steamSupport = false;
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
          PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION = "python";
          buildInputs = [self.packages.${system}.lutris];
          shellHook = ''
            echo "Lutris configured..."
            echo "Run lutris -d to see debug output"
            echo "Set PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python in Lutris environment to activate Battle.net source"
          '';
        };
      };
    };
  };
}
