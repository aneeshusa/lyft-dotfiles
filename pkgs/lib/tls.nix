{
  versions ? [ "VERS-TLS1.2" ],
  ciphers ? [ "AES-128-GCM" "AES-256-CBC" "AES-128-CBC" ], # TODO GCM only
  kexs ? [ "ECDHE-RSA" "DHE-RSA" ], # TODO remove DHE-RSA
  macs ? [ "AEAD" "SHA384" "SHA256" ],
  signatures ? [ "SIGN-RSA-SHA512" "SIGN-RSA-SHA384" "SIGN-RSA-SHA256" ],
  curves ? [ "CURVE-ALL" ], # TODO restrict
  # TODO certificate types?
  compressions ? [ "COMP-NULL" ],

  backend,
}:

{
  "gnutls" = "NONE" + builtins.concatStringsSep "" (builtins.map (s: ":+" + s)
    ([]
     ++ versions
     ++ ciphers
     ++ kexs
     ++ macs
     ++ signatures
     ++ curves
     ++ compressions
    )
  );
}.${backend}
