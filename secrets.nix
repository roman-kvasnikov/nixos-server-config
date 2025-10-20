let
  homelabSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP+APlAyYDiSgtzG2W8KmwWEWW33MdwXMUDxdTThW9Jm root@homelab";
in {
  "./secrets/samba/romank-password.age".publicKeys = [homelabSshKey];
  "./secrets/samba/dssmargo-password.age".publicKeys = [homelabSshKey];
}
