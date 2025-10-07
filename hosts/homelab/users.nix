{config, ...}: {
  users = {
    romank = {
      isNormalUser = true;
      extraGroups = ["wheel" "users" config.server.systemGroup];
    };
  };
}
