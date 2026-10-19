# Editable config files: <configDir>/<path> in your repo, linked to ~/.config/<path>.
# The link points at the checkout, not the Nix store, so edits apply at once
# and show up in git.
{
  config,
  lib,
  flake,
  ...
}:
let
  cfg = config.dotfiles;
in
{
  options.dotfiles = {
    flakeDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.dotfiles";
      description = "Where your repo is checked out.";
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      defaultText = lib.literalExpression ''"hosts/<host>/config"'';
      example = "shared/config";
      description = "Folder in your repo, relative to its root, that holds this host's editable config files. darwinModules.default sets it to hosts/<host>/config.";
    };

    configLinks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "starship.toml" ];
      description = "Files under configDir to link into ~/.config.";
    };
  };

  config = {
    xdg.configFile = lib.genAttrs cfg.configLinks (path: {
      source = config.lib.file.mkOutOfStoreSymlink "${cfg.flakeDir}/${cfg.configDir}/${path}";
    });

    # `flake` is the flake that defines the host, so this checks your repo.
    assertions = map (path: {
      assertion = builtins.pathExists "${flake}/${cfg.configDir}/${path}";
      message = "${cfg.configDir}/${path} is missing from your repo; it's linked to ~/.config/${path}.";
    }) cfg.configLinks;
  };
}
