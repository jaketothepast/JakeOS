{
  description = "ADHD-friendly NixOS: hard to do the wrong thing, easy to do the right thing";

  inputs = {
    # Track unstable: niri-flake + emacs-pgtk move fast and want a recent nixpkgs.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri compositor (NixOS + home-manager modules, plus the niri.cachix.org cache).
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Wipe-on-boot root with explicit persisted paths.
    impermanence.url = "github:nix-community/impermanence";

    # Secrets (API keys for the AI CLIs), mode-scoped.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Auto-updated packages for the AI coding agents (claude-code, codex, opencode, ...).
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
          inputs.impermanence.nixosModules.impermanence
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
