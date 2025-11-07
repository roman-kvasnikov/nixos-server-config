{config, ...}: let
  cfgHomelab = config.homelab;
in {
  users = {
    users = {
      ${cfgHomelab.adminUser} = {
        isNormalUser = true;
        extraGroups = ["wheel" "users" "docker" "podman" "nextcloud" cfgHomelab.systemGroup];
        hashedPasswordFile = cfgHomelab.adminPasswordFile;
      };

      ${cfgHomelab.systemUser} = {
        isSystemUser = true;
        uid = 989;
        group = cfgHomelab.systemGroup;
      };
    };

    groups.${cfgHomelab.systemGroup} = {
      gid = 989;
    };
  };
}
