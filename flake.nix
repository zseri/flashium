{
  description = "Pinned, old chromium with an old flash player";
  inputs.nixpkgs = {
    url = "github:nixos/nixpkgs?rev=6a0a07318763375dd90125fdf73f690e6c49687e";
    flake = false;
  };
  outputs = { self, nixpkgs }: rec {
    overlay = final: prev: (import ./overlay.nix) final (import nixpkgs {
      inherit (final) system;
      config.allowUnfree = true;
    });

    defaultPackage.x86_64-linux =
      let
        nixpkgs' = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      in
        (import ./overlay.nix nixpkgs' nixpkgs').flashium;
  };
}
