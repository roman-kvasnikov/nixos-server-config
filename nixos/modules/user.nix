{pkgs, ...}: {
  users.users = {
    romank = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = ["wheel" "users" "networkmanager" "samba"];
    };
  };
}
