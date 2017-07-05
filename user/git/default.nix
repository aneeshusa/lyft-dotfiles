{ config, pkgs, lib, ... }:

let

  serializePrefValue = value:
    if builtins.isString value then ''"${value}"''
    else if builtins.isBool value then (if value then "true" else "false")
    else throw "git preference value of unknown type";

  serializePref = name: value: ''
    ''\t${name} = ${serializePrefValue value}
  '';

  serializePrefSet = prefset: lib.concatStrings (
    lib.mapAttrsToList serializePref prefset
  );

  serializeSection = sectionName: prefSet: ''
    [${sectionName}]
    ${serializePrefSet prefSet}
  '';

  serializeConfig = config: lib.concatStrings (
    lib.mapAttrsToList serializeSection config
  );

  aliases = {
    a = "add";
    ap = "add --patch";

    c = "commit --verbose";
    ca = "commit --verbose --amend";
    cra = "commit --verbose --amend --reset-author";

    cb = "rev-parse --abbrev-ref HEAD";

    co = "checkout";
    cob = "checkout -b";

    d = "diff";
    dc = "diff --cached";

    g = "pull --ff-only";

    s = "status -sb";

    al = "!${pkgs.git}/bin/git config --get-regexp ^alias\\\\. | sed 's/ /\\t\\t/1;s/^alias\\\\./g[it ]/1'";

    lol = "log --graph --show-signature";
    lola = "log --graph --show-signature --all --decorate --oneline";
    l = "log --graph --show-signature";
  };

in lib.mkIf (pkgs.lib.shouldInclude ./. config) {
  home.file.".config/git/git/config".text = serializeConfig {
    alias = aliases;
    branch.autoSetupRebase = "always";
    commit.verbose = true;
    diff = {
      compactionHeuristic = true;
      mnemonicprefix = true; # TODO: try noprefix = true
      renames = "copies";
    };
    fetch.fsckobjects = true;
    #format.pretty = "tformat:%C(yellow)%h%Creset %Cgreen%ar%Creset %C(auto)%d %s";
    grep = {
      lineNumber = true;
      fallbackToNoIndex = true;
    };
    log = {
      decorate = true;
      follow = true;
    };
    merge = {
      conflictStyle = "diff3";
      ff = false;
    };
    pull.rebase = true;
    push.default = "simple";
    rebase = {
      autosquash = true;
      missingCommitsCheck = "warn";
    };
    receive.fsckObjects = true;
    remote.pushDefault = "origin";
    rerere.enabled = true;
    transfer.fsckobjects = true;
    user.useConfigOnly = true;
  };

  home.file."bin/git-brs".source = pkgs.writeScript "git-brs" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    for branch in $(git branch --sort -authordate | grep -v 'HEAD detached at ' | cut -c 3-); do
        printf "%s\\t%s\n" \
            "$(git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" "$branch" |\
               head -n 1)" \
            "$branch"
    done
  '';

  home.file."bin/git-up".source = pkgs.writeScript "git-up" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    if [[ $(git config "branch.$(git rev-parse --abbrev-ref HEAD).merge") = "" ]]; then
        exec 3>&1
        git push -u "$@" 2>&1 1>&3 3>&- | sed 's/git push --set-upstream/git up/' >&2 3>&-
        exec 3>&-
    else
        git push "$@"
    fi
  '';

  home.zsh.aliases = let
    mkGitAlias = alias: _: { name = "g${alias}"; value = "${pkgs.git}/bin/git ${alias}"; };
  in builtins.removeAttrs (lib.mapAttrs' mkGitAlias aliases) [
    "gs"  # Conflicts with ghostscript
  ] // {
    g = "${pkgs.git}/bin/git s";
  } // lib.mapAttrs' (name: mkGitAlias (lib.removePrefix "bin/git-" name)) (
    lib.filterAttrs (name: _: lib.hasPrefix "bin/git-" name) config.home.file
  );

  home.zsh.functions = {
    pullify = ''
        if [[ "$#" != 1 ]]; then
            printf >&2 'usage: %s <remote>\n' "$0"
            return 1
        fi
        local remote="$1"
        local found='false'
        git remote | while read existing_remote; do
            if [[ "$existing_remote" == "$remote" ]]; then
                git config --local \
                    "remote.$remote.fetch" \
                    '+refs/pull/*:refs/remotes/'"$remote"'/pr/*'
                found='true'
                break;
            fi
        done
        if [[ "$found" != 'true' ]]; then
            printf >&2 '%s: Could not find remote %s.\n' "$0" "$remote"
            return 1
        fi
    '';
  };
}
