{ config, pkgs, lib, ... }:

let
  cfg = config.home.zsh;

  zshUsersPlugin = plugin: pkgs.stdenv.mkDerivation rec {
    inherit (plugin) name;
    src = pkgs.fetchFromGitHub {
      owner = "zsh-users";
      repo = plugin.name;
      inherit (plugin) rev sha512;
    };
    buildCommand = ''
      mkdir "$out"
      cp "$src/${name}.zsh" "$out/"
    '';
  };

  zshHistorySubstringSearch = zshUsersPlugin rec {
    name = "zsh-history-substring-search";
    rev = "60085528959341087b088970c8bea4b7870d6f5b";
    sha512 = "2imcmqwy1x734i357snps6vgrqqcswr2cnhg73gpxg4v4b96zyfcq1zi2vvsbsimwc92whb9529zvdknhr6nggz7nc51jrkm39hacqb";
  };

  zshSyntaxHighlighting = (zshUsersPlugin rec {
    name = "zsh-syntax-highlighting";
    rev = "d711563fe1bf8fa6810bc34ac92a2fd3150290ed";
    sha512 = "0qym57snnzyzml6pwxqrl9352zjkv0hg543c49pcasl8d0vv3nvqy4j8bgqzqxkx6cjj35vsx3ca1ar2ppipm5khr19lbq9ibf1x5hk";
  }).overrideAttrs (oldAttrs: {
    buildCommand = oldAttrs.buildCommand + ''
      cp -r "$src/highlighters" "$out/"
      patch --directory="$out" -p1 \
          <"${./zsh-syntax-highlighting-dont-check-version.patch}"
    '';
  });

  zaw = (zshUsersPlugin rec {
    name = "zaw";
    rev = "98c36822ccedbb588fa037cf0149c5e66aa6b797";
    sha512 = "32mmkj1mhjz9mp09kdb7pj2r1wmmk9v2ny32n1qm3y6i2zjxfxr933ngivbkfkl9gyh1mf3lwfy4x1vv5hwaz3hyb7qs5gyc1853v1p";
  }).overrideAttrs (oldAttrs: {
    buildCommand = (oldAttrs.buildCommand or "") + ''
      cp -r "$src/functions" "$out/"
      cp -r "$src/sources" "$out/"
    '';
  });

  zshNixCompletions = pkgs.stdenv.mkDerivation rec {
    name = "zshNixCompletions-${version}";
    version = "728d68fc6e33d3353c7e4bf8acb4027fdb450fc7";
    src = pkgs.fetchFromGitHub {
      owner = "olejorgenb";
      repo = "nix-zsh-completions";
      rev = version;
      sha512 = "31wbxchnd2mvhd62lmwxmf2cchqv02zxm2314g96k5mqvaw6lpjs58z0ca08aj7iw2irxjnh23vjhgz259y2zizysb9raghzpqchp0d";
    };
    outputs = [ "out" "doc" "license" ];
    buildCommand = ''
      mkdir "$out"
      cp "$src"/_* "$out"
      cp "$src/"*.zsh "$out"

      mkdir "$doc"
      cp "$src/"*.md "$doc"

      mkdir "$license"
      cp "$src/LICENSE" "$license"
    '';
  };

  serializeAliases = aliases: let
    serializeAlias = name: value: "alias ${name}='${value}'";
  in lib.concatStringsSep "\n" (lib.mapAttrsToList serializeAlias aliases);

  serializeFunctions = funcs: let
    serializeFunction = name: value: ''
      ${name}() {
      ${pkgs.lib.indentBy 4 (lib.removeSuffix "\n" value)}
      }
    '';
  in lib.concatStringsSep "\n" (lib.mapAttrsToList serializeFunction funcs);

  serializeOptions = options: let
    serializeOption = option: "setopt ${option}";
  in lib.concatStringsSep "\n" (builtins.map serializeOption options);

  zshOptions = [
    "APPEND_HISTORY"
    "NOMATCH"
    "NOBEEP"
    "AUTO_PUSHD"
  ];

