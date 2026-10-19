# Entry point for a darwin host: `imports = [ inputs.dotfiles.darwinModules.default ];`
{ flake, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.dotfiles) user;
  # Blueprint creates one home-manager user per file in hosts/<host>/users/.
  hmUsers = builtins.attrNames config.home-manager.users;
in
{
  # Through flake.darwinModules so modules needing this flake's inputs get them,
  # not the inputs of the flake importing this one.
  imports = [
    flake.modules.common.user
    flake.darwinModules.homebrew
    flake.darwinModules.nix
    flake.darwinModules.system
  ];

  options.dotfiles.home = lib.mkOption {
    type = lib.types.deferredModule;
    default = { };
    example = lib.literalExpression ''
      { pkgs, lib, ... }: {
        programs.git.settings.pull.rebase = false;            # replaces the default
        programs.git.ignores = [ "*.swp" ];                   # lists are added to
        programs.zsh.setOptions = lib.mkForce [ "AUTO_PUSHD" ]; # replaces the whole list
      }
    '';
    description = ''
      Home-manager config for this host's user, merged with the defaults from
      homeModules.default. Same as writing it in hosts/<host>/users/<name>.nix.
    '';
  };

  config = {
    # The users/ file already names the user, so hosts don't have to repeat it.
    dotfiles.user.name = lib.mkIf (builtins.length hmUsers == 1) (
      lib.mkDefault (builtins.head hmUsers)
    );

    system.primaryUser = user.name;
    users.users = lib.genAttrs hmUsers (name: {
      home = "/Users/${name}";
    });

    # A first switch moves existing files (e.g. ~/.zshrc) to the Trash instead of failing.
    home-manager.backupCommand = "${pkgs.darwin.trash}/bin/trash";

    # Shared rather than set on home-manager.users.<name>, which would create an
    # empty extra user when the name doesn't match the users/ file.
    home-manager.sharedModules = [
      flake.homeModules.default
      { dotfiles.user = user; }
      config.dotfiles.home
    ];

    assertions = [
      {
        assertion = hmUsers == [ user.name ];
        message = ''
          dotfiles.user.name is "${user.name}", but the host's users are: ${toString hmUsers}.
          Name the file hosts/<host>/users/${user.name}.nix, or drop dotfiles.user.name to use the file name.
        '';
      }
    ];
  };
}
