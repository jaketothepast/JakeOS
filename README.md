# nixos-adhd-config

An ADHD-friendly NixOS workstation: **hard to do the wrong thing, easy to do the right thing.**

Built around a single principle — *the bypass must be slower than the impulse, and self-authored.*
Capturing a thought or starting work is one keypress; reaching a distraction (or
mixing work into downtime) takes a reboot and an admin-only `nixos-rebuild`.

> **Read [`docs/MANUAL.md`](docs/MANUAL.md) first.** It explains the daily loop,
> the two modes, how to unblock something, and the recovery runbook. The research
> basis for every mechanism is documented there.

## What's here

| Path | What it is |
|------|------------|
| `flake.nix` | Inputs + the `adhd-desktop` system |
| `hosts/adhd-desktop/` | Host entry + (placeholder) hardware config |
| `modules/nixos/` | System modules: base, boot, desktop (niri+X), enforcement, modes, ollama |
| `modules/nixos/blocklist.nix` | The one list you edit (as admin) to block/unblock sites |
| `modules/home-manager/` | User dotfiles: shared + per-mode (work/personal) |
| `home/` | Per-user home-manager entrypoints |
| `doom/` | Doom Emacs config (close to stock; org + org-roam dailies) |
| `pkgs/pi.nix` | `pi` AI coding agent (npm) packaged for Nix |
| `docs/MANUAL.md` | **The user manual** |

## Two modes

Boot-selectable, strictly isolated (separate users + separate LUKS-encrypted home
volumes). Switching = reboot → pick the boot entry → disk passphrase.

- **work** — dev tooling, Slack; Discord / Reddit / LinkedIn blocked; default-deny browser allowlist.
- **personal** — Discord; Slack and work data absent (work volume not mounted); relaxed.

## Quick start (fresh machine)

See `docs/MANUAL.md → Install`. In short: partition (btrfs subvols + LUKS),
`nixos-generate-config`, merge into `hosts/adhd-desktop/hardware-configuration.nix`,
then `nixos-install --flake .#adhd-desktop`.

## Building changes (the "unblock" path)

Only the `admin` user can rebuild — by design:

```sh
# as admin
cd /etc/nixos        # (or wherever this repo lives)
$EDITOR modules/nixos/blocklist.nix   # add/remove a domain
sudo nixos-rebuild switch --flake .#adhd-desktop
```
