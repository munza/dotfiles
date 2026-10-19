# btop resource monitor. It saves settings you change in its menu to
# ~/.config/btop/btop.conf, which stays writable until you set
# programs.btop.settings from the host.
{ flake, ... }:
flake.lib.mkModule {
  name = "btop";
  description = "btop";
  enable = false;
  glue.programs.btop.enable = true;
}
