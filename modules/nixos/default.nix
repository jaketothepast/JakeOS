{ ... }:
{
  # System-level modules. Order is irrelevant (Nix merges), grouped for humans.
  imports = [
    ./boot.nix         # bootloader, NVIDIA, kernel, LUKS plumbing
    ./impermanence.nix # wipe-on-boot root + explicit persisted paths
    ./desktop.nix      # niri + Xwayland, greetd, audio, fonts, portals
    ./enforcement.nix  # baseline blocking: hosts, AdGuard, Firefox policy, nftables
    ./modes.nix        # work / personal specialisations (users, persist, app+block deltas)
    ./ollama.nix       # local models, CUDA
  ];
}
