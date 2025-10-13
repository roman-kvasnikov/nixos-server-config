{config, ...}: {
  users = {
    users = {
      ${config.server.adminUser} = {
        isNormalUser = true;
        extraGroups = ["wheel" "users" "docker" config.server.systemGroup];
      };

      ${config.server.systemUser} = {
        isSystemUser = true;
        group = config.server.systemGroup;
      };
    };

    groups.${config.server.systemGroup} = {};
  };
}
