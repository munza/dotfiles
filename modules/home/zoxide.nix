# zoxide: `z <part of a path>` jumps to a directory you've visited before.
{ flake, ... }:
flake.lib.mkModule {
  name = "zoxide";
  description = "zoxide";
  glue.programs.zoxide.enable = true;
}
