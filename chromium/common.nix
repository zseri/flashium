{ stdenv, gn, ninja, which, nodejs, fetchurl, fetchpatch, gnutar

# default dependencies
, bzip2, flac, speex, libopus
, libevent, expat, libjpeg, snappy
, libpng, libcap
, xdg_utils, yasm, minizip, libwebp
, libusb1, pciutils, nss, re2, zlib

, python2Packages, perl, pkgconfig
, nspr, systemd, kerberos
, utillinux, alsaLib
, bison, gperf
, glib, gtk2, gtk3, dbus-glib
, libXScrnSaver, libXcursor, libXtst, libGLU_combined
, protobuf, speechd, libXdamage, cups
, ffmpeg, libxslt, libxml2, at-spi2-core

, paxctl

# optional dependencies
, libgcrypt ? null # gnomeSupport || cupsSupport

# package customization
, enableNaCl ? false
, enableWideVine ? false
, gnomeSupport ? false, gnome ? null
, gnomeKeyringSupport ? false, libgnome-keyring3 ? null
, proprietaryCodecs ? true
, cupsSupport ? true
, pulseSupport ? true, libpulseaudio ? null

, upstream-info
}:

buildFun:

with stdenv.lib;

# see http://www.linuxfromscratch.org/blfs/view/cvs/xsoft/chromium.html

