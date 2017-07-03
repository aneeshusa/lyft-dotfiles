{ config, pkgs, lib, ... }:

let

  vimFolders = lib.tabJoin [
    "autoload"
    "common"
    "compiler"
    "doc"
    "ftdetect"
    "ftplugin"
    "indent"
    "plugin"
    "syntax"
    "syntax_checkers"
  ];

  initVim = pkgs.stdenv.mkDerivation {
    name = "init.vim";
    src = ./init.vim;
    buildCommand = ''
      substitute "$src" "$out" \
          --subst-var-by netcat "${pkgs.netcat}/bin/nc"
    '';
  };

  plugins = map pkgs.fetchFromGitHub [
    {
      owner = "LnL7";
      repo = "vim-nix";
      rev = "f0b7bd4bce5ed0f12fb4d26115c84fb3edcd1e12";
      sha512 = "1jwai0iw3j8ykh7jv8f30xasfbildkzqv40im7kbfqn697q8sc85i6502rlrsr34lz6ixjiicp3cnj0zfal04l7x117cvpngsr32ifx";
    }
    {
      owner = "hashivim";
      repo = "vim-vagrant";
      rev = "ce407ebdc8fcdce4ee3a5f947b29c1e3c4cd2a38";
      sha512 = "07yidkqnz4yx0rqj2j73lb5i71cghfccnpwc9gnl354fn00f7x35dyydwj5v0shif31b5dmjlvkxm4gpqwisqxjx007d7fc94434brw";
    }
    {
      owner = "jreybert";
      repo = "vimagit";
      rev = "86863ca3acf04f58bf6ef634ffd5374081d6d64d";
      sha512 = "1x8bk96j2sg3qcy4kyrp1v3zjhf19z1zz56b184ycmxwmr7f61gyjj3dzixpaizssj990m0cllc79pl412sa55my8iqbsm4hgq00h0j";
    }
    {
      owner = "peter-edge";
      repo = "vim-capnp";
      rev = "b508f90d9b4b91e91a1a2bc16ffc644a1e92da98";
      sha512 = "3bw7l91lpzjrl3jgcrw834am14ic3gw7ivk2xxjjz4zv5fp0030z0wmlkd1s1avsmkilrb05lyv8x4a3k07wy6m9b59bxf85lxqc4yv";
    }
    {
      owner = "tpope";
      repo = "vim-fugitive";
      rev = "bdd216827ae53cdf70d933bb30762da9bf42cad4";
      sha512 = "3m1590z139pxhcn0v2533wczkcqjapl0fb1wzgbijjay4n646s4b5j30h0x205w5y533fqxv5fk4j1i7li2llvqc5x3h9ssgr2bjwdy";
    }
    {
      owner = "rust-lang";
      repo = "rust.vim";
      rev = "115d321d383eb96d438466c56cc871fcc1bd0faa";
      sha512 = "2nya3n751wymzhbvsb8vzi100cb8x5mq6nca3yf8lx2v5k1svfxdgffac7jsq9iniwc7p82n2gmyaryg5rs2rfcas8qpjqgkay9p6wy";
    }
    {
      owner = "saltstack";
      repo = "salt-vim";
      rev = "5b15d379fbcbb84f82c6a345abc08cea9d374be9";
      sha512 = "0jfr9s8sqqcgdpzpinskddsdda6yxxm9j335bbc6ljhhhgh9g70rwln8f4fb3wi32wwq89mln2pdm630lmw11a7q6sk09jgkhq3r3yj";
    }
    {
      owner = "jakwings";
      repo = "vim-pony";
      rev = "0d9d4c88f4af4f481b55785ba74fe14bf17c7b61";
      sha512 = "0xzy51s6yyj7i2n7xb2x2mbdb9br9cvha9m9zy3vkb02cz48qlk6047y6mkrg2nsqz4m7adlpm24axsg8h8i3xwy5qlml9i4pby13wz";
    }
    {
      owner = "henrik";
      repo = "vim-indexed-search";
      rev = "1944bbcaf62a2423a587966bb090fb5989fbacb3";
      sha512 = "2kvllryf7vhkq7fl450xz6r2bjhxpgq0b47yjdpiq6bv4qqylmh2ndjbd2lna3w1fv4xikhv8r5ig231lggimncj9q71gv0an6pfnh6";
    }
    {
      owner = "monte-language";
      repo = "monte-vim";
      rev = "75c69efaf61dad51f75f350c2fed014ce87485b0";
      sha512 = "19v0fpwq7d2xip5ks1vhfikaryylbvafkvp6835fgn2lm2qrbmsfks1si3rdkpwl3nsqbb8gwfpg2clv1zwynyw3y61sd46dmfknq80";
    }
    {
      owner = "scrooloose";
      repo = "syntastic";
      rev = "247bf25d8009e84fff4c330d5954073e80310b15";
      sha512 = "157b7zp0yqqnyx6m3iadi9bvbbkf0akf52xz6rjad8s9rw3908vgn0s4696ywwqlh1byqwk69srmb11q9r1hc6ims8skzgz7bq4wlg0";
    }
    {
      owner = "leafgarland";
      repo = "typescript-vim";
      rev = "7e25a901af7cd993498cc9ecfc833ca2ac21db7a";
      sha512 = "0nwh34v6zjncb6i8macmsbnlrqpqxxqbbp7shjq0aaamjxj51dcsbh9wh48zq4n2gk2amkfpwyb1zw6k7cjjffsiy4y053hky0gdcsl";
    }
  ];

in lib.mkIf (pkgs.lib.shouldInclude ./. config) {
  home.profile.envVars = {
    VISUAL = "nvim";
  };
  home.zsh.aliases = let
    todoFile = "$HOME/doings";
  in rec {
    edit = "${pkgs.neovim}/bin/nvim";
    e = edit;
    edo = "${edit} ${todoFile}";
    view = "${edit} -R -M";
    v = view;
    vdo = "${view} ${todoFile}";
  };

  home.file.".config/nvim".source = pkgs.runCommand "neovim-config" { inherit plugins vimFolders; } ''
    IFS="$(printf "\t")" read -a VIM_FOLDERS <<< "$vimFolders"

    mkdir "$out"
    for folder in "''${VIM_FOLDERS[@]}"; do
      mkdir "$out/$folder"
    done
    cp ${initVim} "$out/init.vim"

    for plugin in $plugins; do
      for folder in "''${VIM_FOLDERS[@]}"; do
        if [[ -d "$plugin/$folder" ]]; then
          cp -r "$plugin/$folder"/* "$out/$folder/"
        fi
      done
   done

   ${pkgs.neovim}/bin/nvim --headless -i NONE -u NONE \
       --cmd ":helptags $out/doc" --cmd ":q"
  '';
}
