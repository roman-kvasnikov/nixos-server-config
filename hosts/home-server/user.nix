{pkgs, ...}: {
  users.users = {
    romank = {
      isNormalUser = true;
      extraGroups = ["wheel" "users" "networkmanager" "samba"];
      createHome = true;
    };
  };
}
