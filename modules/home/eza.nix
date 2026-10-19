# eza: a modern ls. Defaults show git status and icons (needs a Nerd Font),
# and add `ll` for a long listing of everything.
{ flake, ... }:
flake.lib.mkModule {
  name = "eza";
  description = "eza";

  glue.programs.eza.enable = true;

  defaults = {
    programs.eza = {
      git = true;
      icons = "auto";
    };
    home.shellAliases.ll = "eza -lah --git";
  };
}
