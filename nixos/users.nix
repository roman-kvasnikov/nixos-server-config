{
  config,
  pkgs,
  ...
}: let
  cfgHomelab = config.homelab;
in {
  users = {
    users = {
      ${cfgHomelab.adminUser} = {
        isNormalUser = true;
        extraGroups = ["wheel" "users" "docker" "podman" "nextcloud" "samba" "downloads" "media"];
        hashedPasswordFile = config.age.secrets.admin-password.path;
      };
    };
  };

  age.secrets.admin-password = {
    file = ../secrets/admin.password.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
