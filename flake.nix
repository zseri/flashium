{
  description = "Pinned, old chromium with an old flash player";
  inputs.nixpkgs = {
    url = "github:nixos/nixpkgs?rev=3a21f65a0b1960148460c9066898480540403572";
    flake = false;
  };

  outputs = { self, nixpkgs }:
    {
      overlay = final: prev: (
        let
          nixpkgs' = import nixpkgs {
            inherit (final) system;
            config.allowUnfree = true;
          };
          lndir = final.xorg.lndir;
          translate = (pname: newchrom: final.stdenvNoCC.mkDerivation {
            inherit pname;
            inherit (newchrom) version;

            nativeBuildInputs = [ lndir ];
            buildInputs = [ newchrom ];
            buildCommand = ''
              mkdir -p $out/share
              mkdir $out/share/applications $out/share/icons

              for i in 'bin ' 'share/man/man1 .1'; do
                tmpmid=$(echo "$i"| cut -f1 -d' ')
                tmpsfx=$(echo "$i"| cut -f2 -d' ')
                mkdir -p $out/$tmpmid
                ln -s "${newchrom}/$tmpmid/chromium$tmpsfx" "$out/$tmpmid/flashium$tmpsfx"
              done

              ${lndir}/bin/lndir -silent ${newchrom}/share/icons $out/share/icons
              for i in $out/share/icons/*/*; do
                mv -T "$i" "''${i/chromium/flashium}"
              done

              cp -T ${newchrom}/share/applications/chromium-browser.desktop $out/share/applications/flashium-browser.desktop
              substituteInPlace $out/share/applications/flashium-browser.desktop \
                --replace chromium flashium \
                --replace Chromium Flashium
            '';

            meta = {
              # we want this to be opt-in, as this bundles flash player
              license = nixpkgs'.lib.licenses.unfree;
            };
          });
        in builtins.listToAttrs (
          builtins.map
            ({n, c}: rec {
              name = n + "flashium";
              value = (translate name (nixpkgs'.callPackage ./chromium (c // { enablePepperFlash = true; })));
            })
            [
              { n=""; c={}; }
              { n = "ungoogled-";
                c = {
                  ungoogled = true;
                  channel = "ungoogled-chromium";
                };
              }
            ]
        )
      );
    };
}
