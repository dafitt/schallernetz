#$ nix repl .#nixosConfigurations.minisforumhm80
#$ nix build .#nixosConfigurations.minisforumhm80.config.system.build.toplevel
#$ nixos-rebuild build --fast --flake .#minisforumhm80 --show-trace
#$ ssh-add ~/.ssh/minisforumhm80 && nixos-rebuild --flake .#minisforumhm80 --target-host admin@minisforumhm80.***REMOVED_DOMAIN*** --use-remote-sudo <test|boot|switch>

{ lib, ... }: with lib.schallernetz; {
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
  ];

  schallernetz = {
    containers = {
      adguard.enable = true;
      DavidCAL.enable = true;
      DavidSYNC.enable = true;
      DavidVPN.enable = true;
      MichiSHARE.enable = true;
      searx.enable = true;
      unbound.enable = true;
    };
    services.haproxy.enable = true;
  };
}
