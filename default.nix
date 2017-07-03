let

  ipfsHash = "QmWBryuPrfWbPK5arJNMtYsWTv81NhhvWz57zQu3TFr9r5";
  # TODO: Switch to fetchIPFS when available to default to localhost
  ipfsPin = builtins.fetchTarball {
    name = "nixpkgs";
    url = "https://gateway.ipfs.io/ipfs/${ipfsHash}";
  };

  # No way to check if <nixpkgs> exists, so check for $NIX_PATH instead
  # to allow local development
  pin = if (builtins.getEnv "NIX_PATH" != "") then <nixpkgs> else ipfsPin;
  nixosPin = pin + "/nixos";

in

  rec {
    user = let
      var = builtins.getEnv "NIX_ENV";
      env = if var != "" then var else "basic";
    in import ./user/eval.nix pin env;
  }
