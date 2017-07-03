{ config, pkgs, lib, ... }:

{
  home.packages = lib.flip lib.genAttrs (name: true) [
    "checkbashisms"
    "cowsay"
    "file"
    "htop"
    "httpie"
    "icdiff"
    "less"
    "lsof"
    "neovim"
    "nix-repl"
    "strace"
    "tmux"
    "tree"
    "zsh"
  ];
}
