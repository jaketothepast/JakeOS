# The Manual

How to use this machine, why it works the way it does, and how to fix it when it
breaks. Read sections 1–3 now; keep section 8 (Recovery) on your phone.

> **This is the simplified ("boring & reliable") build.** No impermanence, one
> disk passphrase, a stable channel, and a deliberately tiny daily surface. The
> goal: nothing to babysit, almost nothing new to learn beyond niri.

---

## 1. Why this exists

One rule: **the bypass must be slower than the impulse, and you must have chosen it
yourself.** Capturing a thought or starting work is one keypress. Reaching a
distraction takes an admin-only rebuild. That asymmetry is the design.

| Mechanism | Why | Evidence |
|---|---|---|
| **2-second global capture → one inbox** | ADHD is a working-memory disorder; external cues at the moment of need beat internal memory (Barkley). | **Strong** |
| **One daily dashboard (3 groups)** | Fewer "what's next / where do I look" decisions = less executive load. | Moderate |
| **Always-visible clock + org-clock** | Time-perception is measurably impaired in ADHD; make time external. | **Strong** (the deficit) |
| **Pomodoro (org-pomodoro)** | Time-boxing lowers task-initiation friction. Tune the length — don't worship 25 min. | Weak |
| **Hard blocks + locked browser + DND** | ADHD is hit harder by distractors; change the environment, don't rely on willpower. | Moderate–Strong |
| **Self-chosen hard block, admin-only escape** | Soft "resist later" decays into procrastination; a precommitment *you authored* sticks. The escape is costly-but-possible (admin rebuild), not impossible. | Moderate + strong autonomy |
| **Work / personal modes** | Task-switching is expensive in ADHD; isolated modes batch contexts and keep work out of downtime. | Moderate |

---

## 2. The daily loop

1. **Capture all day.** Thought / task / urge → `Mod+N` → type → `C-c C-c`. ~2s, the
   frame closes, you're back. It lands in `~/org/inbox.org`. **No menu** — it goes
   straight to a quick task; sort it later.
2. **Process the inbox 1–2×/day.** Open the dashboard (`SPC SPC a d`, also auto-opens
   at login), clear **"Refile me (inbox)"**: each item → `NEXT`, refiled (`SPC m r`),
   or deleted.
3. **Work from the dashboard.** Pick a `NEXT`. There's one list.
4. **Focus block.** `Mod+Shift+F` (DND on). Clock in: `SPC m c i`. The bar shows the
   task + elapsed time. `Mod+Shift+F` again to come back.
5. **Review.** Glance at the dashboard, capture loose ends, done.

---

## 3. The two modes

Boot-selectable and **isolated in daily use** — separate Linux users; the work and
personal homes are **mount-isolated btrfs subvolumes inside one LUKS** (not
cryptographically separated — `root`/`admin` could mount either). Personal mode never
mounts the work home and never installs work apps, and your daily user isn't `root`,
so it can't reach the other mode's home.

| | **work** | **personal** |
|---|---|---|
| User | `jacob-work` | `jacob-personal` |
| Apps | Slack, dev toolchain | Discord, mpv |
| Blocked | Reddit, LinkedIn, Discord, YouTube, X, HN | Slack + your work domains |
| Browser | default-deny allowlist (only work domains) | relaxed (minus blocked hosts) |
| Home | `@home-work` subvol → `/home/jacob-work` | `@home-personal` subvol → `/home/jacob-personal` |

**Switching modes = reboot** → pick the entry in the boot menu → type the disk
passphrase (one LUKS for the whole system). Each mode only *mounts* its own home
subvolume; the daily user isn't root, so it can't reach the other mode's home. The
reboot is deliberate friction so you don't hop into "personal" mid-workday.

The **plain (untagged) boot entry** is the **admin recovery** entry.

---

## 4. niri — the windows (this answers "how do I switch?")

niri tiles **windows side-by-side in a horizontal row**; **workspaces** stack as
separate screens. You're never hunting overlapping windows.

