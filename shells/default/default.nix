{ pkgs, inputs, ... }:

#$ nix develop
pkgs.mkShell {
  nativeBuildInputs = with pkgs; with inputs; [
    git
    nix
    openssh
  ];
}
