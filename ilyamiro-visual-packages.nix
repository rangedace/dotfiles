{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  services.dbus.enable = true;

  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    kitty
    waybar
    rofi-wayland
    dunst

    pavucontrol
    networkmanagerapplet
    brightnessctl
    playerctl

    grim
    slurp
    wl-clipboard
    cliphist

    hyprpaper
    hyprlock
    hypridle
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
