# Starship prompt. Its config is <configDir>/starship.toml in your repo, linked
# into ~/.config so you can edit it in place. Setting programs.starship.settings
# from the host uses those instead, and the file isn't linked.
{ flake, ... }:
flake.lib.mkModule {
  name = "starship";
  description = "the starship prompt";

  glue =
    { config, lib, ... }:
    {
      programs.starship.enable = true;
      dotfiles.configLinks = lib.mkIf (config.programs.starship.settings == { }) [ "starship.toml" ];
    };
}
