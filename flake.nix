{
  description = "Simple logging library for Zig";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: with pkgs; {
        packages.default = stdenv.mkDerivation {
          name = "log";
          src = ./.;
          nativeBuildInputs = [ zig ];
          buildPhase = ''
            zig build -Doptimize=ReleaseFast --global-cache-dir .zig-cache -p $out
          '';
        };
        devShells.default = mkShell {
          packages = [
            nil
            zig
            zls
          ];
        };
        formatter = nixfmt-rfc-style;
      };
    };
}
