{ pkgs, ... }: {
  users.users."admin" = {
    isNormalUser = true;
    description = "Administrator";

    extraGroups = [ "wheel" ];

    packages = with pkgs; [ ];
  };
}
