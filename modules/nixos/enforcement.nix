{ config, lib, pkgs, ... }:
{
  # ===========================================================================
  #  ENFORCEMENT — baseline, always-on (both modes). Per-mode deltas live in
  #  modes.nix (extraHosts + Firefox WebsiteFilter). Network model:
  #    * Egress is default-OPEN  → CLIs / AI agents / dev tooling reach anything.
  #    * The BROWSER is the locked-down vector (Firefox policy + WebsiteFilter).
  #    * DNS blocking (hosts + AdGuard) covers everything, browser and CLI alike.
  #    * nftables ONLY prevents DNS bypass (DoH/DoT) — it does NOT domain-filter.
  # ===========================================================================

  # ---- /etc/hosts baseline blocklist (StevenBlack) --------------------------
  networking.stevenblack = {
    enable = true;
    block = [ "fakenews" "gambling" "porn" "social" ];
  };

  # ===========================================================================
  #  AdGuard Home as the single system resolver.
  # ===========================================================================
  # Free port 53 for AdGuard by turning off resolved's stub listener.
  services.resolved.enable = false;
  networking.nameservers = [ "127.0.0.1" ];
  networking.networkmanager.dns = "none"; # NM must not overwrite resolv.conf

  services.adguardhome = {
    enable = true;
    # Declared config is authoritative — UI tweaks don't silently override it,
    # and they don't survive a reboot. This is intentional (no soft escape).
    mutableSettings = false;
    # Web UI bind (the module injects these into http.address).
    host = "127.0.0.1";
    port = 3000;
    settings = {
      dns = {
        bind_hosts = [ "127.0.0.1" ];
        port = 53;
        # AdGuard's own upstream is allow-listed in nftables (by destination IP),
        # so plain-DNS upstream works even though everything else is forced to :53.
        upstream_dns = [ "9.9.9.9" "1.1.1.1" ];
        bootstrap_dns = [ "9.9.9.9" "1.1.1.1" ];
      };
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        # NOTE: the DoH "canary" (use-application-dns.net) is intentionally NOT
        # handled here — the locked Firefox `DNSOverHTTPS { Locked = true; }`
        # policy below is the real control, so a rewrite would be redundant.
      };
      # Ad/tracker/malware lists. Social/time-sink blocking is per-mode via hosts.
      filters = [
        {
          enabled = true;
          name = "AdGuard DNS filter";
          id = 1;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
        }
        {
          enabled = true;
          name = "AdAway";
          id = 2;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
        }
      ];
    };
  };

  # ===========================================================================
  #  nftables — anti-DNS-bypass ONLY (kill DoH/DoT, force plain DNS to AdGuard).
  #  Does NOT filter by domain (IPs churn) and does NOT restrict CLI egress.
  # ===========================================================================
  networking.nftables = {
    enable = true;
    tables.dns_lockdown = {
      family = "inet";
      content = ''
        # Seed of well-known DoH provider IPs. Expand via a timer that pulls
        # github.com/dibdot/DoH-IP-blocklists into these sets (see MANUAL).
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

        chain output {
          type filter hook output priority 0; policy accept;

          # Allow AdGuard's plain-DNS upstreams (it forwards here). Matching by
          # destination IP avoids depending on the service's (possibly dynamic)
          # uid name. DoH/DoT to these same IPs is still rejected below.
          ip daddr { 9.9.9.9, 1.1.1.1 } udp dport 53 accept
          ip daddr { 9.9.9.9, 1.1.1.1 } tcp dport 53 accept

          # No DNS-over-TLS anywhere.
          tcp dport 853 reject

          # No DNS-over-HTTPS to known resolvers.
          ip daddr @doh4 tcp dport 443 reject

          # Any other plain DNS must go to the local AdGuard resolver (IPv4 + IPv6).
          udp dport 53 ip daddr != 127.0.0.1 reject
          tcp dport 53 ip daddr != 127.0.0.1 reject
          udp dport 53 ip6 daddr != ::1 reject
          tcp dport 53 ip6 daddr != ::1 reject
          # (IPv6 DoH to brand-new endpoints remains a known gap — expand doh sets
          #  with an ip6 set from dibdot/DoH-IP-blocklists if you want to close it.)
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
      # Kill DoH so the browser can't bypass the hosts/AdGuard layer.
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
