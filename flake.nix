{
  description = "Pinned, old chromium with an old flash player";
  inputs.nixpkgs.url = "github:nixos/nixpkgs?rev=f63bc540cbd559736f1671e4ee10e4560b3d5d2a";
  outputs = { self, nixpkgs }:
    let
      pwl = ["" "ungoogled-"];
      oldname = "chromium";
      newname = "flashium";
      attrsets = nixpkgs.lib.attrsets;
    in {
      overlay = final: prev: (
        let
          translate = (pname: newchrom: final.stdenvNoCC.mkDerivation {
            inherit pname;
            inherit (newchrom) version;

            nativeBuildInputs = [ final.lndir ];
            buildInputs = [ newchrom ];
            buildCommand = ''
              mkdir -p $out/share
              mkdir $out/share/applications $out/share/icons

              for i in 'bin ' 'share/man/man1 .1'; do
                tmpmid=$(echo "$i"| cut -f1 -d' ')
                tmpsfx=$(echo "$i"| cut -f2 -d' ')
                mkdir -p $out/$tmpmid
                ln -s "${newchrom}/$tmpmid/${oldname}$tmpsfx" "$out/$tmpmid/${newname}$tmpsfx"
              done

              ${final.lndir}/bin/lndir -silent ${newchrom}/share/icons $out/share/icons
              for i in $out/share/icons/*/*; do
                mv -T "$i" "''${i/${oldname}/${newname}}"
              done

              cp -T ${newchrom}/share/applications/${oldname}-browser.desktop $out/share/applications/${newname}-browser.desktop
              substituteInPlace $out/share/applications/${newname}-browser.desktop \
                --replace ${oldname} ${newname} \
                --replace Chromium Flashium
            '';
          });
        in
          attrsets.listToAttrs (
            builtins.map
              (n: rec {
                name = n + newname;
                value = translate name (nixpkgs.${n + oldname}.override { enablePepperFlash = true; });
              })
              pwl
          )
      );
    };
}
