# A missing command prints which package provides it; `, <command>` runs it
# without installing. Uses a prebuilt index, so nothing to generate locally.
{ inputs, ... }:
{ config, lib, ... }:
{
  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  options.dotfiles.nix-index.enable = lib.mkEnableOption "nix-index and comma" // {
    default = true;
  };

  config = lib.mkIf config.dotfiles.nix-index.enable {
    programs.nix-index.enable = true;
    programs.nix-index-database.comma.enable = true;
  };
}
