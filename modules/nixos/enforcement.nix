{ config, lib, pkgs, ... }:
{
  # ===========================================================================
  #  ENFORCEMENT — baseline, always-on (both modes). Per-mode host/allow deltas
  #  live in modes.nix. Network model:
  #    * Egress is default-OPEN  → CLIs / AI agents / dev tooling reach anything.
  #    * Domain blocking = /etc/hosts, applied to EVERYTHING by systemd-resolved
  #      (and libc nss) — browser and CLI alike. Immutable: /etc/hosts is a
  #      read-only store symlink and the daily user isn't in `wheel`.
  #    * The browser (main distraction vector) is further locked via Firefox policy.
  #    * A slim nftables rule forces all DNS to the local resolver and kills
  #      DoH/DoT, so terminal alternate-resolver tricks (dig @8.8.8.8, DoH) fail.
  # ===========================================================================

  # ---- /etc/hosts baseline blocklist (StevenBlack) --------------------------
  networking.stevenblack = {
    enable = true;
    block = [ "fakenews" "gambling" "porn" "social" ];
  };

  # ---- Local resolver: systemd-resolved reads /etc/hosts and answers 0.0.0.0
  #      for blocked domains, for every app that uses it.
  services.resolved.enable = true;

  # ===========================================================================
  #  nftables — DNS lockdown ONLY (no domain filtering, no CLI egress limits).
  #  Forces plaintext DNS to the local resolver; blocks DoH/DoT.
  # ===========================================================================
  networking.nftables = {
    enable = true;
    # The ruleset references `meta skuid "systemd-resolve"`, but the build sandbox
    # has no such user, so the build-time `nft -c` check fails. The user exists at
    # runtime, so skip the build check and let it load live.
    checkRuleset = false;
    tables.dns_lockdown = {
      family = "inet";
      content = ''
        # Well-known DoH provider IPs (v4 + v6). (Optionally expand from
        # github.com/dibdot/DoH-IP-blocklists via a timer.)
        set doh4 {
          type ipv4_addr
          flags interval
          elements = {
            1.1.1.1, 1.0.0.1,
            8.8.8.8, 8.8.4.4,
            9.9.9.9, 149.112.112.112,
            94.140.14.14, 94.140.15.15
          }
        }
        set doh6 {
          type ipv6_addr
          flags interval
          elements = {
            2606:4700:4700::1111, 2606:4700:4700::1001,
            2001:4860:4860::8888, 2001:4860:4860::8844,
            2620:fe::fe, 2620:fe::9,
            2a10:50c0::ad1:ff, 2a10:50c0::ad2:ff
          }
        }

        chain output {
          type filter hook output priority 0; policy accept;

          # systemd-resolved's own upstream queries are allowed (static user).
          meta skuid "systemd-resolve" accept

          # No DNS-over-TLS.
          tcp dport 853 reject

          # No DNS-over-HTTPS to known resolvers (TCP/443 and HTTP/3 over UDP/443,
          # IPv4 and IPv6).
          ip  daddr @doh4 tcp dport 443 reject
          ip  daddr @doh4 udp dport 443 reject
          ip6 daddr @doh6 tcp dport 443 reject
          ip6 daddr @doh6 udp dport 443 reject

          # All other plaintext DNS must stay on the local resolver (loopback).
          udp dport 53 ip daddr != 127.0.0.0/8 reject
          tcp dport 53 ip daddr != 127.0.0.0/8 reject
          udp dport 53 ip6 daddr != ::1 reject
          tcp dport 53 ip6 daddr != ::1 reject
        }
      '';
    };
  };

  # ===========================================================================
  #  Firefox — managed/locked policies (cannot be undone in the UI).
  #  The per-mode default-deny WebsiteFilter is added in modes.nix (work only).
  # ===========================================================================
  programs.firefox = {
    enable = true;
    policies = {
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = false;
      FirefoxSuggest = {
        WebSuggestions = false;
        SponsoredSuggestions = false;
        ImproveSuggest = false;
      };
      # Kill DoH so the browser can't bypass the /etc/hosts layer.
      DNSOverHTTPS = {
        Enabled = false;
        Locked = true;
      };
      Homepage = {
        StartPage = "homepage";
        URL = "about:blank";
        Locked = true;
      };
      ExtensionSettings = {
        # uBlock Origin — force-installed, cannot be removed.
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        # LeechBlock NG — confirm the exact extension id from about:debugging on
        # first run, then uncomment to force-install + lock it too.
        # "leechblockng@proginosko" = {
        #   installation_mode = "force_installed";
        #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/leechblock-ng/latest.xpi";
        # };
      };
      Preferences = {
        "network.trr.mode" = { Value = 5; Status = "locked"; };          # TRR/DoH off
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = { Value = false; Status = "locked"; };
        "browser.newtabpage.activity-stream.feeds.section.topstories" = { Value = false; Status = "locked"; };
      };
    };
  };
}
