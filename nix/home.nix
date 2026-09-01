{
  pkgs,
  lib,
  local,
  ...
}:
{
  home.username = local.username;
  home.homeDirectory = local.homeDirectory;
  home.stateVersion = "25.11";

  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;

  imports = lib.optionals local.enableHyprland [ ./hyprland-home.nix ];

  home.sessionVariables = lib.mkIf local.enableHyprland {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  home.packages =
    with pkgs;
    [
      # Base (macos-setup.sh install_base_packages)
      git
      curl
      wget
      file
      gnupg
      unzip
      zip
      jq
      ripgrep
      fzf
      fd
      ffmpeg-full
      p7zip
      poppler_utils
      imagemagick
      zoxide
      yazi
      resvg
      neovim
      gh
      tmux
      tree
      pkg-config
      openssl

      # Languages / CLIs
      nodejs_24
      pnpm
      bun
      go
      rustup
      ocaml
      opam
      python3
      watchman
      turso-cli
      cliamp
      yt-dlp
      herdr

      # Java / Kotlin (Temurin equivalent)
      jdk21
      kotlin
      gradle

      # Desktop apps
      ghostty
      zed-editor
      bitwarden-desktop
      discord
      android-studio
      android-tools
      handy
      tailscale

      # Fonts
      nerd-fonts.space-mono
      nerd-fonts.symbols-only
    ]
    ++ lib.optionals local.enableHyprland (
      [
        # Hyprland ecosystem. Rectangle / Raycast / Dock have no macOS analog
        # here: tiling + wofi + waybar cover those jobs on Wayland.
        waybar
        wofi
        mako
        hyprpaper
        hyprlock
        hypridle
        hyprpicker
        hyprsunset
        hyprshot
        grim
        slurp
        wl-clipboard
        cliphist
        brightnessctl
        playerctl
        pavucontrol
        networkmanagerapplet
        xdg-utils
        xdg-desktop-portal-gtk
        kdePackages.qtwayland
        qt5.qtwayland
        polkit_gnome
      ]
      ++ lib.optionals (!local.isNixOS) [
        hyprland
        xdg-desktop-portal-hyprland
      ]
    );
}
