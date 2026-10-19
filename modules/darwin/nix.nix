# Nix itself: flakes on, old generations collected, identical files hard-linked.
# Skipped when nix-darwin doesn't manage Nix (nix.enable = false, e.g. Determinate Nix).
{ config, lib, ... }:
{
  config = lib.mkIf config.nix.enable {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Weekly, on nix-darwin's default schedule.
    nix.gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 30d";
    };

    # Not nix.settings.auto-optimise-store, which can corrupt the store on macOS.
    nix.optimise.automatic = lib.mkDefault true;
  };
}
