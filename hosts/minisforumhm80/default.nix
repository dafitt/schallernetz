{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix

    ../../users/admin.nix

    ../../common/nix.nix

    ../../services/DavidSYNC.nix
    ../../services/DavidVPN.nix
    ../../services/MichiSHARE.nix
    ../../services/pihole.nix
    ../../services/searx.nix
    ../../services/unbound.nix
  ];
}
