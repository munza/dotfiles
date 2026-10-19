# Starship prompt. Its config is config/starship.toml in this repo, linked
# into ~/.config so you can edit it in place.
{ config, lib, ... }:
{
  options.dotfiles.starship.enable = lib.mkEnableOption "the starship prompt" // {
    default = true;
  };

  config = lib.mkIf config.dotfiles.starship.enable {
    programs.starship.enable = true;
    dotfiles.configLinks = [ "starship.toml" ];
  };
}
