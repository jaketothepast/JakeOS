{ config, lib, pkgs, inputs, ... }:
let
  blocklist = import ./blocklist.nix;

  # Null-route a list of domains (and their www.) on BOTH IPv4 and IPv6, so an
  # AAAA lookup can't reach the real host.
  blockHosts = domains:
    lib.concatMapStringsSep "\n"
      (d: "0.0.0.0 ${d}\n0.0.0.0 www.${d}\n:: ${d}\n:: www.${d}")
      domains;

  # Common groups for a non-privileged daily user (NOT wheel → cannot rebuild).
  dailyGroups = [ "networkmanager" "audio" "video" "input" ];
in
{
  # ===========================================================================
  #  Shared admin account — the ONLY account that can rebuild the system.
  #  This is the deliberate, high-friction (not impossible) "unblock" valve:
  #  to change a block you switch to admin, edit modules/nixos/blocklist.nix, rebuild.
  #  Password is read from /var/lib/adhd-secrets/admin.pw (created at install).
  # ===========================================================================
  users.users.admin = {
    isNormalUser = true;
    uid = 1000;
    description = "Administrator (rebuilds only — do not daily-drive)";
    extraGroups = [ "wheel" "networkmanager" ];
    hashedPasswordFile = "/var/lib/adhd-secrets/admin.pw";
  };
  nix.settings.trusted-users = [ "root" "admin" ];
  home-manager.users.admin = import ../../home/admin.nix;

  # sudo (and therefore nixos-rebuild) is restricted to wheel; daily users aren't
  # in wheel, so they cannot rebuild. This is intentional.
  security.sudo.execWheelOnly = true;

  # ===========================================================================
  #  WORK MODE  (boot entry: "work")
  # ===========================================================================
  specialisation.work.configuration = {
    system.nixos.tags = [ "work" ];

    users.users.jacob-work = {
      isNormalUser = true;
      uid = 1001;
      description = "Jacob — work";
      extraGroups = dailyGroups;
      hashedPasswordFile = "/var/lib/adhd-secrets/jacob-work.pw";
    };
    home-manager.users.jacob-work = import ../../home/jacob-work.nix;

    # Autologin straight into niri as the work user.
    services.greetd.settings.initial_session = {
      command = "niri-session";
      user = "jacob-work";
    };

    # Encrypted work volume, mounted DIRECTLY at the work user's home and unlocked
    # ONLY in this mode. All work data lives here → personal mode can't see it.
    # (Single passphrase across volumes; you just don't unlock this one in personal.)
    boot.initrd.luks.devices.cryptwork = {
      device = "/dev/disk/by-uuid/REPLACE-LUKS-CRYPTWORK-UUID";
      allowDiscards = true;
    };
    fileSystems."/home/jacob-work" = {
      device = "/dev/mapper/cryptwork";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" ];
    };

    # Block the time-sinks at the hosts layer (resolved applies this to CLIs too).
    networking.extraHosts = blockHosts blocklist.workBlocked;

    # Browser is default-deny in work mode; only the allow-list gets through.
    programs.firefox.policies.WebsiteFilter = {
      Block = [ "<all_urls>" ];
      Exceptions = blocklist.workAllowExceptions;
    };
  };

  # ===========================================================================
  #  PERSONAL MODE  (boot entry: "personal")
  # ===========================================================================
  specialisation.personal.configuration = {
    system.nixos.tags = [ "personal" ];

    users.users.jacob-personal = {
      isNormalUser = true;
      uid = 1002;
      description = "Jacob — personal";
      extraGroups = dailyGroups;
      hashedPasswordFile = "/var/lib/adhd-secrets/jacob-personal.pw";
    };
    home-manager.users.jacob-personal = import ../../home/jacob-personal.nix;

    services.greetd.settings.initial_session = {
      command = "niri-session";
      user = "jacob-personal";
    };

    boot.initrd.luks.devices.cryptpersonal = {
      device = "/dev/disk/by-uuid/REPLACE-LUKS-CRYPTPERSONAL-UUID";
      allowDiscards = true;
    };
    fileSystems."/home/jacob-personal" = {
      device = "/dev/mapper/cryptpersonal";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" ];
    };

    # Personal mode blocks work tooling/domains. No default-deny browser filter
    # here (relaxed personal browsing, minus the blocked hosts + uBlock).
    networking.extraHosts = blockHosts blocklist.personalBlocked;
  };
}
