# The Manual — JakeOS

How to use this machine, why it works the way it does, and how to fix it when it
breaks. **Read sections 1–4 now.** Keep section 9 (Recovery) and section 10
(Troubleshooting) on your phone — that's what you'll want when something's wrong and
the machine is the thing that's broken.

> **This is the simplified ("boring & reliable") build.** No impermanence, one disk
> passphrase, a stable channel, and a deliberately tiny daily surface. The goal:
> nothing to babysit, almost nothing new to learn beyond niri.

---

## 1. Why this exists

One rule: **the bypass must be slower than the impulse, and you must have chosen it
yourself.** Capturing a thought or starting work is one keypress. Reaching a
distraction takes an admin-only rebuild. That asymmetry is the entire design.

| Mechanism | Why | Evidence |
|---|---|---|
| **2-second global capture → one inbox** | ADHD is a working-memory disorder; an external cue at the moment of need beats internal memory (Barkley). | **Strong** |
| **One daily dashboard (a few groups)** | Fewer "what's next / where do I look" decisions = less executive load. | Moderate |
| **Always-visible clock + org-clock** | Time perception is measurably impaired in ADHD; make time external. | **Strong** (the deficit) |
| **Pomodoro (org-pomodoro)** | Time-boxing lowers task-initiation friction. Tune the length — don't worship 25 min. | Weak |
| **Hard blocks + locked browser + DND** | ADHD is hit harder by distractors; change the environment, don't rely on willpower. | Moderate–Strong |
| **Self-chosen hard block, admin-only escape** | Soft "resist later" decays into procrastination; a precommitment *you authored* sticks. The escape is costly-but-possible (admin rebuild), not impossible. | Moderate + strong autonomy |
| **Work / personal modes** | Task-switching is expensive in ADHD; isolated modes batch contexts and keep work out of downtime. | Moderate |

---

## 2. The daily loop

1. **Capture all day.** Thought / task / urge → **`Mod+N`** → type → `C-c C-c`. ~2s,
   the little frame closes, you're back where you were. It lands in
   `~/org/inbox.org`. **No menu, no "what kind is this?"** — it always goes to a quick
   task. Sort it later.
2. **Process the inbox 1–2× a day** (see §6, *Refiling*). Open it with **`SPC o i`**,
   and for each item: turn it into a `NEXT`, **refile** it to a project
   (`SPC m r r`), or delete it. Empty inbox = clear head.
3. **Work from the dashboard.** **`SPC o d`** → pick something from **NEXT**. There is
   one list. Don't reorganize — just pick.
4. **Focus block.** `Mod+Shift+F` (DND on). Clock in on the task: `SPC m c i`. The top
   bar now shows the task + elapsed time. `Mod+Shift+F` again when you surface.
5. **Review.** Glance at the dashboard, capture loose ends, done for the day.

---

## 3. What you see when you log in

You log in and a **Doom Emacs frame** opens to the **Doom dashboard** (the splash with
recent files / projects). This is a normal Emacs buffer, so **`SPC` is the leader and
all your keybinds work immediately.**

- Your daily agenda is **one key away: `SPC o d`**.
- The top bar shows the **current org-clock task** (left-of-center) and the
  **date + time** (right). Nothing else is clickable — by design.
- Notifications start **paused** (DND). You pull them deliberately, you don't get
  pulled.

> **Why the dashboard and not the agenda?** Opening straight into the agenda dropped
> you into a buffer where `SPC` runs *agenda* commands, not the Doom leader — which is
> confusing, and the old auto-open could leave a junk `(org-agenda nil "d")` file.
> Now you land somewhere `SPC` works, and the agenda is a single keypress.

---

## 4. The two modes (work / personal)

