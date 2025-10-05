{pkgs, ...}: {
  users.users = {
    romank = {
      isNormalUser = true;
      extraGroups = ["wheel" "users"];
    };
  };
}
