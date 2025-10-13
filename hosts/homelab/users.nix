{config, ...}: {
  users = {
    users = {
      romank = {
        isNormalUser = true;
        extraGroups = ["wheel" "users" "docker" config.server.systemGroup];
      };
    };
  };
}
