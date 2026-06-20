# `pi` — the earendil-works AI coding agent (npm: @earendil-works/pi-coding-agent).
#
# It isn't in nixpkgs and is a fast-moving npm CLI, so rather than vendor a
# lockfile + npmDepsHash that rots weekly, we ship a thin wrapper that runs it
# via `npx`. Tradeoff: the first invocation downloads the package into the npm
# cache (which is persisted per-mode), so it's not a hermetic build — acceptable
# for a personal CLI that updates constantly.
#
# If you meant can1357/oh-my-pi instead, swap the package name below.
{ writeShellApplication, nodejs }:
writeShellApplication {
  name = "pi";
  runtimeInputs = [ nodejs ];
  text = ''
    exec npx --yes @earendil-works/pi-coding-agent "$@"
  '';
}
