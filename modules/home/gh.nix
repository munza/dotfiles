# GitHub CLI, also used by git as the credential helper for github.com.
# Login state (`gh auth login`) stays out of the repo.
{ config, lib, ... }:
{
  options.dotfiles.gh.enable = lib.mkEnableOption "the GitHub CLI" // {
    default = true;
  };

  config = lib.mkIf config.dotfiles.gh.enable {
    programs.gh.enable = true;
  };
}
