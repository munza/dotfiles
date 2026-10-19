# Example host, evaluated in CI as the shape every real host follows.
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
