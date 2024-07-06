{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    libpisp-src = {
      flake = false;
      url = "github:raspberrypi/libpisp/v1.0.6";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux"];
      perSystem = {
        config,
        pkgs,
        system,
        inputs',
        self',
        ...
      }: let 
      in {
        packages = rec {
          libpisp = pkgs.stdenv.mkDerivation {
            name = "libpisp";
            version = "1.0.6";
            src = inputs.libpisp-src;
            nativeBuildInputs = [pkgs.pkg-config pkgs.meson pkgs.ninja];
            buildInputs = [pkgs.nlohmann_json pkgs.boost];
            # Meson is no longer able to pick up Boost automatically.
            # https://github.com/NixOS/nixpkgs/issues/86131
            BOOST_INCLUDEDIR = "${pkgs.lib.getDev pkgs.boost}/include";
            BOOST_LIBRARYDIR = "${pkgs.lib.getLib pkgs.boost}/lib";
          };
          libcamera = pkgs.libcamera.overrideAttrs (old: {
            nativeBuildInputs = old.nativeBuildInputs ++ [pkgs.python3Packages.pybind11];
            buildInputs = old.buildInputs ++ [libpisp];
            postPatch = ''
              patchShebangs src/py/ utils/
            '';
            src = ./.;
          });
        };
      };
    };
}
