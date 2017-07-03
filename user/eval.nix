pin: env:

let

  # TODO: Inject custom lib functions (from ../pkgs/lib) w/o infinite recursion
  lib = import (pin + "/lib");

  dotfilesDir = "${builtins.toPath ./.}";
  userModules = let
    entries = builtins.attrNames (builtins.readDir dotfilesDir);
    candidates = builtins.map (d: "${dotfilesDir}/${d}/default.nix") entries;
  in builtins.filter builtins.pathExists candidates;

  pkgsModule = { config, ... }: {
    options = with lib; {
      nixpkgs.overlays = mkOption {
        default = [];
        type = types.listOf (mkOptionType {
          name = "nixpkgs-overlay";
          check = builtins.isFunction;
          merge = lib.mergeOneOption;
        });
      };
    };
    config = {
      _module.args = {
        inherit env;
        pkgs = lib.mkForce (import pin {
          overlays = [
            (import ../pkgs/overlay.nix { isServer = false; })
          ] ++ config.nixpkgs.overlays;
        });
      };
    };
  };

in rec {
  inherit (lib.evalModules {
    modules = [
      pkgsModule
      ./home.nix
      (./envs + "/${env}.nix")
    ] ++ userModules;
  }) config options;

  inherit (config._module.args) pkgs;
}
