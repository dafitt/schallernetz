{
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix

    ../../users/admin.nix

    ../../common/nix.nix

    ../../services/DavidSYNC.nix
  ];
}