Boot-selectable and **isolated in daily use**: separate Linux users, and the work and
personal homes are **mount-isolated btrfs subvolumes inside one LUKS** (not
cryptographically separated — `root`/`admin` *could* mount either, but your daily user
can't). Personal mode never mounts the work home and never installs work apps.

| | **work** | **personal** | **admin (recovery)** |
|---|---|---|---|
| User | `jacob-work` | `jacob-personal` | `admin` |
| Login | **autologin** | **autologin** | manual prompt (tuigreet) |
| In `wheel`/sudo? | no | no | **yes** (the only one) |
| Apps | Slack, dev toolchain | Discord, mpv | — |
| Blocked | Reddit, LinkedIn, Discord, YouTube, X, HN | Slack + your work domains | — |
| Browser | default-deny allowlist | relaxed (minus blocked) | — |
| Home | `/home/jacob-work` | `/home/jacob-personal` | `/home/admin` |

### Picking a mode at boot

The **boot menu** is both your recovery net (older generations) and your mode selector.
Entries:

- **`work`** / **`personal`** — your two daily modes. Selecting one **autologs in** to
  that user.
- **The plain / untagged entry** — the **admin recovery** system. It shows a **manual
  login prompt**; only `admin` exists here and it's the only account with `sudo`. This
  is where you go to rebuild, unblock, or fix things.

> **If you keep "ending up in admin":** you're letting the menu land on the plain
> entry. **Arrow down and pick `work`.** Nothing auto-logs-into-admin — admin is a
> manual login; you've just been selecting (or defaulting to) the recovery entry and
> typing the admin password.

**Switching modes = reboot → pick the other entry → enter the disk passphrase** (one
LUKS for the whole machine). The reboot is deliberate friction so you don't hop into
"personal" mid-workday.

---

## 5. niri — the windows ("how do I switch?")

niri tiles **windows side-by-side in a horizontal row**; **workspaces** are separate
screens. You're never hunting for an overlapping window — new windows open full-width
(monotasking), and you scroll between them.

- **Switch between open windows** (editor ↔ browser): `Mod+←` / `Mod+→`.
- **See everything at once** (zoom-out): `Mod+O` (overview).
- **Workspaces** = fixed homes for tasks (e.g. 1 = code, 2 = comms): `Mod+1/2/3`; send
  the current window to one with `Mod+Shift+1/2/3`.
- **Maximize / restore** the current window: `Mod+F`.
- **Close** a window: `Mod+Q`.
- **Forgot a key?** `Mod+Shift+/` shows the full overlay.

---

## 6. Capture, the inbox, and **refiling**

This is the core workflow, so it gets its own section.

### Capture (offload anything, instantly)
- **`Mod+N`** anywhere (even from the browser) → a tiny frame → type → `C-c C-c`. Goes
  straight to a quick **TODO** in `~/org/inbox.org`. No categorize-it-now decision.
- Want a deliberate **note** instead of a task? In Emacs press **`SPC X`** and choose
  `n` (note) from the menu.

### Refiling (move an inbox item to where it belongs)
"Refiling" = taking a captured item out of the inbox and filing it under a real
heading (a project). Do this 1–2× a day so the inbox keeps meaning "unsorted."

1. **`SPC o i`** — opens `~/org/inbox.org`.
2. Put the cursor **on the item's heading line**.
3. **`SPC m r r`** (or `C-c C-w`) — the **refile** command. A prompt appears.
4. Type to filter and pick a target, e.g. `projects.org/Work`, then `Enter`. The item
   moves there.
   - Targets are any heading (up to 3 deep) in your agenda files. You start with
     **`~/org/projects.org`** (`Work` / `Personal` / `Someday`) — add your own
     headings any time.
   - **Filing somewhere new?** Just type a heading that doesn't exist yet; you'll be
     asked to confirm creating it.
5. Repeat for each inbox item. Done = empty inbox.

> From the **dashboard** (`SPC o d`) the inbox items show under **"Refile me (inbox)."**
> The agenda has no one-key refile, so press `RET` on an item to jump to it in
> `inbox.org`, then `SPC m r r` — or just work from `SPC o i`.

### The dashboard (`SPC o d`)
One screen, grouped: **Today** (scheduled/due) · **Overdue** · **Refile me (inbox)** ·
**NEXT — do these**. Empty groups hide themselves. It's an *agenda* buffer, so inside
it the keys are agenda keys — `RET` open, `t` cycle TODO, `q` quit back to a normal
buffer.

### org-roam (second brain — kept out of the agenda)
- `SPC n j` — today's daily note.
- `SPC n r f` / `i` / `r` — find note / insert link / show backlinks.
- Lives in `~/org/roam/`, deliberately separate from your action lists.

---

## 7. Focus & time

- **DND:** notifications start paused (batched). `Mod+Shift+F` toggles; check the batch
  deliberately a couple times a day.
- **Clock:** always in the bar (date + time) — your anti-time-blindness anchor. The bar
  also shows the currently-clocked task. Clock in/out: `SPC m c i` / `SPC m c o`.
- **Pomodoro:** `org-pomodoro` auto-clocks the task. Length lives in
  `doom/config.el` (`org-pomodoro-length`) — change it if 25 min doesn't fit you.

---

## 8. What's blocked & how to unblock

**Why the blocks are actually hard** (not "just edit the hosts file"):
- `/etc/hosts` is generated from Nix — a read-only `/nix/store` symlink regenerated
  every boot. Your daily user isn't in `wheel` and has no `sudo`, so **you cannot edit
  it.**
- `systemd-resolved` reads `/etc/hosts`, so blocked domains answer `0.0.0.0` for the
  browser *and* normal CLIs (`curl reddit.com` fails).
- An nftables rule forces all DNS to the local resolver and blocks DoH/DoT, so even
  `dig @8.8.8.8 reddit.com` or a DoH client can't dodge it.
- The **work browser is default-deny** (a locked Firefox allowlist) — only work domains
  load; everything else is blocked *in the browser*.
- Your **AI agents / CLIs / npm / pip keep full network access** — they resolve via the
  local resolver and connect to any IP. Only *direct external DNS from a non-resolver
  process* and *non-allowlisted sites in the work browser* are blocked.

**To unblock something (the only path — by design):**
```sh
# 1. Reboot → pick the plain/untagged "admin" boot entry → log in as `admin`.
# 2. Edit ONE list file (plain quoted domains, no Nix knowledge needed):
sudo $EDITOR /etc/nixos/modules/nixos/blocklist.nix
#    - workBlocked / personalBlocked  → what each mode blocks
#    - workAllowExceptions            → what the work browser is allowed to load
# 3. Rebuild:
sudo nixos-rebuild switch --flake /etc/nixos#adhd-desktop
# 4. Reboot back into your daily mode.
```
That friction is the feature. Unblocking the same site over and over? **Change the
list deliberately** — don't fight yourself in the moment.

---

## 9. Recovery runbook (keep on your phone)

**A rebuild broke the desktop:**
- Reboot → in the **systemd-boot menu** pick an **older generation** (last 10 are
  kept). Older = last known good. (Daily users can't `--rollback` from a terminal — use
  the boot menu, or boot the admin entry and fix it as `admin`.)

**Won't boot at all:**
1. Boot a NixOS live USB.
2. `cryptsetup open /dev/nvme0n1p2 cryptroot` (your disk may differ — check `lsblk`).
3. Mount the root + nix subvolumes, then `nixos-enter`.
4. Fix the flake / roll back, `nixos-rebuild boot`, reboot.

**Your data:** the root is **persistent** — files survive reboots (no impermanence).
Each mode's home lives on its encrypted subvolume (`/home/jacob-work` or
`/home/jacob-personal`).

