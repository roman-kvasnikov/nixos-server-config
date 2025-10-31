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

      postgresql-nextcloud-password = {
        file = ../../secrets/postgresql/nextcloud-password.age;
        owner = "root";
        mode = "0600";
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
    };
  };
}
