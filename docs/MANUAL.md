# The Manual

How to use this machine, why it works the way it does, and how to fix it when it
breaks. Read sections 1–3 now; keep section 8 (Recovery) on your phone.

---

## 1. Why this exists

This computer is built on one rule: **the bypass must be slower than the impulse,
and you must have chosen it yourself.** Capturing a thought or starting work is one
keypress. Reaching a distraction — or mixing work into your downtime — takes a
reboot and an admin-only rebuild. That asymmetry is the whole design.

Every mechanism here is tied to ADHD research. Honest grading — some of this is
strongly evidenced, some is a low-cost nudge. Don't oversell the nudges to yourself.

| Mechanism | Why | Evidence |
|---|---|---|
| **2-second global capture → one inbox** | ADHD is a working-memory/executive-function disorder; external cues at the point of performance beat internal memory (Barkley). | **Strong** |
| **One daily dashboard** | Fewer "what's next / where do I look" decisions = less executive load. | Moderate |
| **Always-visible clock + countdown + org-clock** | Time-perception is measurably impaired in ADHD (2022 meta-analysis); make time external. | **Strong** (the deficit) |
| **Pomodoro** | Time-boxing lowers task-initiation friction. *But* ADHD-specific Pomodoro numbers are weak and many ADHD adults prefer longer blocks — **tune the length, don't worship 25 min.** | Weak |
| **Hard blocks + locked browser + DND** | ADHD is hit harder by external distractors; change the environment, don't rely on willpower (stimulus control). | Moderate–Strong |
| **Self-chosen hard block, admin-only escape** | Steep delay-discounting makes soft "I'll resist later" decay into procrastination. A precommitment *you authored* is the supported sweet spot; autonomy is what makes it stick (vs. control imposed by others). The lab nuance: the escape should be costly-but-possible, not literally irreversible — which is exactly the admin-rebuild path. | Moderate + strong autonomy |
| **Work / personal modes** | Task-switching cost is elevated in ADHD; batching contexts cuts costly gear-changes. | Moderate |
| **Grayscale during focus** | General-population evidence only (≈20 min/day less screen time); **no ADHD study, and your checking frequency may not change.** A nudge, not a cure. *(Also: niri has no native grayscale — see §5.)* | Weak |
| **Lock the config / timebox tinkering** | ADHD novelty-seeking + blunted tonic dopamine means *building this system* hijacks the same circuitry it's meant to manage. | Strong neuro |

If you ever resent the system, re-read the autonomy row: you chose this because
soft blocks become waiting. Repeated overrides are a signal to **redesign the
block list**, not to add more coercion.

---

## 2. The daily loop

1. **Capture all day.** A thought, a task, a distraction-urge → `Mod+N` → type it →
   `C-c C-c`. ~2 seconds, the frame closes, you're back. It lands in `~/org/inbox.org`.
2. **Process the inbox once or twice a day.** Open the dashboard (`SPC SPC a d` or it
   auto-opens at login), clear the **"Refile me (inbox)"** group: refile each item
   to a project (`SPC m r`), or mark it `NEXT`, or kill it.
3. **Work from the dashboard.** Pick from **NEXT** or **Quick wins**. Don't scan five
   lists — there is one.
4. **Focus block.** `Mod+Shift+F` (DND on + grayscale stub). Start a pomodoro on the
   task: in Emacs `SPC m c i` clocks in; the modeline and waybar show elapsed time.
   `Mod+Shift+G` ends it.
5. **Review.** Glance at the dashboard; capture loose ends; done.

---

## 3. The two modes

