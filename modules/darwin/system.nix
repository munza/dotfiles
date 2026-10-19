# Safe defaults for any Mac. Personal preferences (Dock, Finder, keyboard)
# belong in the host's system.defaults.
{ lib, ... }:
{
  # Touch ID for sudo, also inside terminal multiplexers such as tmux.
  security.pam.services.sudo_local = {
    touchIdAuth = lib.mkDefault true;
    reattach = lib.mkDefault true;
  };

  networking.applicationFirewall = {
    enable = lib.mkDefault true;
    enableStealthMode = lib.mkDefault true;
  };

  system.defaults.loginwindow.GuestEnabled = lib.mkDefault false;
}
