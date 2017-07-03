lib:

with lib;

recursiveUpdate lib (rec {
  mkTls = import ./tls.nix;

  # DERIVATIONS
  blacklistPatches = blacklisted: original: let
    filtered = builtins.filter (
      patch: !(builtins.any (bad: baseNameOf patch == bad) blacklisted)
    ) original;
  in if original != filtered
    then filtered
    else let formatted = builtins.toJSON blacklisted; in builtins.trace
      "warning: nothing filtered by blacklistPatches ${formatted}" filtered;


  # LISTS
  first = builtins.head;
  # last is already defined in nixpkgs

  # STRINGS
  lines = s: builtins.map (removeSuffix "\n") (splitString "\n" s);
  words = s: splitString " " s;
  indentBy = n: s: builtins.concatStringsSep "\n" (
    builtins.map (addPrefix (lib.fixedWidthString n " " "")) (lines s)
  );

  escapeShell = arg: builtins.replaceStrings ["'"] ["'\\''"] arg;

  # To go along with {has,remove}{Prefix,Suffix}
  addPrefix = prefix: s: prefix + s;
  addSuffix = suffix: s: s + suffix;

  # NIXOS
  mountPointFor = label: fss: let
    mps = builtins.attrNames (lib.filterAttrs (_: f: f.label == label) fss);
  in (assert builtins.length mps == 1; builtins.elemAt mps 0);

  # MODULES
  shouldInclude = dir: cfg: let
    dirname = builtins.baseNameOf (builtins.toString dir);
  in cfg.home.configModules."${dirname}" or false;
})
