{inputs, ...}: {
  imports = [
    inputs.agenix.nixosModules.default
  ];

  age = {
    identityPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
    ];

    secrets = {
      server-admin-password = {
        file = ../../secrets/server/admin-password.age;
        owner = "root";
        mode = "0600";
      };

      acme-namecheap-env = {
        file = ../../secrets/acme/namecheap.env.age;
        owner = "root";
        mode = "0600";
      };

      onlyoffice-jwt-secret = {
        file = ../../secrets/onlyoffice/jwt-secret.age;
        owner = "onlyoffice";
        group = "onlyoffice";
        mode = "0400";
      };

      restic-env = {
        file = ../../secrets/restic/env.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };

      samba-romank-password = {
        file = ../../secrets/samba/romank-password.age;
        owner = "root";
        mode = "0600";
      };

      samba-dssmargo-password = {
        file = ../../secrets/samba/dssmargo-password.age;
        owner = "root";
        mode = "0600";
      };

      xray-config-json = {
        file = ../../secrets/xray/config.json.age;
        owner = "root";
        mode = "0600";
      };
    };
  };
}
