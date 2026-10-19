# direnv loads a project's environment when you cd into it (`use flake` in .envrc).
# nix-direnv caches the dev shell, so re-entering a project is instant.
{ config, lib, ... }:
{
  options.dotfiles.direnv.enable = lib.mkEnableOption "direnv" // {
    default = true;
  };

  config = lib.mkIf config.dotfiles.direnv.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      # Only speak up on errors, not on every load.
      config.global.hide_env_diff = true;
    };
  };
}
