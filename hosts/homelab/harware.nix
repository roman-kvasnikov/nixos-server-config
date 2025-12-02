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
        intel-media-sdk # для Intel (новые GPU)
        intel-compute-runtime
        intel-vaapi-driver # для старых Intel
        libva-utils
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
  };
}
