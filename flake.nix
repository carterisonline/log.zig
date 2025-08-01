{
  description = "Simple logging library for Zig";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zls-overlay.url = "github:zigtools/zls";
    zls-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ];
      systems =
        [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        with pkgs; {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.zig-overlay.overlays.default ];
          };
          packages.default = stdenv.mkDerivation {
            name = "log";
            src = ./.;
            nativeBuildInputs =
              [ inputs.zig-overlay.packages.${system}.master ];
            buildPhase = ''
              zig build -Doptimize=ReleaseFast --global-cache-dir .zig-cache -p $out
            '';
          };
          devShells.default = mkShell {
            packages = [
              nil
              inputs.zig-overlay.packages.${system}.master
              (inputs.zls-overlay.packages.${system}.zls.overrideAttrs (old: {
                nativeBuildInputs =
                  [ inputs.zig-overlay.packages.${system}.master ];
              }))
            ];
          };
          formatter = nixfmt-rfc-style;
        };
    };
}
