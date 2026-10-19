# Annotation Mono's Nerd Font build, for the terminal and editor.
{ pkgs, ... }:
{
  dotfiles.fonts.mono = {
    name = "AnnotationM Nerd Font Mono";
    package = pkgs.nerd-fonts.annotationmono;
  };
}
