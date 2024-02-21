{ inputs, path, ... }: {
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    inputs.agenix.nixosModules.default

    "${path.usersDir}/admin.nix"

    "${path.commonDir}/nix.nix"

    "${path.containersDir}/adguard.nix"
    "${path.containersDir}/DavidCAL.nix"
    "${path.containersDir}/DavidSYNC.nix"
    "${path.containersDir}/DavidVPN.nix"
    "${path.containersDir}/MichiSHARE.nix"
    "${path.containersDir}/searx.nix"
    "${path.containersDir}/unbound.nix"
    "${path.servicesDir}/haproxy.nix"
  ];
}
