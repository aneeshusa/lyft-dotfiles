{ config, pkgs, lib, env, ... }:

let

  cfg = config.home;

in

{
  imports = [
    ./profile.nix
  ];

  options = with lib; {
    home = {
      cacheDir = mkOption {
        type = types.str;
        default = "$HOME/.cache";
      };
      configDir = mkOption {
        type = types.str;
        default = ".config";
      };
      loghistDir = mkOption {
        type = types.str;
        default = "var/log";
      };


      configModules = mkOption {
        type = types.attrsOf types.bool;
        default = {};
      };

      file = mkOption {
        description = "Attribute set of files to link into the user home.";
        default = {};
        type = types.attrsOf (types.submodule ({ name, config, ... }: {
          options = {
            source = mkOption {
              type = types.path;
              description = "Path to the source file.";
            };
            text = mkOption {
              type = types.nullOr types.lines;
              default = null;
              description = "Text of the file.";
            };
          };
          config = {
            source = mkIf (config.text != null) (
              let name' = "home-file-" + builtins.baseNameOf name;
              in mkDefault (pkgs.writeText name' config.text)
            );
          };
        }));
      };

      packages = mkOption {
        type = types.attrsOf types.bool;
        default = {};
        description = "The set of packages to appear in the user environment.";
      };
    };

    home.build = mkOption {
      type = types.path;
      internal = true;
    };
  };

  config = {
    nixpkgs.overlays = [
      (import ./overlay.nix config)
    ];

    home.configModules = lib.mapAttrs (n: v: true) config.home.packages;

    home.packages = lib.flip lib.genAttrs (name: true) [
      "glibcLocales"
      "nix"
    ];

    home.profile.envVars = {
      LOCALE_ARCHIVE = "$HOME/.nix-profile/lib/locale/locale-archive";
      NIX_REMOTE = "daemon";
    };

    home.build = let
      profile = pkgs.buildEnv {
        name = "user-profile-${env}";
        extraOutputsToInstall = [ "doc" "man" ];
        paths = lib.concatMap (
          pkgName: lib.optional config.home.packages.${pkgName} pkgs.${pkgName}
        ) (builtins.attrNames config.home.packages);
      };

      configs = lib.mapAttrs (n: v: v.source) config.home.file;

      mkActivate = topDirEnvVar: pkgs.substituteAll {
        name = "activate-user-profile-${env}";
        src = ./bin/activate.py;
        isExecutable = true;

        inherit (pkgs) nix python3;
        inherit profile topDirEnvVar;
        configs = builtins.toJSON (
          lib.mapAttrs (n: v: v.source) config.home.file
        );
      };

      activate = mkActivate "HOME";

      builtConfigs = let
        buildTree = mkActivate "out";
      in derivation {
        name = "user-configs=${env}";
        builder = (mkActivate "out");
        system = builtins.currentSystem;
      };

    in (pkgs.runCommand "user-home-${env}" {} ''
      mkdir -p "$out"

      ln -s '${activate}' "$out/activate"
      ln -s '${profile}' "$out/profile"
      ln -s '${builtConfigs}' "$out/configs"
    '') // { inherit profile configs activate builtConfigs; };
  };
}
