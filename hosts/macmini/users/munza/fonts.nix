# Annotation Mono's Nerd Font build, for the terminal and editor, with
# JetBrains Mono's as the fallback for any glyph it lacks.
{ config, pkgs, ... }:
let
  fallback = "JetBrainsMono Nerd Font Mono";
in
{
  dotfiles.fonts.mono = {
    name = "AnnotationM Nerd Font Mono";
    package = pkgs.nerd-fonts.annotationmono;
  };

  home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  # Ghostty tries each family in order.
  programs.ghostty.settings.font-family = [
    config.dotfiles.fonts.mono.name
    fallback
  ];

  programs.zed-editor.userSettings = {
    buffer_font_fallbacks = [ fallback ];
    ui_font_fallbacks = [ fallback ];
  };
}
