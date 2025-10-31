# Enhanced Nextcloud configuration with proper Nginx settings for NixOS
# Based on official Nextcloud Nginx recommendations
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.nextcloudctl;
  cfgHomelab = config.homelab;
  cfgAcme = config.services.acmectl;
  cfgNginx = config.services.nginxctl;
in {
  options.homelab.services.nextcloudctl = {
    enable = lib.mkEnableOption "Enable Nextcloud";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Host of the Nextcloud module";
      default = "nextcloud.${cfgHomelab.domain}";
    };

    homeDir = lib.mkOption {
      type = lib.types.path;
      description = "Home directory for Nextcloud";
      default = "/var/lib/nextcloud";
    };

    adminUser = lib.mkOption {
      type = lib.types.str;
      description = "Admin user for Nextcloud";
    };

    adminPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "Admin password file for Nextcloud";
    };

    apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of Nextcloud apps to enable";
      default = ["bookmarks" "calendar" "contacts" "notes" "mail" "onlyoffice" "groupfolders"];
    };

    logFile = lib.mkOption {
      type = lib.types.path;
      description = "Log file for Nextcloud";
      default = "/var/lib/nextcloud/data/nextcloud.log";
    };

    # Database configuration options
    database = {
      type = lib.mkOption {
        type = lib.types.enum ["sqlite" "postgresql" "mysql"];
        default = "postgresql";
        description = "Database type to use";
      };

      passwordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Database password file (if using postgresql/mysql)";
      };
    };

    # Performance tuning options
    performance = {
      maxUploadSize = lib.mkOption {
        type = lib.types.str;
        default = "16G";
        description = "Maximum upload size";
      };

      phpMemoryLimit = lib.mkOption {
        type = lib.types.str;
        default = "512M";
        description = "PHP memory limit";
      };

      opcacheMemory = lib.mkOption {
        type = lib.types.int;
        default = 128;
        description = "OPcache memory consumption in MB";
      };
    };

    homepage = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Nextcloud";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Enterprise File Storage and Collaboration";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "nextcloud.svg";
      };
      category = lib.mkOption {
        type = lib.types.str;
        default = "Clouds";
      };
      widget = lib.mkOption {
        type = lib.types.attrs;
        default = {
          type = "nextcloud";
          url = "https://${cfg.host}";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services = {
        nextcloud = {
          enable = true;
          package = pkgs.nextcloud32;

          hostName = cfg.host;
          home = cfg.homeDir;
          https = true;

          extraApps = lib.genAttrs cfg.apps (app: config.services.nextcloud.package.packages.apps.${app});
          extraAppsEnable = true;
          autoUpdateApps.enable = true;

          maxUploadSize = cfg.performance.maxUploadSize;

          # Redis caching for better performance
          caching.redis = true;
          configureRedis = true;

          # Database configuration
          database.createLocally = cfg.database.type != "sqlite";

          config =
            {
              adminuser = cfg.adminUser;
              adminpassFile = cfg.adminPasswordFile;
            }
            // (
              if cfg.database.type == "sqlite"
              then {
                dbtype = "sqlite";
              }
              else if cfg.database.type == "postgresql"
              then {
                dbtype = "pgsql";
                dbname = "nextcloud";
                dbuser = "nextcloud";
                dbpassFile = cfg.database.passwordFile;
                dbhost = "/run/postgresql";
              }
              else {
                dbtype = "mysql";
                dbname = "nextcloud";
                dbuser = "nextcloud";
                dbpassFile = cfg.database.passwordFile;
                dbhost = "localhost";
              }
            );

          # PHP OPcache configuration
          phpOptions = {
            "opcache.enable" = "1";
            "opcache.interned_strings_buffer" = "16";
            "opcache.max_accelerated_files" = "10000";
            "opcache.memory_consumption" = toString cfg.performance.opcacheMemory;
            "opcache.save_comments" = "1";
            "opcache.revalidate_freq" = "60";
            "opcache.jit" = "1255";
            "opcache.jit_buffer_size" = "128M";
            "memory_limit" = cfg.performance.phpMemoryLimit;
            "upload_max_filesize" = cfg.performance.maxUploadSize;
            "post_max_size" = cfg.performance.maxUploadSize;
            "max_execution_time" = "3600";
            "max_input_time" = "3600";
          };

          settings = {
            trusted_domains = [
              "localhost"
              "127.0.0.1"
              "172.20.0.0/16"
              "192.168.1.0/24"
              cfg.host
            ];

            overwriteprotocol = "https";
            overwritehost = cfg.host;

            default_phone_region = "RU";
            "profile.enabled" = true;

            # Logging configuration
            loglevel = 2;
            log_type = "file";
            logfile = cfg.logFile;

            # Performance and security settings
            "memcache.local" = "\\OC\\Memcache\\APCu";
            "memcache.distributed" = "\\OC\\Memcache\\Redis";
            "memcache.locking" = "\\OC\\Memcache\\Redis";

            # File locking
            "filelocking.enabled" = true;

            # Preview generation settings
            "preview_max_x" = 2048;
            "preview_max_y" = 2048;
            "jpeg_quality" = 60;

            # Security hardening
            "auth.bruteforce.protection.enabled" = true;
            "ratelimit.protection.enabled" = true;
          };
        };

        # PostgreSQL configuration (if selected)
        postgresql = lib.mkIf (cfg.database.type == "postgresql") {
          enable = true;
          ensureDatabases = ["nextcloud"];
          ensureUsers = [
            {
              name = "nextcloud";
              ensureDBOwnership = true;
            }
          ];
        };

        # MySQL configuration (if selected)
        mysql = lib.mkIf (cfg.database.type == "mysql") {
          enable = true;
          package = pkgs.mariadb;
          ensureDatabases = ["nextcloud"];
          ensureUsers = [
            {
              name = "nextcloud";
              ensurePermissions = {
                "nextcloud.*" = "ALL PRIVILEGES";
              };
            }
          ];
        };

        # Enhanced Nginx configuration based on official recommendations
        nginx = lib.mkIf cfgNginx.enable {
          enable = true;

          # Global Nginx optimizations
          recommendedGzipSettings = true;
          recommendedOptimisation = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = true;

          # Client body size for large uploads
          clientMaxBodySize = cfg.performance.maxUploadSize;

          virtualHosts."${cfg.host}" = {
            enableACME = cfgAcme.enable;
            forceSSL = cfgAcme.enable;

            # HTTP/2 support
            http2 = true;

            # Security headers based on official recommendations
            extraConfig = ''
              # Security headers
              add_header Referrer-Policy                   "no-referrer"                                  always;
              add_header X-Content-Type-Options            "nosniff"                                      always;
              add_header X-Download-Options                "noopen"                                       always;
              add_header X-Frame-Options                   "SAMEORIGIN"                                   always;
              add_header X-Permitted-Cross-Domain-Policies "none"                                         always;
              add_header X-Robots-Tag                      "noindex, nofollow"                            always;
              add_header X-XSS-Protection                  "1; mode=block"                                always;

              # HSTS header (uncomment after testing)
              # add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;

              # Remove X-Powered-By header
              more_clear_headers 'X-Powered-By';

              # FastCGI cache configuration
              fastcgi_cache_key "$scheme$request_method$host$request_uri";
              fastcgi_cache_use_stale error timeout updating invalid_header http_500 http_503;
              fastcgi_cache_lock on;
              fastcgi_cache_valid 60m;

              # Gzip settings
              gzip on;
              gzip_vary on;
              gzip_comp_level 4;
              gzip_min_length 256;
              gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
              gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

              # Client body buffer size
              client_body_buffer_size 512k;

              # Proxy timeouts for long operations
              proxy_connect_timeout 600s;
              proxy_send_timeout 600s;
              proxy_read_timeout 600s;
              fastcgi_send_timeout 600s;
              fastcgi_read_timeout 600s;
            '';

            locations = {
              # Root location
              "/" = {
                priority = 999;
                extraConfig = ''
                  rewrite ^ /index.php;
                '';
              };

              # Robots.txt
              "= /robots.txt" = {
                priority = 100;
                extraConfig = ''
                  allow all;
                  log_not_found off;
                  access_log off;
                '';
              };

              # Well-known URLs for CalDAV and CardDAV
              "= /.well-known/carddav" = {
                priority = 210;
                extraConfig = ''
                  return 301 $scheme://$host/remote.php/dav;
                '';
              };

              "= /.well-known/caldav" = {
                priority = 210;
                extraConfig = ''
                  return 301 $scheme://$host/remote.php/dav;
                '';
              };

              # Microsoft DAV clients
              "^~ /.well-known" = {
                priority = 210;
                extraConfig = ''
                  location = /.well-known/carddav   { return 301 $scheme://$host/remote.php/dav; }
                  location = /.well-known/caldav    { return 301 $scheme://$host/remote.php/dav; }

                  # Webfinger and NodeInfo
                  location = /.well-known/webfinger { return 301 $scheme://$host/index.php/.well-known/webfinger; }
                  location = /.well-known/nodeinfo  { return 301 $scheme://$host/index.php/.well-known/nodeinfo; }

                  # Let Nextcloud handle other well-known URLs
                  try_files $uri $uri/ =404;
                '';
              };

              # Static assets with aggressive caching
              "~ \\.(?:css|js|mjs|svg|gif|png|jpg|ico|wasm|tflite|map|ogg|flac)$" = {
                priority = 300;
                extraConfig = ''
                  try_files $uri /index.php$request_uri;
                  add_header Cache-Control "public, max-age=15778463, immutable";
                  access_log off;

                  # Security headers for static content
                  add_header Referrer-Policy                   "no-referrer"        always;
                  add_header X-Content-Type-Options            "nosniff"            always;
                  add_header X-Download-Options                "noopen"             always;
                  add_header X-Frame-Options                   "SAMEORIGIN"         always;
                  add_header X-Permitted-Cross-Domain-Policies "none"               always;
                  add_header X-Robots-Tag                      "noindex, nofollow"  always;
                  add_header X-XSS-Protection                  "1; mode=block"      always;
                '';
              };

              # WebAssembly files
              "~ \\.wasm$" = {
                priority = 300;
                extraConfig = ''
                  default_type application/wasm;
                  try_files $uri /index.php$request_uri;
                  add_header Cache-Control "public, max-age=15778463, immutable";
                  access_log off;
                '';
              };

              # Media files
              "~ \\.(?:mp4|webm|mp3|ogg|flac|wav|aac|m4a)$" = {
                priority = 300;
                extraConfig = ''
                  try_files $uri /index.php$request_uri;
                  add_header Cache-Control "public, max-age=7776000";
                  access_log off;
                '';
              };

              # Office documents and other binary files
              "~ \\.(?:doc|docx|xls|xlsx|ppt|pptx|odt|ods|odp|pdf|zip|tar|gz|rar|7z)$" = {
                priority = 300;
                extraConfig = ''
                  try_files $uri /index.php$request_uri;
                  add_header Cache-Control "public, max-age=3600";
                  access_log off;
                '';
              };
            };
          };
        };

        # Fail2ban configuration
        fail2ban = {
          enable = true;

          jails.nextcloud = {
            enabled = true;
            settings = {
              backend = "auto";
              port = "80,443";
              protocol = "tcp";
              filter = "nextcloud";
              maxretry = 5;
              bantime = 3600;
              findtime = 600;
              logpath = cfg.logFile;
            };
          };
        };
      };

      # Fail2ban filter configuration
      environment.etc."fail2ban/filter.d/nextcloud.conf".text = ''
        [Definition]
        _groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
        failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
                    ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
                    ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":".*Bruteforce attempt from IP detected
        datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
      '';

      # System optimizations
      systemd.services = {
        nextcloud-setup = {
          after = ["postgresql.service" "mysql.service" "redis.service"];
          requires =
            lib.optional (cfg.database.type == "postgresql") "postgresql.service"
            ++ lib.optional (cfg.database.type == "mysql") "mysql.service";
        };

        # Nextcloud background jobs
        nextcloud-cron = {
          startAt = "*:0/5";
        };

        # Nextcloud preview generator (optional)
        nextcloud-preview-generator = {
          description = "Nextcloud preview generator";
          after = ["nextcloud-setup.service"];
          serviceConfig = {
            Type = "oneshot";
            User = "nextcloud";
            ExecStart = "${config.services.nextcloud.occ}/bin/nextcloud-occ preview:pre-generate";
          };
        };
      };

      # Systemd timers
      systemd.timers.nextcloud-preview-generator = {
        description = "Timer for Nextcloud preview generator";
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
        wantedBy = ["timers.target"];
      };

      # Firewall rules
      networking.firewall = lib.mkIf cfgHomelab.openFirewall {
        allowedTCPPorts = [80 443];
      };
    })

    # ACME certificate configuration
    (lib.mkIf (cfg.enable && cfgAcme.enable) {
      security.acme.certs."${cfg.host}" =
        cfgAcme.commonCertOptions
        // {
          postRun = "systemctl reload nginx.service";
        };
    })
  ];
}
