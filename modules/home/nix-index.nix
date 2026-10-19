# A missing command prints which package provides it. Defaults add comma:
# `, <command>` runs it without installing. Uses a prebuilt index, so
# nothing to generate locally.
{ flake, inputs, ... }:
flake.lib.mkModule {
  name = "nix-index";
  description = "nix-index";
  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  glue.programs.nix-index.enable = true;
  defaults.programs.nix-index-database.comma.enable = true;
}
