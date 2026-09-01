{
  pkgs,
  ...
}:
{
  # NixOS system module for Hyprland.
  # Import from configuration.nix or a host flake:
  #   imports = [ /path/to/dotfiles/nix/nixos/hyprland.nix ];
  #
  # This is the supported way to run Hyprland via Nix. The compositor needs
  # session files, portals, and a graphics stack that nix profile cannot
  # provide on its own. See https://wiki.nixos.org/wiki/Hyprland
  # and https://wiki.hypr.land/Nix/Hyprland-on-NixOS/

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # programs.hyprland already wires xdg-desktop-portal-hyprland.
  # GTK portal covers file pickers and apps that do not speak the Hyprland portal.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };

  hardware.graphics.enable = true;

  security.polkit.enable = true;
  security.rtkit.enable = true;
  programs.dconf.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  fonts.packages = with pkgs; [
    nerd-fonts.space-mono
    nerd-fonts.symbols-only
  ];
}
