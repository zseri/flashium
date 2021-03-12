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
          findutils = final.findutils;
          translate = (pname: newchrom: final.stdenvNoCC.mkDerivation rec {
            inherit pname;
            inherit (newchrom) version;

            mylnx = final.substituteAll {
              src = ./flashium_lnx.sh;
              isExecutable = true;
              inherit (final) bash coreutils gnused;
            };
            nativeBuildInputs = [ findutils ];
            buildInputs = [ newchrom ];
            buildCommand = ''
              ${findutils}/bin/find -L ${newchrom} '!' -type d -execdir '${mylnx}' '{}' ';'
              rm "$out/share/applications/flashium-browser.desktop"
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
