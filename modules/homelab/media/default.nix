{
  imports = [
    ./jellyfin.nix
    ./jellyseerr.nix
    ./prowlarr.nix
    ./qbittorrent.nix
    ./radarr.nix
    ./sonarr.nix
  ];

  users.groups = {
    downloads = {};
    media = {};
  };
}
