{ agenix, ... }: {
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    agenix.nixosModules.default

    ../../users/admin.nix

    ../../common/nix.nix

    ../../containers/DavidCAL.nix
    ../../containers/DavidSYNC.nix
    ../../containers/DavidVPN.nix
    ../../containers/MichiSHARE.nix
    ../../containers/searx.nix
    ../../containers/unbound.nix
    ../../services/haproxy.nix
  ];
}
