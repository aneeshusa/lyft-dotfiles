config: self: super: let
  pkgNames = builtins.attrNames config.home.packages;

  # TODO: support `cache`, currently omitted due to always being absolute
  dirNames = [ "config" "loghist" ];
  mkPatchName = dirName: "user_${dirName}_dir";
  mkDir = dirName: builtins.getAttr (dirName + "Dir") config.home;

  addOverrides = pkgName: let
    getLocalPatch = dirName:
      "${builtins.toPath ./.}/${pkgName}/${mkPatchName dirName}.patch"
    ;
    overrides = builtins.filter (
      dirName: builtins.pathExists (getLocalPatch dirName)
    ) dirNames;
  in super.lib.optional ((builtins.length overrides) > 0) {
    name = pkgName;
    value = let
      # Place a copy of the patch in the Nix store,
      # so that it can be accessed inside the Nix sandbox.
      mkStorePatch = dirName: let
        contents = builtins.readFile (getLocalPatch dirName);
      in self.writeText "${mkPatchName dirName}.patch" contents;

      mkFixupScript = dirName: let
        storePatch = mkStorePatch dirName;
      in ''
        for fileToPatch in $(${self.patchutils}/bin/lsdiff "${storePatch}"); do
          if [[ ! -e "$fileToPatch" ]]; then
            fileToPatch="''${fileToPatch:2}"  # Strip a/, b/ style prefixes
          fi
          substituteInPlace "$fileToPatch" \
            --subst-var-by ${mkPatchName dirName} '${mkDir dirName}/${pkgName}'
        done
      '';
    in super.${pkgName}.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or [])
        ++ (builtins.map mkStorePatch overrides)
      ;
      postPatch = (oldAttrs.postPatch or "") + (
        self.lib.concatStrings (builtins.map mkFixupScript overrides)
      );
    });
  };

# Note: all overrides are performed in a single overlay to ensure
# dependencies are properly progagated.
# If each package is overriden in a separate overlay,
# then there may be different results depnding on the ordering.
in builtins.listToAttrs (super.lib.concatMap addOverrides pkgNames) // {
  weechat = super.weechat.overrideAttrs (oldAttrs: rec {
    cmakeFlags = (oldAttrs.cmakeFlags or {}) // {
      WEECHAT_HOME = "~/${config.home.configDir}/weechat";
    };
  });
}
