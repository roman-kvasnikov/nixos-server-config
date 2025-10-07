{
  lib,
  config,
  ...
}: let
  cfgAcme = config.services.acmectl;
  cfgNextcloud = config.services.nextcloudctl;
in {
  config = {
    environment.etc = {
      # ${cfgAcme.commonCertOptions.credentialsFile}.text = lib.mkIf cfgAcme.enable ''
      #   NAMECHEAP_API_USER=RomanKW
      #   NAMECHEAP_API_KEY=545cef3f919847b28999ca3eb2b643b9
      #   NAMECHEAP_API_IP=188.243.2.115
      # '';

      ${cfgNextcloud.adminpassFile}.text = lib.mkIf cfgNextcloud.enable "123";
    };
  };
}
