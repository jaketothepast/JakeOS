{
  description = "ADHD-friendly NixOS: hard to do the wrong thing, easy to do the right thing";

  inputs = {
    # Stable base: a boring, reliable foundation cuts the breakage/tinkering treadmill.
    # niri still comes from niri-flake's own package + cache, so stable nixpkgs is fine.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri compositor (NixOS + home-manager modules, plus the niri.cachix.org cache).
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning (automates install — no manual fdisk/cryptsetup).
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets (API keys for the AI CLIs), mode-scoped.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Auto-updated packages for the AI coding agents (claude-code, codex, opencode, ...).
    # Intentionally does NOT follow our nixpkgs — these fast-moving tools need newer
    # deps (e.g. pnpm_11) than stable 25.11 ships. It brings its own pinned nixpkgs;
    # the resulting binaries don't need to match our system nixpkgs.
    llm-agents.url = "github:numtide/llm-agents.nix";
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