let
  # The additional attributes for creating derivations based on the chromium
  # source tree.
  extraAttrs = buildFun base;

  githubPatch = commit: sha256: fetchpatch {
    url = "https://github.com/chromium/chromium/commit/${commit}.patch";
    inherit sha256;
  };

  mkGnFlags =
    let
      # Serialize Nix types into GN types according to this document:
      # https://chromium.googlesource.com/chromium/src/+/master/tools/gn/docs/language.md
      mkGnString = value: "\"${escape ["\"" "$" "\\"] value}\"";
      sanitize = value:
        if value == true then "true"
        else if value == false then "false"
        else if isList value then "[${concatMapStringsSep ", " sanitize value}]"
        else if isInt value then toString value
        else if isString value then mkGnString value
        else throw "Unsupported type for GN value `${value}'.";
      toFlag = key: value: "${key}=${sanitize value}";
    in attrs: concatStringsSep " " (attrValues (mapAttrs toFlag attrs));

  gnSystemLibraries = [
    "flac" "libwebp" "libxslt" "yasm" "opus" "snappy" "libpng" "zlib"
    # "libjpeg" # fails with multiple undefined references to chromium_jpeg_*
    # "re2" # fails with linker errors
    # "ffmpeg" # https://crbug.com/731766
    # "harfbuzz-ng" # in versions over 63 harfbuzz and freetype are being built together
                    # so we can't build with one from system and other from source
  ];

  opusWithCustomModes = libopus.override {
    withCustomModes = true;
  };

  defaultDependencies = [
    bzip2 flac speex opusWithCustomModes
    libevent expat libjpeg snappy
    libpng libcap
    xdg_utils yasm minizip libwebp
    libusb1 re2 zlib
    ffmpeg libxslt libxml2
    # harfbuzz # in versions over 63 harfbuzz and freetype are being built together
               # so we can't build with one from system and other from source
  ];

  # build paths and release info
  packageName = extraAttrs.packageName or extraAttrs.name;
  buildType = "Release";
  buildPath = "out/${buildType}";
  libExecPath = "$out/libexec/${packageName}";

  freetype_source = fetchurl {
    url = http://anduin.linuxfromscratch.org/BLFS/other/chromium-freetype.tar.xz;
    sha256 = "1vhslc4xg0d6wzlsi99zpah2xzjziglccrxn55k7qna634wyxg77";
  };

  versionRange = min-version: upto-version:
    let inherit (upstream-info) version;
        result = versionAtLeast version min-version && versionOlder version upto-version;
        stable-version = (import ./upstream-info.nix).stable.version;
    in if versionAtLeast stable-version upto-version
       then warn "chromium: stable version ${stable-version} is newer than a patchset bounded at ${upto-version}. You can safely delete it."
            result
       else result;

  base = rec {
    pname = packageName;
    inherit (upstream-info) version;
    inherit packageName buildType buildPath;

    src = upstream-info.main;

    nativeBuildInputs = [
      ninja which python2Packages.python perl pkgconfig
      python2Packages.ply python2Packages.jinja2 nodejs
      gnutar paxctl
    ];

    buildInputs = defaultDependencies ++ [
      nspr nss systemd
      utillinux alsaLib
      bison gperf kerberos
      glib gtk2 gtk3 dbus-glib
      libXScrnSaver libXcursor libXtst libGLU_combined
      pciutils protobuf speechd libXdamage
    ] ++ optional gnomeKeyringSupport libgnome-keyring3
      ++ optionals gnomeSupport [ gnome.GConf libgcrypt ]
      ++ optionals cupsSupport [ libgcrypt cups ]
      ++ optional pulseSupport libpulseaudio
      ++ optional (versionAtLeast version "71") at-spi2-core;

    patches = [
      # As major versions are added, you can trawl the gentoo and arch repos at
      # https://gitweb.gentoo.org/repo/gentoo.git/plain/www-client/chromium/
      # https://git.archlinux.org/svntogit/packages.git/tree/trunk?h=packages/chromium
      # for updated patches and hints about build flags
    # (gentooPatch "<patch>" "0000000000000000000000000000000000000000000000000000000000000000")
      ./patches/fix-freetype.patch
      ./patches/nix_plugin_paths_68.patch
      ./patches/remove-webp-include-69.patch
    ] ++ optional enableWideVine ./patches/widevine.patch
      ++ optional ((versionRange "69" "70") && stdenv.isAarch64)
           (fetchpatch {
              url    = https://raw.githubusercontent.com/OSSystems/meta-browser/e4a667deaaf9a26a3a1aeb355770d1f29da549ad/recipes-browser/chromium/files/0001-vpx_sum_squares_2d_i16_neon-Make-s2-a-uint64x1_t.patch;
              sha256 = "0f37rsjx7jcvdngkj8y6600091nwgn4jci0ny7bxlapq0zx2a4x7";
            })
      ++ optional stdenv.isAarch64
           (if (versionOlder version "71") then
              fetchpatch {
                url       = https://raw.githubusercontent.com/OSSystems/meta-browser/e4a667deaaf9a26a3a1aeb355770d1f29da549ad/recipes-browser/chromium/files/aarch64-skia-build-fix.patch;
                sha256    = "0dkchqair8cy2f5a5p5vi24r9b4d28pgn2bfvm1568lypbjw6iab";
              }
            else
              fetchpatch {
                url       = https://raw.githubusercontent.com/OSSystems/meta-browser/e4a667deaaf9a26a3a1aeb355770d1f29da549ad/recipes-browser/chromium/files/aarch64-skia-build-fix.patch;
                postFetch = "substituteInPlace $out --replace __aarch64__ SK_CPU_ARM64";
                sha256    = "018fbdzyw9rvia8m0qkk5gv8q8gl7x34rrjbn7mi1fgxdsayn22s";
              }
            );

    postPatch = ''
      # We want to be able to specify where the sandbox is via CHROME_DEVEL_SANDBOX
      substituteInPlace sandbox/linux/suid/client/setuid_sandbox_host.cc \
        --replace \
          'return sandbox_binary;' \
          'return base::FilePath(GetDevelSandboxPath());'

      sed -i -e 's@"\(#!\)\?.*xdg-@"\1${xdg_utils}/bin/xdg-@' \
        chrome/browser/shell_integration_linux.cc

      sed -i -e '/lib_loader.*Load/s!"\(libudev\.so\)!"${systemd.lib}/lib/\1!' \
        device/udev_linux/udev?_loader.cc

      sed -i -e '/libpci_loader.*Load/s!"\(libpci\.so\)!"${pciutils}/lib/\1!' \
        gpu/config/gpu_info_collector_linux.cc

      sed -i -re 's/([^:])\<(isnan *\()/\1std::\2/g' \
        chrome/browser/ui/webui/engagement/site_engagement_ui.cc

      sed -i -e '/#include/ {
        i #include <algorithm>
        :l; n; bl
      }' gpu/config/gpu_control_list.cc

      # Allow to put extensions into the system-path.
      sed -i -e 's,/usr,/run/current-system/sw,' chrome/common/chrome_paths.cc

      patchShebangs .
      # use our own nodejs
      mkdir -p third_party/node/linux/node-linux-x64/bin
      ln -s $(which node) third_party/node/linux/node-linux-x64/bin/node

      # use patched freetype
      # FIXME https://bugs.chromium.org/p/pdfium/issues/detail?id=733
      # FIXME http://savannah.nongnu.org/bugs/?51156
      tar -xJf ${freetype_source}

      # remove unused third-party
      # in third_party/crashpad third_party/zlib contains just a header-adapter
      for lib in ${toString gnSystemLibraries}; do
        find -type f -path "*third_party/$lib/*"     \
            \! -path "*third_party/crashpad/crashpad/third_party/zlib/*"  \
            \! -path "*third_party/$lib/chromium/*"  \
            \! -path "*third_party/$lib/google/*"    \
            \! -path "*base/third_party/icu/*"       \
            \! -path "*base/third_party/libevent/*"  \
            \! -regex '.*\.\(gn\|gni\|isolate\|py\)' \
            -delete
      done
    '' + optionalString stdenv.isAarch64 ''
      substituteInPlace build/toolchain/linux/BUILD.gn \
        --replace 'toolprefix = "aarch64-linux-gnu-"' 'toolprefix = ""'
    '';

    gnFlags = mkGnFlags ({
      linux_use_bundled_binutils = false;
      use_gold = true;
      gold_path = "${stdenv.cc}/bin";
      is_debug = false;

      proprietary_codecs = false;
      use_sysroot = false;
      use_gnome_keyring = gnomeKeyringSupport;
      use_gio = gnomeSupport;
      enable_nacl = enableNaCl;
      enable_widevine = enableWideVine;
      use_cups = cupsSupport;

      treat_warnings_as_errors = false;
      is_clang = false;
      clang_use_chrome_plugins = false;
      remove_webcore_debug_symbols = true;
      enable_swiftshader = false;
      fieldtrial_testing_like_official_build = true;

      # Google API keys, see:
      #   http://www.chromium.org/developers/how-tos/api-keys
      # Note: These are for NixOS/nixpkgs use ONLY. For your own distribution,
      # please get your own set of keys.
      google_api_key = "AIzaSyDGi15Zwl11UNe6Y-5XW_upsfyw31qwZPI";
      google_default_client_id = "404761575300.apps.googleusercontent.com";
      google_default_client_secret = "9rIFQjfnkykEmqb6FfjJQD1D";
    } // optionalAttrs (versionRange "60" "70") {
      use_gtk3 = true;
    } // optionalAttrs proprietaryCodecs {
      # enable support for the H.264 codec
      proprietary_codecs = true;
      enable_hangout_services_extension = true;
      ffmpeg_branding = "Chrome";
    } // optionalAttrs pulseSupport {
      use_pulseaudio = true;
      link_pulseaudio = true;
    } // (extraAttrs.gnFlags or {}));

    configurePhase = ''
      runHook preConfigure

      # This is to ensure expansion of $out.
      libExecPath="${libExecPath}"
      python build/linux/unbundle/replace_gn_files.py \
        --system-libraries ${toString gnSystemLibraries}
      ${gn}/bin/gn gen --args=${escapeShellArg gnFlags} out/Release | tee gn-gen-outputs.txt

      # Fail if `gn gen` contains a WARNING.
      grep -o WARNING gn-gen-outputs.txt && echo "Found gn WARNING, exiting nix build" && exit 1

      runHook postConfigure
    '';

    buildPhase = let
      # Build paralelism: on Hydra the build was frequently running into memory
      # exhaustion, and even other users might be running into similar issues.
      # -j is halved to avoid memory problems, and -l is slightly increased
      # so that the build gets slight preference before others
      # (it will often be on "critical path" and at risk of timing out)
      # lol, ignore that
      buildCommand = target: ''
        ninja -v -C "${buildPath}" \
          -j$NIX_BUILD_CORES -l$(( $NIX_BUILD_CORES+1 )) \
          "${target}"
        (
          source chrome/installer/linux/common/installer.include
          PACKAGE=$packageName
          MENUNAME="Chromium"
          process_template chrome/app/resources/manpage.1.in "${buildPath}/chrome.1"
        )
      '' + optionalString (target == "mksnapshot" || target == "chrome") ''
        ${paxctl}/bin/paxctl -c "${buildPath}/${target}"
        ${paxctl}/bin/paxctl -zex -m "${buildPath}/${target}"
      '';
      targets = extraAttrs.buildTargets or [];
      commands = map buildCommand targets;
    in concatStringsSep "\n" commands;
  };

# Remove some extraAttrs we supplied to the base attributes already.
in stdenv.mkDerivation (base // removeAttrs extraAttrs [
  "name" "gnFlags" "buildTargets"
])
