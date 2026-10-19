# lazygit, a terminal UI for git. Its config (~/.config/lazygit/config.yml)
# stays yours to edit until you set programs.lazygit.settings from the host.
{ flake, ... }:
flake.lib.mkModule {
  name = "lazygit";
  description = "lazygit";
  enable = false;
  glue.programs.lazygit.enable = true;
}
