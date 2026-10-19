# Safe defaults for any Mac: Touch ID for sudo, firewall on, no guest login.
# Personal preferences (Dock, Finder, keyboard) belong in the host's system.defaults.
{ flake, ... }:
flake.lib.mkModule {
  name = "system";
  description = "macOS settings";

  defaults = {
    # Touch ID for sudo, also inside terminal multiplexers such as tmux.
    security.pam.services.sudo_local = {
      touchIdAuth = true;
      reattach = true;
    };

    networking.applicationFirewall = {
      enable = true;
      enableStealthMode = true;
    };

    system.defaults.loginwindow.GuestEnabled = false;
  };
}
