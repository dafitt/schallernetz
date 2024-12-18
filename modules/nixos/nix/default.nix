{ options, config, lib, pkgs, inputs, ... }:

with lib;
{
  programs.git.enable = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      warn-dirty = false;
      trusted-users = [ "root" ];
      allowed-users = [ "@wheel" ];
    };

    gc = {
      automatic = true;
      dates = "monthly";
      options = "--delete-older-than 2m";
    };

    # disable nix-channel, we use flakes instead.
    channel.enable = false;
  };
}
