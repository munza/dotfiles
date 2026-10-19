# The monospace font terminals and editors use. The default is a Nerd Font,
# so icons (eza, starship) render without a fallback font. Change it in your
# host, e.g.:
#   dotfiles.home.dotfiles.fonts.mono = { name = "FiraCode Nerd Font Mono"; package = pkgs.nerd-fonts.fira-code; };
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.fonts.mono;
in
{
  options.dotfiles.fonts.mono = {
    name = lib.mkOption {
      type = lib.types.str;
      # The Mono variant keeps icons one cell wide, which terminals need.
      default = "JetBrainsMono Nerd Font Mono";
      description = "Font family name, as apps see it.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nerd-fonts.jetbrains-mono;
      defaultText = lib.literalExpression "pkgs.nerd-fonts.jetbrains-mono";
      description = "Package that provides the font.";
    };
  };

  # home-manager copies fonts from home.packages into ~/Library/Fonts/HomeManager.
  config.home.packages = [ cfg.package ];
}
