# Rename hosts/my-mac/ to this Mac's name (`scutil --get LocalHostName`), so
# darwin-rebuild finds it without --flake .#<name>.
{ inputs, ... }:
{
  imports = [ inputs.dotfiles.darwinModules.default ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  dotfiles.user = {
    fullName = "Your Name";
    email = "you@example.com";
  };

  # Set once at install time; never bump on upgrade.
  system.stateVersion = 6;
}
