# yazi terminal file manager. `y` opens it and, on quit, moves your shell to
# the directory you were in. Defaults show hidden files and list folders first.
{ flake, ... }:
flake.lib.mkModule {
  name = "yazi";
  description = "the yazi file manager";
  enable = false;

  glue.programs.yazi.enable = true;

  defaults.programs.yazi.settings.mgr = {
    show_hidden = true;
    sort_dir_first = true;
  };
}
