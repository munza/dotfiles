# eza: a modern ls. Defaults show git status, icons (needs a Nerd Font) and
# dotfiles, and add `ll` for a long listing of everything.
{ flake, ... }:
flake.lib.mkModule {
  name = "eza";
  description = "eza";

  glue.programs.eza.enable = true;

  defaults = {
    programs.eza = {
      git = true;
      icons = "auto";
      # Every alias (ls, la, lt) lists dotfiles too.
      extraOptions = [ "--all" ];
    };
    home.shellAliases.ll = "eza -lah --git";
  };
}
