let nixpkgs = import <nixpkgs> { };
in (import ./overlay.nix nixpkgs nixpkgs).flashium
