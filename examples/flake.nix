{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    lutris-overlay = {
      url = "github:clemenscodes/lutris-overlay";
    };
  };
  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [inputs.lutris-overlay.overlays.lutris];
    };
  in {
    packages = {
      ${system} = {
        inherit (pkgs) lutris;
        default = pkgs.lutris;
      };
    };
    devShells = {
      ${system} = {
        default = pkgs.mkShell {
          PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION = "python";
          buildInputs = [pkgs.lutris];
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
