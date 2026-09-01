{
  description = "Dotfiles Home Manager config for NixOS (see nixos-setup.sh)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }:
    let
      # User-specific values come from the environment. nixos-setup.sh exports
      # these and runs home-manager with --impure so getEnv works inside a flake.
      envOr =
        name: fallback:
        let
          value = builtins.getEnv name;
        in
        if value == "" then fallback else value;

      local = {
        username = envOr "USER" "user";
        homeDirectory = envOr "HOME" "/home/user";
        isNixOS = true;
        enableHyprland = builtins.getEnv "DOTFILES_HYPRLAND" != "0";
      };

      mkHome =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit local; };
          modules = [ ./home.nix ];
        };
    in
    {
      homeConfigurations = {
        "dotfiles-x86_64-linux" = mkHome "x86_64-linux";
        "dotfiles-aarch64-linux" = mkHome "aarch64-linux";
      };

      nixosModules.hyprland = import ./nixos/hyprland.nix;
      nixosModules.services = import ./nixos/services.nix;
    };
}
