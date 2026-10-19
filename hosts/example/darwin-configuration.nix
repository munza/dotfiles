# Example host. Copy it to make your own:
#
#   1. cp -r hosts/example hosts/<mac-name>      # scutil --get LocalHostName
#   2. mv hosts/<mac-name>/users/example.nix \
#         hosts/<mac-name>/users/<login>.nix     # whoami
#   3. Fill in your name and email below.
#   4. sudo nix run nix-darwin -- switch --flake .#<mac-name>
#
# Leave this folder as it is; CI checks it so the example always works.
{ flake, ... }:
{
  imports = [ flake.darwinModules.default ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  dotfiles.user = {
    fullName = "Example User";
    email = "example@example.com";
  };

  # Set once at install time; never bump on upgrade.
  system.stateVersion = 6;
}
