# fzf: fuzzy search for files (Ctrl-T), history (Ctrl-R) and directories (Alt-C).
# Defaults search with fd, which respects .gitignore and is faster than find.
{ flake, ... }:
flake.lib.mkModule {
  name = "fzf";
  description = "fzf";

  glue.programs.fzf.enable = true;

  defaults =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.fd ];
      programs.fzf = {
        defaultCommand = "fd --type f --hidden --exclude .git";
        fileWidget.command = "fd --type f --hidden --exclude .git";
        changeDirWidget.command = "fd --type d --hidden --exclude .git";
      };
    };
}
