{
  description = "ADHD-friendly NixOS: hard to do the wrong thing, easy to do the right thing";

  inputs = {
    # Inputs are PINNED to the exact revisions the machine was installed with, so a
    # `nixos-rebuild` reuses the already-built/cached packages instead of drifting to
    # newer revs and recompiling niri/ollama/codex. To update deliberately later,
    # point these back at their branches and run `nix flake update`.
    nixpkgs.url = "github:NixOS/nixpkgs/d6df3513510aa548c83868fd22bfddd0a8c0a0d4"; # nixos-25.11 @ install

    home-manager = {
      url = "github:nix-community/home-manager/3ee51fbdac8c8bdfe1e7e1fcaba6520a563f394f"; # release-25.11
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri compositor (NixOS + home-manager modules, plus the niri.cachix.org cache).
    niri = {
      url = "github:sodiboo/niri-flake/493ce1e33e72f86312584f331c8cf52b3432ec99";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning (automates install — no manual fdisk/cryptsetup).
    disko = {
      url = "github:nix-community/disko/ff8702b4de27f72b4c78573dfb89ec74e36abdf1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets (API keys for the AI CLIs), mode-scoped.
    sops-nix = {
      url = "github:Mic92/sops-nix/420f8d2e9882911f65cfac15cc706f639ba96cca";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Auto-updated packages for the AI coding agents (claude-code, codex, opencode, ...).
    # Intentionally does NOT follow our nixpkgs — these fast-moving tools need newer
    # deps (e.g. pnpm_11) than stable 25.11 ships. It brings its own pinned nixpkgs;
    # the resulting binaries don't need to match our system nixpkgs.
    llm-agents.url = "github:numtide/llm-agents.nix/6b704a00ef4211936ce6815770386638ddf1d0e3";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.adhd-desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        # Thread every flake input down to modules as `inputs`.
        specialArgs = { inherit inputs; };
        modules = [
          inputs.home-manager.nixosModules.home-manager
          inputs.niri.nixosModules.niri
          inputs.disko.nixosModules.disko
          inputs.sops-nix.nixosModules.sops

          ./hosts/adhd-desktop

          {
            # home-manager as a NixOS module: one atomic generation, unified rollback.
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.backupFileExtension = "hm-bak";
          }
        ];
      };
    };
}
