# Example host. Copy it to make your own:
#
#   1. cp -r hosts/example hosts/<mac-name>      # scutil --get LocalHostName
#   2. mv hosts/<mac-name>/users/example.nix \
#         hosts/<mac-name>/users/<login>.nix     # whoami
#   3. Fill in your name and email below.
#   4. sudo nix run nix-darwin -- switch --flake .#<mac-name>
#   5. From then on: nh darwin switch --ask
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

  # Apps from Homebrew, and macOS preferences, go here too, e.g.:
  #   homebrew.casks = [ "firefox" ];
  #   system.defaults.dock.autohide = true;

  # Every module ships default settings. For each one, a host can:
  #   - use them:      do nothing
  #   - merge:         set values; a value replaces that default, a list is added to
  #   - override:      dotfiles.<module>.defaults = false, then set your own
  # Home settings go in dotfiles.home, e.g.:
  #   dotfiles.home = { lib, pkgs, ... }: {
  #     programs.git.settings.pull.rebase = false;      # merge: replaces one default
  #     programs.git.ignores = [ "*.swp" ];             # merge: added to the defaults
  #     dotfiles.zsh.defaults = false;                  # override: bare zsh, then
  #     programs.zsh.autosuggestion.enable = true;      #   only what you set here
  #     dotfiles.fonts.mono = { name = "FiraCode Nerd Font Mono"; package = pkgs.nerd-fonts.fira-code; };
  #   };
  # Darwin modules work the same way here directly, e.g. dotfiles.system.defaults = false;

  # Set once at install time; never bump on upgrade.
  system.stateVersion = 6;
}
