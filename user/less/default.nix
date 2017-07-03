{ config, pkgs, lib, ... }:

lib.mkIf (pkgs.lib.shouldInclude ./. config) {
  home.profile.envVars = {
    LESS = "-FMRSX";
    LESSHISTFILE = "$HOME/${config.home.loghistDir}/less/history";
    LESSOPEN = "|${pkgs.lesspipe}/bin/lesspipe.sh %s";
  };
}
