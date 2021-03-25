let
  f = builtins.getFlake (toString ./.)
in
  (f.overlay (import <nixpkgs> {}) <nixpkgs>).flashium
