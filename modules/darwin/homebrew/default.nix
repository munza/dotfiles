# Homebrew, for apps nixpkgs doesn't ship well (most GUI apps). Declare them in
# the host, e.g. homebrew.casks = [ "firefox" ];
#
# Apps you didn't declare are left alone. To have rebuilds remove them, set
# homebrew.onActivation.cleanup = "uninstall" (or "zap", which also deletes their data).
#
# Formulae missing from Homebrew live in ./tap; any host can use them, e.g.
# homebrew.brews = [ "dotfiles/tap/herdr-core" ];
{ flake, inputs, ... }:
flake.lib.mkModule {
  name = "homebrew";
  description = "Homebrew";
  # Installs Homebrew itself, so a fresh Mac needs no manual step.
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  glue =
    { config, lib, ... }:
    {
      homebrew = {
        enable = true;
        # Puts brew and the apps it installs on PATH.
        enableZshIntegration = true;
        taps = [ "dotfiles/tap" ];
        # The zed home module uses the cask unless a user picked a Nix package.
        casks = lib.optional (lib.any (
          home: home.dotfiles.zed.enable && home.programs.zed-editor.package == null
        ) (lib.attrValues config.home-manager.users)) "zed";
      };
      # enableZshIntegration only covers interactive shells; login items
      # such as the arc menu run `zsh -lc` and need it too.
      environment.systemPath = [
        "${config.homebrew.prefix}/bin"
        "${config.homebrew.prefix}/sbin"
      ];

      nix-homebrew = {
        enable = true;
        user = config.dotfiles.user.name;
        # Takes over a Homebrew that was installed by hand, instead of failing.
        autoMigrate = true;
        # The option wants a whole store path, which a subfolder of the flake isn't.
        taps."dotfiles/homebrew-tap" = builtins.path {
          path = ./tap;
          name = "homebrew-tap";
        };
      };
    };
}
