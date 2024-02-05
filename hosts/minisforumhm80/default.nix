{ agenix, ... }: {
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    agenix.nixosModules.default

    ../../users/admin.nix

    ../../common/nix.nix

    ../../services/DavidCAL.nix
    ../../services/DavidSYNC.nix
    ../../services/DavidVPN.nix
    ../../services/haproxy.nix
    ../../services/MichiSHARE.nix
    #../../services/pihole.nix
    ../../services/searx.nix
    ../../services/unbound.nix
  ];
}