in {
  options = with lib; {
    home.zsh = {
      aliases = mkOption {
        type = types.attrsOf types.str;
        default = {};
      };
      config = mkOption {
        type = types.lines;
        default = "";
      };
      functions = mkOption {
        type = types.attrsOf types.str;
        default = {};
      };
    };
  };
  config = lib.mkIf (pkgs.lib.shouldInclude ./. config) {
    home.zsh.aliases = rec {
      path = ''echo "$PATH" | sed "s/:/\n/g"'';
      p = path;
      wh = "command -v";

      grep = "${pkgs.gnugrep}/bin/grep --color=auto";
      ls = "${pkgs.coreutils}/bin/ls --classify --color=auto";

      cp = "${pkgs.coreutils}/bin/cp --interactive";
      mv = "${pkgs.coreutils}/bin/mv --interactive";
      # No need for `--interactive` because zsh will prompt before deletion
      rm = "${pkgs.coreutils}/bin/rm --dir";

      rawdd = "${pkgs.coreutils}/bin/dd";
      dd = "${pkgs.dcfldd}/bin/dcfldd";
      free = "${pkgs.procps}/bin/free --human";

      show = "${pkgs.coreutils}/bin/cat --show-nonprinting"; # For security
      s = show;

      mirror = ''
        ${pkgs.wget}/bin/wget \
            --mirror \
            --convert-links \
            --backup-converted \
            --execute robots=off \
            --continue"
      '';

      unixtime = "${pkgs.coreutils}/bin/date +%s";
      epoch = unixtime;
      utc = "${pkgs.coreutils}/bin/date --iso-8601=seconds --utc";
      utcdate = utc;
      utctime = utc;

      strings = "${pkgs.binutils}/bin/strings -a";

      ips = "${pkgs.iproute}/bin/ip -br -c a";
      whois = "${pkgs.whois}/bin/whois -H domain";
    };
    home.zsh.functions = {
      man = ''
          LESS_TERMCAP_md=$'\e[1;36m' \
          LESS_TERMCAP_me=$'\e[0m' \
          LESS_TERMCAP_se=$'\e[0m' \
          LESS_TERMCAP_so=$'\e[1;40;92m' \
          LESS_TERMCAP_ue=$'\e[0m' \
          LESS_TERMCAP_us=$'\e[1;32m' \
          command man "$@"
      '';
      strlen = ''
          FOO=$1
          local zero='%([BSUbfksu]|([FB]|){*})'
          LEN="''${#''${(S%%)FOO//$~zero/}}"
          echo "$LEN"
      '';
      # show right prompt with date ONLY when command is executed
      preexec = ''
          DATE=$( date +"[%H:%M:%S]" )
          local len_right=$( strlen "$DATE" )
          len_right=$(( $len_right+1 ))
          local right_start=$(($COLUMNS - $len_right))
          local len_cmd=$( strlen "$@" )
          local len_prompt=$(strlen "$PROMPT" )
          local len_left=$(($len_cmd+$len_prompt))
          RDATE="\033[$right_startC $DATE"
          if [ $len_left -lt $right_start ]; then
              # command does not overwrite right prompt
              # ok to move up one line
              echo -e "\033[1A$RDATE"
          else
              echo -e "$RDATE"
          fi
      '';
      up = ''
          local val
          if [[ 0 -eq "$#" ]]; then
              val=1
          else
              val="$1"
          fi
          if [[ "$val" -le 0 ]]; then return; fi
          cd ..
          up $((val - 1))
      '';
    };

    home.file.".config/zsh".source = pkgs.stdenv.mkDerivation {
      name = "zdotdir";
      zshrcPre = ./zshrc-pre;
      zshrcPost = ./zshrc-post;
      zshenv = ''
        source ~/.profile
        setopt NO_GLOBAL_RCS
        ZDOTDIR=~/.config/zsh
      '';

      passAsFile = [ "zshFunctions" ];
      zshFunctions = serializeFunctions cfg.functions;
      zshAliases = serializeAliases cfg.aliases;
      zshConfig = cfg.config;
      zshOptions = serializeOptions zshOptions;
      inherit (config.home) cacheDir loghistDir;
      inherit
        zshNixCompletions
        zshHistorySubstringSearch
        zshSyntaxHighlighting
        zaw;
      buildCommand = ''
        printf '%s\n' "$zshenv" > "./zshenv"
        cat -- "$zshrcPre" "$zshFunctionsPath" "$zshrcPost" >./.zshrc
        substituteInPlace "./.zshrc" \
            --subst-var cacheDir \
            --subst-var loghistDir \
            --subst-var zshAliases \
            --subst-var zshConfig \
            --subst-var zshOptions \
            --subst-var zshNixCompletions \
            --subst-var zshHistorySubstringSearch \
            --subst-var zshSyntaxHighlighting \
            --subst-var zaw

        mkdir -p "$out"
        for zshDotfile in "zshenv" ".zshrc"; do
            #${pkgs.zsh}/bin/zsh -c "zcompile ./$zshDotfile"
            #cp "./$zshDotfile.zwc" "$out/"
            cp "./$zshDotfile" "$out/"
        done
      '';
    };
  };
}
