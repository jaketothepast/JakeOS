# Single source of truth for what's blocked / allowed per mode.
#
# THIS is the file you (as admin) edit to unblock something, then rebuild. Plain
# lists — no Nix knowledge beyond "add/remove a quoted string." Consumed by
# enforcement.nix and modes.nix via `import ./blocklist.nix`.
{
  # ---- WORK mode: kill the named time-sinks --------------------------------
  workBlocked = [
    "reddit.com" "old.reddit.com" "new.reddit.com" "i.redd.it" "v.redd.it"
    "linkedin.com"
    "discord.com" "discordapp.com" "discord.gg"
    "youtube.com" "news.ycombinator.com" "x.com" "twitter.com"
  ];

  # ---- PERSONAL mode: no work tooling. Add your employer domains here. ------
  personalBlocked = [
    "slack.com" "app.slack.com"
    # "yourcompany.example.com"
    # "jira.yourcompany.com"
  ];

  # ---- WORK browser allow-list (Firefox WebsiteFilter is default-DENY) ------
  # Everything not listed is blocked IN THE BROWSER. CLIs/agents are unaffected.
  workAllowExceptions = [
    "*://*.github.com/*" "*://github.com/*"
    "*://*.githubusercontent.com/*"
    "*://*.anthropic.com/*" "*://*.claude.ai/*" "*://claude.ai/*"
    "*://challenges.cloudflare.com/*"   # Cloudflare Turnstile — claude.ai login bot-check
    "*://*.cloudflareinsights.com/*"
    "*://*.gstatic.com/*" "*://*.googleapis.com/*"   # fonts / static assets used at login
    "*://*.openai.com/*" "*://*.chatgpt.com/*"        # codex login (OpenAI / ChatGPT OAuth)
    "*://*.opencode.ai/*"                              # opencode login
    "*://*.plane.so/*" "*://plane.so/*"                # Plane — work task manager
    # OAuth callbacks: the AI CLIs finish their browser login on a local port.
    "*://localhost/*" "*://127.0.0.1/*"
    "*://*.stackoverflow.com/*" "*://stackoverflow.com/*"
    "*://*.google.com/*" "*://google.com/*"
    "*://*.gitlab.com/*"
    "*://*.npmjs.com/*" "*://*.pypi.org/*" "*://*.crates.io/*"
    "*://*.nixos.org/*" "*://*.mozilla.org/*"
    "*://*.focusmate.com/*"        # body-doubling (allow-listed on purpose)
    # "*://*.yourcompany.example.com/*"
  ];
}
