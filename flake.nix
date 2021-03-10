{
  description = "Pinned, old chromium with an old flash player";
  inputs.nixpkgs.url = "github:nixos/nixpkgs?rev=f63bc540cbd559736f1671e4ee10e4560b3d5d2a";
  outputs = { self, nixpkgs }: {
    overlay = final: prev: (
      prev.lib.attrsets.genAttrs
        ["chromium" "ungoogled-chromium"]
        (name: prev.${name}.override { enablePepperFlash = true; })
    );
  };
}
