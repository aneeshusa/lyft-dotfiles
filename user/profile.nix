{ config, pkgs, lib, ... }:

let
  cfg = config.home.profile;

  serializeEnvVars = envVars: let
    serializeEnvVar = name: value:
      pkgs.lib.escapeShell (
        if value == null
        then ''unset ${name}''
        else ''export ${name}="${value}"''
      );
  in builtins.concatStringsSep "\n"
    (lib.mapAttrsToList serializeEnvVar envVars);

in {
  options = with lib; {
    home.profile = {
      envVars = mkOption {
        type = types.attrsOf (types.nullOr types.str);
        default = {};
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
      };
    };
  };
  config = {
    home.profile.envVars = {
      PATH = "$HOME/.nix-profile/bin:$PATH";
      XDG_CACHE_HOME = config.home.cacheDir;
    };

    home.file.".profile".source = pkgs.stdenv.mkDerivation {
      name = "profile";
      src = ./profile;
      envVars = serializeEnvVars cfg.envVars;
      inherit (cfg) extraConfig;
      buildCommand = ''
        substitute "$src" "$out" \
          --subst-var envVars \
          --subst-var extraConfig
      '';
    };
  };
}
