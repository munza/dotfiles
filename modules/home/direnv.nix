# direnv loads a project's environment when you cd into it (`use flake` in .envrc).
# nix-direnv caches the dev shell, so re-entering a project is instant.
{ flake, ... }:
flake.lib.mkModule {
  name = "direnv";
  description = "direnv";

  glue.programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Only speak up on errors, not on every load.
  defaults.programs.direnv.config.global.hide_env_diff = true;
}
