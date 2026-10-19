# Herdr terminal session manager. Herdr writes to its own config.toml
# (onboarding, UI changes), so it stays writable: settings set from the host
# are merged into it on rebuild and win; everything else is kept.
{ flake, ... }:
flake.lib.mkModule {
  name = "herdr";
  description = "the Herdr session manager";
  enable = false;

  glue.programs.herdr = {
    enable = true;
    mutableSettings = true;
  };
}