**Get back in to fix things remotely:** SSH is enabled. If the firewall is in the way,
from the machine's TTY (`Ctrl+Alt+F2`, log in as admin) you can `sudo nft flush ruleset`
to open it temporarily.

---

## 10. Troubleshooting (things we actually hit)

**First login feels broken / Emacs looks like plain Emacs.**
On a *fresh* home, the first login clones and compiles Doom in the background
(`doom-sync`), and the Emacs daemon waits for it. **Give it a few minutes** on first
boot (and it needs network — see WiFi below). It's a one-time cost; later logins are
instant.

**WiFi won't connect (`wireless-security key-management property is missing`).**
Add the network explicitly as admin:
```sh
nmcli connection add type wifi con-name MyNet ssid "MyNet" \
  wifi-sec.key-mgmt wpa-psk wifi-sec.psk "your-password"
nmcli connection up MyNet
```

**The dashboard / agenda doesn't respond to `SPC`.**
That's expected *inside the agenda buffer* — there `SPC` runs agenda commands. Press
`q` to return to a normal buffer where `SPC` is the Doom leader. (You now log in to the
Doom dashboard, where `SPC` works, precisely to avoid this.)

**Icons are missing / boxes in Doom.**
The system installs *Symbols Nerd Font* for nerd-icons. If glyphs are still missing
after a rebuild, run `M-x nerd-icons-install-fonts` once, then restart Emacs
(`SPC q r` or log out/in).

