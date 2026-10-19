# Entry point for a darwin host: `imports = [ inputs.dotfiles.darwinModules.default ];`
{ flake, ... }:
{ config, lib, ... }:
let
  inherit (config.dotfiles) user;
  # Blueprint creates one home-manager user per file in hosts/<host>/users/.
  hmUsers = builtins.attrNames config.home-manager.users;
in
{
  imports = [ flake.modules.common.user ];

  # The users/ file already names the user, so hosts don't have to repeat it.
  dotfiles.user.name = lib.mkIf (builtins.length hmUsers == 1) (lib.mkDefault (builtins.head hmUsers));

  system.primaryUser = user.name;
  users.users = lib.genAttrs hmUsers (name: {
    home = "/Users/${name}";
  });

  # Shared rather than set on home-manager.users.<name>, which would create an
  # empty extra user when the name doesn't match the users/ file.
  home-manager.sharedModules = [
    flake.homeModules.default
    { dotfiles.user = user; }
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
}
