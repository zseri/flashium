{
  description = "Pinned, old chromium with an old flash player";
  inputs.nixpkgs.url = "github:nixos/nixpkgs?rev=f63bc540cbd559736f1671e4ee10e4560b3d5d2a";
  outputs = { self, nixpkgs }:
    let
      pwl = ["chromium" "ungoogled-chromium"];
      suffix = "-yflashed";
      attrsets = nixpkgs.lib.attrsets;
    in {
      overlay = final: prev: (
        let
          translate = (name:
            let
              newchrom = nixpkgs.${name}.override { enablePepperFlash = true; };
              lndir = final.lndir;
            in final.stdenvNoCC.mkDerivation {
              pname = name + suffix;
              version = nixpkgs.${name}.version;
              nativeBuildInputs = [ lndir ];
              buildInputs = [ chrom ];
              buildCommand = ''
                mkdir -p $out/share
                mkdir $out/share/applications $out/share/icons

                for i in 'bin ' 'share/man/man1 .1'; do
                  tmpmid=$(echo "$i"| cut -f1 -d' ')
                  tmpsfx=$(echo "$i"| cut -f2 -d' ')
                  mkdir -p $out/$tmpmid
                  ln -s "${newchrom}/$tmpmid/chromium$tmpsfx" "$out/$tmpmid/chromium${suffix}$tmpsfx"
                done

                ${lndir}/bin/lndir -silent ${newchrom}/share/icons $out/share/icons
                for i in $out/share/icons/*/*; do
                  mv -T "$i" "''${i/chromium/chromium${suffix}}"
                done

                cp -T ${newchrom}/share/applications/chromium-browser.desktop $out/share/applications/chromium-browser${suffix}.desktop
                substituteInPlace $out/share/applications/chromium-browser${suffix}.desktop \
                  --replace chromium-browser chromium-browser${suffix} \
                  --replace chromium chromium${suffix} \
                  --replace Chromium Chromium${suffix}
              '';
            }
          );
        in
          attrsets.mapAttrs'
            (name: value: attrsets.nameValuePair (name + suffix) value)
            (attrsets.genAttrs pwl translate)
      );
    };
}
