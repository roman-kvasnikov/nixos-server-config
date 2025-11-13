{
  config,
  pkgs,
  ...
}: {
  hardware = {
    graphics = {
      enable = true;

      extraPackages = with pkgs; [
        intel-media-driver # для Intel (новые GPU)
        intel-vaapi-driver # для старых Intel
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
  };
}
