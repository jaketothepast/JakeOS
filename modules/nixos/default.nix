{ ... }:
{
  # System-level modules. Order is irrelevant (Nix merges), grouped for humans.
  imports = [
    ./disko.nix        # declarative disk layout (partitions, LUKS, btrfs subvols)
    ./base.nix         # ssh host key (for sops), nix housekeeping
    ./boot.nix         # bootloader, NVIDIA, kernel, LUKS plumbing
    ./desktop.nix      # niri + Xwayland, greetd, audio, fonts, portals
    ./enforcement.nix  # blocking: hosts + resolved + slim nftables + Firefox policy
    ./modes.nix        # work / personal specialisations (users, home-on-LUKS, block deltas)
    ./ollama.nix       # local models, CUDA
  ];
}