Boot-selectable and **strictly isolated** — separate Linux users, separate
LUKS-encrypted `/persist`. Personal mode literally cannot read work data (it's
encrypted with a passphrase you don't type in personal mode), and work tools
aren't installed there.

| | **work** | **personal** |
|---|---|---|
| User | `jacob-work` | `jacob-personal` |
| Apps | Slack, dev toolchain | Discord, mpv |
| Blocked | Reddit, LinkedIn, Discord, YouTube, X/Twitter, HN | Slack + your work domains |
| Browser | **default-deny allowlist** (only work domains open) | relaxed (minus blocked hosts) |
| Look | grayscale at login | color |
| Data | `/persist-work` (passphrase B) | `/persist-personal` (passphrase C) |

**Switching modes = reboot** → pick the entry in the boot menu → type that mode's
passphrase. The reboot is deliberate friction; it stops you from hopping into
"personal" to goof off mid-workday. There is no hot-switch (the other mode's disk
was never unlocked).

The **plain entry** (no "work"/"personal" tag) is the **admin recovery** entry.

---

## 4. Capture & org

- **Capture:** `Mod+N` anywhere. Templates: `t` quick task, `n` note/brain-dump,
  `e` event, `E` task with an ENERGY property (for "Quick wins" on low days).
- **Dashboard:** `SPC SPC a d`. Groups: Today / Due / Overdue / Refile-inbox /
  Quick wins / NEXT / Important / Waiting. Empty groups hide themselves.
- **org-roam dailies & notes** (your second brain, kept *out* of the agenda):
  - `SPC n j` → today's daily note.
  - `SPC n r f` find a note, `SPC n r i` insert a link, `SPC n r r` backlinks.
- Files: `~/org/inbox.org`, `~/org/projects.org`, `~/org/calendar.org`,
  `~/org/roam/`. These live on the current mode's encrypted `/persist`.

---

## 5. Focus & time

- **DND:** notifications start **paused** (batched). `Mod+Shift+D` toggles; check the
  batch deliberately a couple times a day instead of being interrupted.
- **Clock:** always in the waybar (date + time) — your anti-time-blindness anchor.
- **Pomodoro:** `Mod+Shift+F` starts a focus block; in Emacs `org-pomodoro` (`SPC m c`
  area) runs the timer and auto-clocks. **Length is configurable in `doom/config.el`
  — change it if 25 min doesn't fit you.**
- **Grayscale caveat:** niri has **no native desaturation shader** (unlike Hyprland).
  `focus-grayscale` is currently a no-op stub. If you want real grayscale, wire it to
  your monitor's mono mode (`ddcutil`) or a GPU/OS accessibility filter and edit
  `modules/home-manager/common.nix`. The evidence for grayscale is weak anyway — low
  priority.

---

## 6. What's blocked & how to unblock (the override valve)

**Blocked:** see the table in §3. Enforced in layers — `/etc/hosts` (StevenBlack +
per-mode lists), AdGuard Home (resolver), a locked Firefox policy with a default-deny
WebsiteFilter in work mode, and nftables that kills DNS-over-HTTPS so the browser
can't sneak around DNS.

**Honest limit:** your terminal/CLI tools and AI agents have **full, unrestricted
network access** — that's required so Claude/Codex/opencode/pi, npm, pip, etc. work.
So `curl reddit.com` still fails (DNS-blocked), but a determined `w3m`/SOCKS-tunnel
bypass exists. That's fine: it has no muscle-memory and is deliberate effort. This is
an anti-distraction system, not a kiosk.

**To unblock something (the ONLY path — by design):**

```sh
# 1. Log out, log in as `admin` (the only account in `wheel`).
# 2. Edit the relevant file:
$EDITOR modules/nixos/modes.nix        # per-mode host blocklists / browser allowlist
$EDITOR modules/nixos/enforcement.nix  # baseline blocking, AdGuard, Firefox policy
# 3. Rebuild:
sudo nixos-rebuild switch --flake .#adhd-desktop
# 4. Log back into your daily user.
```

That friction is the feature. If you find yourself doing this often for the same
site, **change the list** — don't fight yourself.

---

## 7. The anti-tinkering rule

Reconfiguring this system *is* novel and dopamine-rich — which is exactly the trap
it's built to manage. When you get the urge to add a feature or re-rice niri:
**capture it to `inbox.org` (`Mod+N`) and move on.** Timebox config sessions. Treat
"I'll just improve my setup" as a craving, not as work.

---

## 8. Recovery runbook (keep on your phone)

**A rebuild broke the desktop / it won't boot:**
1. Reboot. In the **systemd-boot menu**, pick an **older generation** (they're listed;
   `configurationLimit = 10` keeps the last ten). Older = last known good.
2. Daily users aren't in `wheel`, so you **can't `nixos-rebuild --rollback` from a
   terminal** — use the boot menu instead. Or boot the **admin recovery entry** (the
   untagged one), log in as `admin`, and rebuild/rollback there.

**Total failure (won't boot at all):**
1. Boot a NixOS live USB.
2. Unlock + mount: `cryptsetup open /dev/<part> cryptroot`, mount the `@nix`/`@persist`
   subvolumes, `nixos-enter`.
3. Roll back or fix the flake, `nixos-rebuild boot`.

**Where your data is:** nothing in `/` survives a reboot (impermanence). Your real
data lives on the encrypted per-mode volumes — `~/org`, `~/.ssh`, browser profile,
keyrings, repos — under `/persist-work` or `/persist-personal`, plus system state in
`/persist`. If a file isn't under a persisted path, **it's gone on reboot** — this is
why downloads/scratch must be moved into `~/org` or a repo before you reboot.

**Passwords / keys:** user passwords are hashed files at `/persist*/passwords/`.
The SSH host key (persisted) is what lets sops-nix decrypt your API keys — don't
delete it.

---

## 9. Cheat-sheet

**niri (Mod = Super):**

| Key | Action |
|---|---|
| `Mod+N` | **Capture** (org-capture frame) |
| `Mod+Return` | Terminal (kitty) |
| `Mod+D` | App launcher (fuzzel) |
| `Mod+Q` | Close window |
| `Mod+F` | Maximize column |
| `Mod+←/→` | Focus column |
| `Mod+1/2/3` | Workspace |
| `Mod+Shift+1/2/3` | Move window to workspace |
| `Mod+Shift+D` | Toggle DND |
| `Mod+Shift+F` / `Mod+Shift+G` | Start / end focus block |
| `Mod+Shift+/` | Hotkey overlay |
| `Mod+Shift+E` | Quit niri |

**Doom / org:**

| Key | Action |
|---|---|
| `SPC SPC a d` | Daily dashboard |
| `SPC X` | Capture (in-Emacs) |
| `SPC n j` | Today's roam daily |
| `SPC n r f/i/r` | Roam find / insert / backlinks |
| `SPC m r` | Refile |
| `SPC m c i / o` | Clock in / out |
| `SPC t z` | Zen mode |

**Rebuild (admin only):** `sudo nixos-rebuild switch --flake .#adhd-desktop`

---

## 10. Install (first time)

1. Boot the NixOS ISO. Partition the disk:
   - ESP (vfat) → `/boot`.
   - A LUKS partition (passphrase A) → btrfs with subvolumes `@root`, `@nix`, `@persist`.
   - Two more LUKS partitions (passphrases B, C) → btrfs subvolume `@persist` each,
     for `cryptwork` / `cryptpersonal`.
2. **Snapshot the blank root** (impermanence depends on this):
   `btrfs subvolume snapshot -r /mnt/@root /mnt/@root-blank`.
3. Create password files on the persisted volumes:
   `mkpasswd -m sha-512` → write to `/mnt/persist/passwords/admin`,
   `/mnt/persist-work/passwords/jacob-work`, `/mnt/persist-personal/passwords/jacob-personal`.
4. `nixos-generate-config --root /mnt --no-filesystems`; merge the generated kernel
   modules into `hosts/adhd-desktop/hardware-configuration.nix` and fill in the real
   LUKS/ESP UUIDs (`blkid`) there and in `modules/nixos/modes.nix`.
5. `nixos-install --flake .#adhd-desktop`. Reboot, pick a mode, type its passphrase.
6. First login runs `doom-sync` (clones + builds Doom) — give it a few minutes.
