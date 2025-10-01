{pkgs, ...}: {
  users = {
    users.romank = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = ["wheel" "input" "networkmanager" "video" "audio" "disk" "samba"];
    };
  };
}