**Doom config change isn't taking effect.**
Doom needs a sync after config edits: `~/.config/emacs/bin/doom sync`, then restart the
daemon (`SPC q r`, or log out/in). The login `doom-sync` does this automatically when
you're online.

**A download wedged during install/rebuild (nix-daemon stuck on a NAR).**
`sudo systemctl restart nix-daemon`, then re-run the rebuild — it resumes.

**You're stuck in admin and wanted work.** See §4 — pick the `work` entry at the boot
menu (admin is a manual-login recovery entry, not where daily work happens).

---

## 11. Cheat-sheet

**niri (Mod = Super):**

| Key | Action |
|---|---|
| `Mod+N` | **Capture** (straight to a quick task) |
| `Mod+Return` | Terminal (kitty) |
| `Mod+D` | Launcher (fuzzel) |
| `Mod+Q` | Close window |
| `Mod+Shift+F` | Focus on/off (DND toggle) |
| `Mod+←` / `Mod+→` | Previous / next window |
| `Mod+O` | Overview (see everything) |
| `Mod+F` | Maximize / restore window |
| `Mod+1/2/3` | Switch workspace |
| `Mod+Shift+1/2/3` | Send window to workspace |
| `Mod+Shift+/` | Hotkey overlay |
| `Mod+Shift+E` | Log out of niri |
| Volume keys | Raise / lower / mute |

**Doom / org:**

| Key | Action |
|---|---|
| `Mod+N` | **Global capture** (from anywhere → inbox) |
| `SPC o d` | **Daily dashboard** (agenda) |
| `SPC o i` | **Open inbox** (to refile) |
| `SPC X` | Capture with menu (task / note) |
| `SPC m r r` *(or `C-c C-w`)* | **Refile** item to a project |
| `SPC m c i` / `SPC m c o` | Clock in / out |
| `SPC n j` | Today's roam daily |
| `SPC n r f / i / r` | Roam find / insert link / backlinks |
| `RET` / `t` / `q` *(in agenda)* | Open item / cycle TODO / quit agenda |
| `SPC q r` | Restart Emacs |
| `SPC t z` | Zen / writeroom mode |

**Rebuild (admin only):** `sudo nixos-rebuild switch --flake /etc/nixos#adhd-desktop`

---

## 12. Install (first time)

> **Full copy-pasteable walkthrough: [`docs/INSTALL.md`](INSTALL.md).** Partitioning is
> declarative (disko) — no manual fdisk/cryptsetup/UUIDs. The summary:

1. Boot the NixOS ISO, get online, `git clone https://github.com/jaketothepast/JakeOS`.
2. Set your disk in `modules/nixos/disko.nix` (`device = "/dev/…"` — check `lsblk`).
3. `echo -n 'your-disk-passphrase' > /tmp/secret.key`, then
   `sudo nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#adhd-desktop`
   (partitions + formats + mounts to `/mnt`).
4. `sudo cp -r . /mnt/etc/nixos`, then create the admin password hash file in
   `/mnt/var/lib/adhd-secrets/admin.pw` (`mkpasswd -m sha-512 > …`).
5. `sudo nixos-install --flake /mnt/etc/nixos#adhd-desktop --no-root-passwd`, reboot,
   pick the **work** entry. First login runs `doom-sync` — give it a few minutes.

> Reproducibility: every input in `flake.nix` is pinned to an exact commit, and the
> committed `flake.lock` records their hashes — so rebuilds don't drift. Run
> `nix flake update` deliberately when you *want* updates.
