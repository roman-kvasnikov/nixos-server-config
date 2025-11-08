{config, ...}: let
  cfgHomelab = config.homelab;
in {
  users = {
    users = {
      ${cfgHomelab.adminUser} = {
        isNormalUser = true;
        extraGroups = ["wheel" "users" "docker" "podman" "nextcloud" cfgHomelab.systemGroup];
        hashedPasswordFile = config.age.secrets.admin-password.path;
      };

      ${cfgHomelab.systemUser} = {
        isSystemUser = true;
        group = cfgHomelab.systemGroup;
      };
    };

    groups.${cfgHomelab.systemGroup} = {};
  };

  age.secrets.admin-password = {
    file = ../../secrets/admin-password.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
