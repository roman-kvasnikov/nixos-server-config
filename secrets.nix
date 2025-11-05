let
  homelabSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+APlAyYDiSgtzG2W8KmwWEWW33MdwXMUDxdTThW9Jm root@homelab";
in {
  "./secrets/server/admin-password.age".publicKeys = [homelabSshKey];

  "./secrets/acme/namecheap.env.age".publicKeys = [homelabSshKey];

  "./secrets/microbin/env.age".publicKeys = [homelabSshKey];

  "./secrets/onlyoffice/jwt-secret.age".publicKeys = [homelabSshKey];

  "./secrets/restic/env.age".publicKeys = [homelabSshKey];

  "./secrets/samba/romank-password.age".publicKeys = [homelabSshKey];

  "./secrets/samba/dssmargo-password.age".publicKeys = [homelabSshKey];

  "./secrets/xray/config.json.age".publicKeys = [homelabSshKey];
}
