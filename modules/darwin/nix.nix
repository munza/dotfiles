# Nix itself: flakes on. Defaults add weekly garbage collection of anything
# older than 30 days and hard-linking of identical files.
# Skipped when nix-darwin doesn't manage Nix (nix.enable = false, e.g. Determinate Nix).
{ flake, ... }:
flake.lib.mkModule {
  name = "nix";
  description = "Nix settings";

  glue =
    { config, lib, ... }:
    lib.mkIf config.nix.enable {
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

  defaults =
    { config, lib, ... }:
    lib.mkIf config.nix.enable {
      # Weekly, on nix-darwin's default schedule.
      nix.gc = {
        automatic = true;
        options = "--delete-older-than 30d";
      };
      # Not nix.settings.auto-optimise-store, which can corrupt the store on macOS.
      nix.optimise.automatic = true;
    };
}
