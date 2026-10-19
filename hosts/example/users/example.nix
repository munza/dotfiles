# Your home-manager config. The file name is your macOS login name (`whoami`);
# see ../darwin-configuration.nix for the steps.
{
  # Opt-in apps; remove the ones you don't want.
  dotfiles.aerospace.enable = true;
  dotfiles.btop.enable = true;
  dotfiles.ghostty.enable = true;
  dotfiles.herdr.enable = true;
  dotfiles.lazygit.enable = true;
  dotfiles.yazi.enable = true;
  dotfiles.zed.enable = true;

  # Set once at install time; never bump on upgrade.
  home.stateVersion = "26.05";
}
