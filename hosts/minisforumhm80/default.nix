{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix

    ../../users/admin.nix

    ../../common/nix.nix

    ../../services/DavidSYNC.nix
    ../../services/MichiSHARE.nix
    ../../services/pihole.nix
    ../../services/unbound.nix
  ];
}
