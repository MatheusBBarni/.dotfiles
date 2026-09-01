{ pkgs, ... }:
{
  # Workstation services that match macos-setup.sh / linux-setup.sh.
  # Import alongside hyprland.nix:
  #   imports = [ /path/to/dotfiles/nix/nixos/services.nix ];
  #
  # Add your user to the docker group in configuration.nix:
  #   users.users.<name>.extraGroups = [ "docker" ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  programs.zsh.enable = true;

  virtualisation.docker = {
    enable = true;
    extraPackages = with pkgs; [ docker-buildx ];
  };

  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  services.tailscale.enable = true;
}
