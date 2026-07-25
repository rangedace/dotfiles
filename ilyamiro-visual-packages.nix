{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    kitty
    waybar
    rofi-wayland
    dunst
    pavucontrol
    networkmanagerapplet
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
