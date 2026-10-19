# Starship prompt. Its config is <configDir>/starship.toml in your repo, linked
# into ~/.config so you can edit it in place.
{ flake, ... }:
flake.lib.mkModule {
  name = "starship";
  description = "the starship prompt";

  glue = {
    programs.starship.enable = true;
    dotfiles.configLinks = [ "starship.toml" ];
  };
}
