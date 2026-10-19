# eza: a modern ls. Defaults show git status and icons (needs a Nerd Font).
{ flake, ... }:
flake.lib.mkModule {
  name = "eza";
  description = "eza";

  glue.programs.eza.enable = true;

  defaults.programs.eza = {
    git = true;
    icons = "auto";
  };
}
