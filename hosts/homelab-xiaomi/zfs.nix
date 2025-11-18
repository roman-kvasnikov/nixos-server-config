{
  config,
  lib,
  pkgs,
  ...
}: let
  zfsCompatibleKernelPackages =
    lib.filterAttrs (
      name: kernelPackages:
        (builtins.match "linux_[0-9]+_[0-9]+" name)
        != null
        && (builtins.tryEval kernelPackages).success
        && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
    )
    pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in {
  boot = {
    kernelPackages = lib.mkForce latestKernelPackage;
    zfs.extraPools = ["zdata" "zmedia"];
  };

  networking.hostId = "8425e349";

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };
}
