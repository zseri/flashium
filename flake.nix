{
  description = "Pinned, old chromium with an old flash player";
  inputs.nixpkgs = {
    url = "github:nixos/nixpkgs?rev=6a0a07318763375dd90125fdf73f690e6c49687e";
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
          newchrom = nixpkgs'.callPackage ./chromium (nixpkgs' // { enablePepperFlash = true; });
        in {
          flashium = final.stdenvNoCC.mkDerivation rec {
            pname = "flashium";
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
          };
        }
      );
    };
}
