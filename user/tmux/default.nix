{ config, pkgs, lib, ... }:

let

  scrollCopyPlugin = pkgs.stdenv.mkDerivation rec {
    name = "tmux-scroll-copy-mode-${version}";
    version = "5e4c864d2f96be01000f692fe0f04cf50128a8df";
    src = pkgs.fetchFromGitHub {
      owner = "NHDaly";
      repo = "tmux-scroll-copy-mode";
      rev = version;
      sha512 = "3d3qmnd9dichl6ryjzb9i96fdbhn6nxggicwcpvd3973q64h6y6hwgy88jgxcbjmv87yc9153mlvyps8841i87m5yc2vdnb9mgj0gh0";
    };
    buildCommand = ''
      mkdir "$out"
      cp "$src/scroll_copy_mode.tmux" "$out/scroll_copy_mode.tmux"
      cp --recursive "$src/scripts" "$out/scripts"
    '';
  };

in lib.mkIf (pkgs.lib.shouldInclude ./. config) {
  home.profile.envVars = {
    TMUX_TMPDIR = "$XDG_RUNTIME_DIR"; # tmux creates its own subdirectory
  };
  home.zsh.config = ''
      if [[ -v TMUX ]]; then
          export TERM=screen-256color
      else
          export TERM=xterm-256color
      fi
  '';
  home.file.".config/tmux/tmux.conf".text = ''
    set-window-option -g mode-keys vi
    set -s escape-time 0

    set -g status-bg colour32
    set -g pane-active-border-fg colour32

    set -g mouse on
    set -g @scroll-without-changing-pane "on"
    set -g @emulate-scroll-for-no-mouse-alternate-buffer "on"
    run-shell ${scrollCopyPlugin}/scroll_copy_mode.tmux

    bind-key r source-file ~/.config/tmux/tmux.conf

    set-window-option -g window-status-current-bg magenta

    set -g history-limit 10000

    setw -g monitor-activity on

    set-option -ga terminal-overrides ",xterm-256color:Tc"
  '';
}
