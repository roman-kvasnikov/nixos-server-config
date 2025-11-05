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
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      nvidiaPersistenced = true;
      open = false; # ❌ Оставляем проприетарные (закрытые) драйверы для GTX 10XX и выше
    };
  };

  services.xserver.videoDrivers = ["nvidia"];
}
