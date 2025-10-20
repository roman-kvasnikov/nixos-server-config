{config, ...}: {
  users = {
    users = {
      ${config.server.adminUser} = {
        isNormalUser = true;
        extraGroups = ["wheel" "users" "docker" "nextcloud" config.server.systemGroup];
        hashedPasswordFile = config.server.adminPasswordFile;
      };

      ${config.server.systemUser} = {
        isSystemUser = true;
        uid = 989;
        group = config.server.systemGroup;
      };
    };

    groups.${config.server.systemGroup} = {
      gid = 989;
    };
  };
}
