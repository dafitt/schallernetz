{ config, pkgs, ... }: {

  virtualisation = {
    podman.enable = true;
    oci-containers.backend = "podman";
    #containers = {
    #  enable = true;
    #  storage.settings.storage = {
    #    driver = "zfs";
    #    graphroot = "/persist/podman/containers";
    #    runroot = "/run/containers/storage";
    #  };
    #};
  };

  system.activationScripts."mkDockerNetwork" =
    let
      docker = config.virtualisation.oci-containers.backend;
      dockerBin = "${pkgs.${docker}}/bin/${docker}";
    in
    ''
      ${dockerBin} network inspect ipvlan >/dev/null 2>&1 || \
      ${dockerBin} network create \
        --driver ipvlan \
        --opt parent=br0 \
        --ipv6 \
        --subnet ***REMOVED_IPv4***/23 --subnet ***REMOVED_IPv6***::/64 \
        --gateway ***REMOVED_IPv4*** --gateway ***REMOVED_IPv6*** \
        ipvlan
    '';
}