- **Switch between open windows** (editor ↔ browser): `Mod+←` / `Mod+→`.
- **See everything at once** (bird's-eye zoom-out): `Mod+O` (overview).
- **Workspaces** = fixed homes for tasks (e.g. 1 = code, 2 = comms): `Mod+1/2/3`.
  Send the current window to one: `Mod+Shift+1/2/3`.
- **Maximize / restore** the current window: `Mod+F`.
- New windows open full-width on purpose (monotasking) — `Mod+←/→` is how you move
  off one.

Forgot a key? `Mod+Shift+/` shows the full overlay.

---

## 5. Capture & org

- **Capture:** `Mod+N` anywhere → straight to a quick task (no menu). For a
  deliberate note, in Emacs use `SPC X` and pick `n`.
- **Dashboard:** `SPC SPC a d`. Three groups: **Today** (scheduled/due) /
  **Overdue** / **Refile-inbox** + **NEXT**. Empty groups hide themselves.
- **org-roam dailies & notes** (kept out of the agenda):
  `SPC n j` today's daily · `SPC n r f/i/r` find / insert / backlinks.
- Files: `~/org/inbox.org`, `~/org/projects.org`, `~/org/roam/` — on the current
  mode's encrypted home volume.

---

## 6. Focus & time

- **DND:** notifications start paused (batched). `Mod+Shift+F` toggles; check the
  batch deliberately a couple times a day.
- **Clock:** always in the bar (date + time) — your anti-time-blindness anchor; the
  bar also shows the currently-clocked task.
- **Pomodoro:** Doom's `org-pomodoro` (`SPC m c` area) auto-clocks the task. Length
  lives in `doom/config.el` — change it if 25 min doesn't fit you.

---

## 7. What's blocked & how to unblock

**Why the blocks are actually hard** (not "just edit the hosts file"):
- `/etc/hosts` is generated from Nix — a read-only `/nix/store` symlink, regenerated
  every boot. Your daily user isn't in `wheel` and has no `sudo`, so **you cannot
  edit it.**
- `systemd-resolved` reads `/etc/hosts`, so blocked domains answer `0.0.0.0` for the
  browser *and* normal CLIs (`curl reddit.com` fails).
- An nftables rule forces all DNS to the local resolver and blocks DoH/DoT, so even
  `dig @8.8.8.8 reddit.com` or a DoH client can't dodge it.
- Your AI agents / CLIs / npm / pip still have full network access — they resolve via
  the local resolver and connect to any IP. Only *direct external DNS from a
  non-resolver process* is blocked.

**To unblock something (the only path — by design):**
```sh
# 1. Log out, log in as `admin` (the only account in `wheel`).
# 2. Edit ONE list file:
$EDITOR modules/nixos/blocklist.nix      # add/remove a quoted domain
# 3. Rebuild:
sudo nixos-rebuild switch --flake .#adhd-desktop
# 4. Log back into your daily user.
```
That friction is the feature. Unblocking the same site repeatedly? **Change the
list** — don't fight yourself.

---

## 8. Recovery runbook (keep on your phone)

**A rebuild broke the desktop:**
- Reboot → in the **systemd-boot menu** pick an **older generation** (last ten are
  kept). Older = last known good. (Daily users can't `--rollback` from a terminal —
  use the boot menu, or boot the untagged admin entry and fix it as `admin`.)

**Won't boot at all:**
1. Boot a NixOS live USB.
2. `cryptsetup open /dev/<part> cryptroot`, mount `@root` + `@nix`, `nixos-enter`.
3. Fix the flake / roll back, `nixos-rebuild boot`.

**Your data:** the root is **persistent now** — files survive reboots (no
impermanence). Your home lives on the encrypted mode volume
(`/home/jacob-work` or `/home/jacob-personal`).

---

## 9. Cheat-sheet

**niri (Mod = Super):**

| Key | Action |
|---|---|
| `Mod+N` | **Capture** (quick task) |
| `Mod+Return` | Terminal |
| `Mod+D` | Launcher |
| `Mod+Q` | Close window |
| `Mod+Shift+F` | Focus on/off (DND) |
| `Mod+←` / `Mod+→` | Previous / next window |
| `Mod+O` | Overview (see everything) |
| `Mod+F` | Maximize / restore window |
| `Mod+1/2/3` | Switch workspace |
| `Mod+Shift+1/2/3` | Send window to workspace |
| `Mod+Shift+/` | Hotkey overlay |
| `Mod+Shift+E` | Log out of niri |

**Doom / org:**

| Key | Action |
|---|---|
| `SPC SPC a d` | Daily dashboard |
| `SPC X` | Capture (menu: task / note) |
| `SPC n j` | Today's roam daily |
| `SPC n r f/i/r` | Roam find / insert / backlinks |
| `SPC m r` | Refile |
| `SPC m c i / o` | Clock in / out |
| `SPC t z` | Zen mode |

**Rebuild (admin only):** `sudo nixos-rebuild switch --flake .#adhd-desktop`

---

## 10. Install (first time)

> **Full copy-pasteable walkthrough: [`docs/INSTALL.md`](INSTALL.md).** Partitioning
> is declarative (disko) — no manual fdisk/cryptsetup/UUIDs. The summary:

1. Boot the NixOS ISO, get online, `git clone` this repo.
2. Set your disk in `modules/nixos/disko.nix` (`device = "/dev/…"`).
3. `echo -n 'passphrase' > /tmp/secret.key`, then
   `sudo nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#adhd-desktop`
   (partitions + formats + mounts to `/mnt`).
4. `cp -r` the repo to `/mnt/etc/nixos`; create the `mkpasswd` hash files in
   `/mnt/var/lib/adhd-secrets/`.
5. `nixos-install --flake /mnt/etc/nixos#adhd-desktop --no-root-passwd`, reboot, pick
   a mode. First login runs `doom-sync` — give it a few minutes.

> Reproducibility: commit a `flake.lock` (`nix flake lock`) so "stable 25.11" is
> pinned to exact revisions.
