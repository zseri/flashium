{
  description = "Pinned, old chromium with an old flash player";
  inputs.nixpkgs = {
    url = "github:nixos/nixpkgs?rev=6a0a07318763375dd90125fdf73f690e6c49687e";
    flake = false;
  };
  outputs = { self, nixpkgs }: {
    overlay = final: prev: (import ./overlay.nix) final nixpkgs;
  };
}
