#$ nix repl .#nixosConfigurations.<host>
#$ nix build .#nixosConfigurations.<host>.config.system.build.toplevel
#$ nixos-rebuild build --fast --flake .#<host> --show-trace
#$ ssh-add ~/.ssh/<host> && nixos-rebuild --flake .#<host> --target-host admin@<host> --use-remote-sudo <test|switch|boot>

{ lib, ... }: with lib.schallernetz; {
  imports = [ ./hardware-configuration.nix ];

  schallernetz = { };

  system.stateVersion = "23.11"; # move this line to hardware-configuration.nix
}
