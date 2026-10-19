# Ghostty terminal, using the font from dotfiles.fonts.mono. It also loads
# config/ghostty/config from your repo, so you can edit settings in place;
# values there win over the ones set here.
{ flake, ... }:
flake.lib.mkModule {
  name = "ghostty";
  description = "the Ghostty terminal";
  enable = false;

  glue =
    { config, pkgs, ... }:
    {
      programs.ghostty = {
        enable = true;
        # The macOS app; home-manager copies it to ~/Applications/Home Manager Apps.
        # Set to null to use the Homebrew cask instead.
        package = pkgs.ghostty-bin;
        settings = {
          font-family = config.dotfiles.fonts.mono.name;
          # `?` makes the file optional.
          config-file = [ "?${config.dotfiles.flakeDir}/config/ghostty/config" ];
        };
      };
    };

  # Option (⌥) works as Alt in terminal apps, instead of typing special characters.
  defaults.programs.ghostty.settings.macos-option-as-alt = true;
}
