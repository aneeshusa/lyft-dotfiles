options: self: super: {
  lib = import ./lib super.lib;

  diffoscope = super.diffoscope.override {
    poppler_utils = null; # Don't pull in all of X, no need to compare PDFs
    vim = null; # Fall back to Python hexlify instead of xxd
  };

  git = super.git.override {
    guiSupport = false;
    pythonSupport = false;
    sendEmailSupport = false;
  };

  # en_US.UTF-8/UTF-8 is the default, don't need the others
  glibcLocales = super.glibcLocales.override { allLocales = false; };

  gnupg = (super.gnupg.override {
      guiSupport = false;
      libusb = null;
      openldap = null;
      pcsclite = null;
      readline = self.readline;
  }).overrideAttrs(oldAttrs: {
    postPatch = ""; # I'm not using pcsclite
    postInstall = (oldAttrs.postInstall or "") + ''
      ln -s "$out/bin/gpg2" "$out/bin/gpg"
    '';
  });

  go_1_8 = super.go_1_8.override { subversion = null; };
  go = self.go_1_8;

  grub2 = super.grub2.override {
    zfsSupport = false;
  };

  janus-gateway = super.janus-gateway.override {
    openssl = self.openssl_1_0_2;
  };

  krb5Full = super.krb5Full.override {
    openldap = null;
    openssl = self.openssl_1_1_0;
  };

  less = super.less.override {
    lessSecure = true;
  };

  libarchive = (super.libarchive.override {
    openssl = null;
    xarSupport = false;
  }).overrideAttrs (oldAttrs: {
    configureFlags = (oldAttrs.configureFlags or []) ++ [
      "--without-openssl"
    ];
    preFixup = ''
      sed -i "$lib/lib/libarchive.la" \
        -e 's|-llzo2|-L${self.lzo}/lib -llzo|'
    '';
  });

  libkrb5 = self.krb5Full.override {
    type = "lib";
    inherit (self) openssl;
  };

  libmsgpack = super.libmsgpack.overrideAttrs(oldAttrs: {
    cmakeFlags = (oldAttrs.cmakeFlags or {}) // {
      MSGPACK_BUILD_EXAMPLES = false;
    };
  });

  man-db = super.man-db.overrideAttrs (oldAttrs: {
    preconv = "${self.groff}/bin/preconv";
  });

  neovim = super.neovim.override {
    withPython = false;
    withPython3 = false;
    withPyGUI = false;
  };

  nginx = (super.nginx.override {
    modules = with self.nginxModules; [
      moreheaders
    ];
  }).overrideAttrs (oldAttrs: rec {
    configureFlags = self.lib.subtractLists [
      "--with-http_realip_module"
      "--with-http_xslt_module"
      "--with-http_geoip_module"
      "--with-http_image_filter_module"
      "--with-http_dav_module"
      "--with-http_flv_module"
      "--with-http_mp4_module"
    ] (oldAttrs.configureFlags or []);
  });

  nodejs-6_x = super.nodejs-6_x.override {
    openssl = self.openssl_1_0_2;
  };

  ntp = super.ntp.override {
    openssl = self.openssl_1_1_0;
  };

  openssh = super.openssh.override {
    # Can disable OpenSSL on NixOS servers (only ed25519 is enabled),
    # but need to link OpenSSL elsewise for places like GitHub, GitLab, etc. :(
    linkOpenssl = !options.isServer;
    withKerberos = true;
  };

  openssl = super.libressl;

  postgresql = self.postgresql96;

  python3 = super.python36;
  python = self.python3;
  pythonPackages = self.python3.pkgs;

  mkVagrantPluginFile = plugins: let
    mkPlugin = name: value: {
      gem_version = "";
      require = "";
      ruby_version = builtins.toString self.vagrant.ruby.version;
      sources = [
        "https://rubygems.org"
        "https://gems.hashicorp.com"
      ];
      vagrant_version = self.vagrant.version;
    };
    pluginsConfig = {
      installed = self.lib.mapAttrs mkPlugin plugins;
      version = "1";
    };
  in self.writeText "plugins.json" (builtins.toJSON pluginsConfig);

  vagrant = super.vagrant.overrideAttrs (oldAttrs: rec {
    buildPhase = (oldAttrs.buildPhase or "") + ''
      ln -sf "${self.mkVagrantPluginFile {}}" opt/vagrant/embedded/plugins.json

      rm opt/vagrant/embedded/gems/cache/vagrant-share-*.gem
      rm opt/vagrant/embedded/gems/specifications/vagrant-share-*.gemspec
      rm -r opt/vagrant/embedded/gems/gems/vagrant-share-*
    '';
  });

  weechat = super.weechat.override {
    guileSupport = false;
    luaSupport = false;
    perlSupport = false;
    #pythonSupport = false; # have a python script
    pythonPackages = super.python2Packages; # TODO: add python3 support, check if script supports it
    #rubySupport = false; # still have a ruby script
    tclSupport = false;
  };

  zsh = super.zsh.overrideAttrs (oldAttrs: rec {
    postPatch = (oldAttrs.postPatch or "") + ''
      rm Scripts/newuser
    '';
  });

  # Why does this have to hardcode the kernel version :(
  linux_4_9 = super.linux_4_9.override {
    extraConfig = ''
        # ENABLE
        BTRFS_FS y
        EXT4_FS y
        VFAT_FS y

        BRIDGE m
        BRIDGE_NETFILTER m
        NF_TABLES_BRIDGE m
        NFT_BRIDGE_REJECT m
        NF_LOG_BRIDGE m
        NF_TABLES y

        TCP_CONG_BBR y
        NET_SCH_FQ y

        # CRYPTO
        #CRYPTO_ECB n
        CRYPTO_MD4 n
        #CRYPTO_MD5 n
        CRYPTO_RMD128 n
        CRYPTO_RMD160 n
        CRYPTO_RMD256 n
        CRYPTO_RMD320 n
        #CRYPTO_SHA1 n
        CRYPTO_BLOWFISH n
        CRYPTO_BLOWFISH_X86_64 n
        CRYPTO_CAMELLIA n
        CRYPTO_CAMELLIA_X86_64 n
        CRYPTO_CAMELLIA_AESNI_AVX_X86_64 n
        CRYPTO_CAMELLIA_AESNI_AVX2_X86_64 n
        CRYPTO_CAMELLIA_X86_64 n
        #CRYPTO_DES n
        CRYPTO_SERPENT n
        CRYPTO_SERPENT_SSE2_X86_64 n
        CRYPTO_SERPENT_AVX_X86_64 n
        CRYPTO_SERPENT_AVX2_X86_64 n
        CRYPTO_TWOFISH n

        # Drivers
        ANDROID n
        BLK_DEV_RBD n
        FIREWIRE n
        INFINIBAND n
        INPUT_JOYSTICK n
        MACINTOSH_DRIVERS n
        NVM n
        PCCARD n
        #SSB n
        STAGING n
        THUNDERBOLT n
        UWB n

        # Filesystems
        ADFS_FS n
        AFFS_FS n
        AFS_FS n
        AUTOFS4_FS n
        BEFS_FS n
        BFS_FS n
        CEPH_FS n
        CIFS n
        CODA_FS n
        CRAMFS n
        DLM n
        ECRYPT_FS n
        EFS_FS n
        EXOFS_FS n
        EXT2_FS n
        F2FS_FS n
        GFS2_FS n
        HFS_FS n
        HFSPLUS_FS n
        HPFS_FS n
        ISO9660_FS n
        JFFS2_FS n
        JFS_FS n
        LOGFS n
        MINIX_FS n
        NCP_FS n
        NFS_FS n
        NFSD n
        NILFS2_FS n
        OCFS2_FS n
        OMFS_FS n
        OVERLAY_FS n
        QNX4FS_FS n
        QNX6FS_FS n
        REISERFS_FS n
        ROMFS_FS n
        SQUASHFS n
        SYSV_FS n
        UBIFS_FS n
        UDF_FS n
        UFS_FS n
        VXFS_FS n
        XFS_FS n

        # GPU Drivers
        DRM_NOUVEAU n
        DRM_RADEON n
        DRM_AMDGPU n

        # Networking
        6LOWPAN n
        ATALK n
        ATM n
        HAMRADIO n
        BATMAN_ADV n
        ## Bridging
        BT n
        CAIF n
        CAN n
        CEPH_LIB n
        DCB n
        DECNET n
        HSR n
        IEEE802154 n
        IP_DCCP n
        IP_SCTP n
        IPX n
        IRDA n
        NET_L3_MASTER_DEV n
        L2TP n
        LAPB n
        MPLS n
        NFC n
        OPENVSWITCH n
        PHONET n
        PLIP n
        PPP n
        RDS n
        RFKILL n
        AF_RXRPC n
        SLIP n
        TIPC n
        X25 n
        WAN n
        WIMAX n

        # TTY
        LEGACY_PTYS n
        SERIAL_NONSTANDARD n
      '' + self.lib.optionalString (options.isServer) ''
        # Drivers
        INPUT_TABLET n
        INPUT_TOUCHSCREEN n

        # Networking
        WLAN n

        # Sound
        SOUND n
      ''
      ;
  };

  stdenv = super.stdenv // {
    platform = super.stdenv.platform // {
      kernelExtraConfig = ''
        ## Misc
        ## HYPERVISOR_GUEST n # causes unused option KVM_GUEST
        ## XEN n # causes unused option error

        ## ACCESSIBILITY n # investigate
        ## ACPI y
        ## ARM_AMBA n # causes unused option error
        ## ATA y
        ## ATM_DRIVERS n # taken care of by ATM
        FPGA n
        ## I2C n # caused some weird error
        ## IIO n # causes repeated question error
        ## INPUT n # causes option is not set correctly error...
        ## PINCTRL n # causes option is not set correctly here
        ## PPS n # causes repeated question error
        ## PTP_1588_CLOCK n # causes repeated quesiton error
        PWM n
        ## SPI n # caused an unused error
        ##SSB n # causes repeated question error

        ## Filesystems DONE
        ## TODO:
        ## investigate:
        ## EXPORTFS, TMPFS, HUGETLBFS, KERNFS, more
        ## 9P: investigate its use for caching or something in nixos vm tests?
        ## CONFIGFS_FS: investigate
        ## EFIVAR_FS: investigate
        ## FUSE_FS: investigate
        ## NTFS_FS: investigate (need for flash drive for 6.115?)
        ## PROC_FS: investigate
        ## SYSFS investigate
      '';
    };
  };
}
