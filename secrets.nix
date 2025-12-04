let
  homelabSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+APlAyYDiSgtzG2W8KmwWEWW33MdwXMUDxdTThW9Jm root@homelab";
in {
  "./secrets/admin.password.age".publicKeys = [homelabSshKey];
  "./secrets/linkwarden.env.age".publicKeys = [homelabSshKey];
  "./secrets/microbin.env.age".publicKeys = [homelabSshKey];
  "./secrets/namecheap.env.age".publicKeys = [homelabSshKey];
  "./secrets/onlyoffice.jwt-secret.age".publicKeys = [homelabSshKey];
  "./secrets/pihole.env.age".publicKeys = [homelabSshKey];
  "./secrets/restic.password.age".publicKeys = [homelabSshKey];
  "./secrets/s3.env.age".publicKeys = [homelabSshKey];
  "./secrets/samba.env.age".publicKeys = [homelabSshKey];
  "./secrets/vaultwarden.env.age".publicKeys = [homelabSshKey];
  "./secrets/pgadmin.password.age".publicKeys = [homelabSshKey];
  "./secrets/ups.password.age".publicKeys = [homelabSshKey];
  "./secrets/xray.config.json.age".publicKeys = [homelabSshKey];
}
