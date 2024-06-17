# Check:
#$ nix flake check
#$ nix repl
#nix-repl> :lf .
#nix-repl> nixosConfigurations.<host>.config

# Build:
#$ flake build-system [#<host>]
#$ nixos-rebuild build --fast --flake .#<host> --show-trace
#$ nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# Activate:
#$ flake <test|switch|boot> [#<host>]
#$ nixos-rebuild --flake .#<host> <test|switch|boot>
#$ nix run .#nixosConfigurations.<host>.config.system.build.toplevel

{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.schallernetz; {
  imports = [ ./hardware-configuration.nix ];

  schallernetz = rec { };

  environment.systemPackages = with pkgs; [
  ];

  # add device-specific nixos configuration here #

  system.stateVersion = "24.05";
}
