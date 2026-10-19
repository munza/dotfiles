# nh: rebuild with a package diff and a confirm before switching.
#   nh darwin switch --ask            build, diff, switch on yes
#   nh darwin switch --update --ask   same, after updating flake inputs
#   nh search <term>                  find a package
#   nh clean all --keep-since 30d     delete old generations
{ config, lib, ... }:
{
  options.dotfiles.nh.enable = lib.mkEnableOption "nh" // {
    default = true;
  };

  config = lib.mkIf config.dotfiles.nh.enable {
    programs.nh = {
      enable = true;
      # Works from any directory, not just inside the repo.
      flake = config.dotfiles.flakeDir;
    };
  };
}
