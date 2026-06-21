###############################################################################
#  Declarative disk layout (disko). This REPLACES manual partitioning:
#  `disko` reads this and does the partition + LUKS + btrfs + mount for you.
#
#  ONE LUKS container (cryptroot) holds everything as btrfs subvolumes:
#     @root          -> /        (system, persistent)
#     @nix           -> /nix
#     @home-work     -> /home/jacob-work     (mounted only in work mode)
#     @home-personal -> /home/jacob-personal (mounted only in personal mode)
#
#  The two home subvolumes are CREATED here but NOT globally mounted — each is
#  mounted inside its specialisation in modes.nix, so personal mode never has the
#  work home on a filesystem path (daily users aren't root → can't mount it).
###############################################################################
{ lib, ... }:
{
  disko.devices.disk.main = {
    # >>> SET THIS to your real disk (lsblk). e.g. /dev/nvme0n1 or /dev/sda <<<
    device = lib.mkDefault "/dev/nvme0n1";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        cryptroot = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            # At install, write your passphrase to this file first:
            #   echo -n 'your-passphrase' > /tmp/secret.key
            passwordFile = "/tmp/secret.key";
            content = {
              type = "btrfs";
              extraArgs = [ "-L" "nixos" ];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                # Created by disko; mounted per-mode in modes.nix (no mountpoint here).
                "@home-work" = { };
                "@home-personal" = { };
              };
            };
          };
        };
      };
    };
  };
}
