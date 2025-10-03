{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.cockpit-proxy;
in {
  options.services.cockpit-proxy = {
    enable = mkEnableOption "Cockpit with nginx reverse proxy";

    domain = mkOption {
      type = types.str;
      example = "cockpit.example.com";
      description = "Domain name for Cockpit access";
    };

    useSubdirectory = mkOption {
      type = types.bool;
      default = false;
      description = "Serve Cockpit from subdirectory instead of subdomain";
    };

    urlPath = mkOption {
      type = types.str;
      default = "/cockpit";
      example = "/admin";
      description = "URL path when using subdirectory mode";
    };

    cockpitPort = mkOption {
      type = types.port;
      default = 9090;
      description = "Port on which Cockpit listens";
    };

    cockpitHost = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "192.168.1.10";
      description = "Host address where Cockpit is running";
    };

    enableSSL = mkOption {
      type = types.bool;
      default = true;
      description = "Enable SSL/TLS for nginx (can be disabled for local/home networks)";
    };

    allowUnencrypted = mkOption {
      type = types.bool;
      default = false;
      description = "Allow unencrypted HTTP connections to Cockpit (useful for home networks)";
    };

    sslCertificate = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/var/lib/acme/cockpit.example.com/cert.pem";
      description = "Path to SSL certificate";
    };

    sslCertificateKey = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/var/lib/acme/cockpit.example.com/key.pem";
      description = "Path to SSL certificate key";
    };

    enableACME = mkOption {
      type = types.bool;
      default = false;
      description = "Enable ACME/Let's Encrypt certificate generation";
    };

    acmeEmail = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "admin@example.com";
      description = "Email for ACME registration";
    };
  };

  config = mkIf cfg.enable {
    # Enable Cockpit service
    services.cockpit = {
      enable = true;
      port = cfg.cockpitPort;
      settings = lib.mkForce {
        WebService =
          {
            Origins =
              if cfg.useSubdirectory
              then "${
                if cfg.enableSSL
                then "https"
                else "http"
              }://${cfg.domain} ${
                if cfg.enableSSL
                then "wss"
                else "ws"
              }://${cfg.domain}"
              else "${
                if cfg.enableSSL
                then "https"
                else "http"
              }://${cfg.domain} ${
                if cfg.enableSSL
                then "wss"
                else "ws"
              }://${cfg.domain}";
            ProtocolHeader = "X-Forwarded-Proto";
            AllowUnencrypted = cfg.allowUnencrypted;
          }
          // optionalAttrs cfg.useSubdirectory {
            UrlRoot = cfg.urlPath;
          };
      };
    };

    # Enable nginx
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = cfg.enableSSL;
      recommendedOptimisation = true;
      recommendedGzipSettings = false; # Gzip must be off for Cockpit

      virtualHosts."${cfg.domain}" = {
        forceSSL = mkIf cfg.enableSSL true;

        enableACME = cfg.enableACME;

        sslCertificate =
          if cfg.enableACME
          then null
          else cfg.sslCertificate;
        sslCertificateKey =
          if cfg.enableACME
          then null
          else cfg.sslCertificateKey;

        locations =
          if cfg.useSubdirectory
          then {
            "${cfg.urlPath}/" = {
              proxyPass = "${
                if cfg.allowUnencrypted
                then "http"
                else "https"
              }://${cfg.cockpitHost}:${toString cfg.cockpitPort}${cfg.urlPath}/";
              extraConfig = ''
                proxy_set_header Host $host;
                proxy_set_header X-Forwarded-Proto $scheme;

                # Required for web sockets
                proxy_http_version 1.1;
                proxy_buffering off;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";

                # Pass ETag header from Cockpit to clients
                gzip off;
              '';
            };
          }
          else {
            "/" = {
              proxyPass = "${
                if cfg.allowUnencrypted
                then "http"
                else "https"
              }://${cfg.cockpitHost}:${toString cfg.cockpitPort}";
              extraConfig = ''
                proxy_set_header Host $host;
                proxy_set_header X-Forwarded-Proto $scheme;

                # Required for web sockets
                proxy_http_version 1.1;
                proxy_buffering off;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";

                # Pass ETag header from Cockpit to clients
                gzip off;
              '';
            };
          };
      };
    };

    # ACME configuration if enabled
    security.acme = mkIf cfg.enableACME {
      acceptTerms = true;
      defaults.email = mkIf (cfg.acmeEmail != null) cfg.acmeEmail;
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [80] ++ optional cfg.enableSSL 443;

    # SELinux equivalent in NixOS (if using SELinux)
    # This allows nginx to connect to network services
    # Note: NixOS doesn't use SELinux by default, but if you enable it:
    # boot.kernelParams = [ "security=selinux" ];
  };
}
