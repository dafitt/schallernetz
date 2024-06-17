#$ nix repl .#nixosConfigurations.<host>
#$ nix build .#nixosConfigurations.<host>.config.system.build.toplevel
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
