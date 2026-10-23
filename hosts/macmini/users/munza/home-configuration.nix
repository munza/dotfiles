# Tawsif's home. Imports hold each tool's settings and the font; the dotfiles
# block below turns tools on.
{ config, ... }:
{
  imports = [
    ./aerospace.nix
    ./colima.nix
    ./fonts.nix
    ./gh.nix
    ./ghostty.nix
    ./herdr.nix
    ./neovim.nix
    ./pi.nix
    ./skills.nix
    ./starship.nix
    ./zed.nix
  ];

  dotfiles = {
    aerospace.enable = true;
    btop.enable = true;
    clamav.enable = true;
    colima.enable = true;
    ghostty.enable = true;
    herdr.enable = true;
    lazygit.enable = true;
    neovim.enable = true;
    pi.enable = true;
    yazi.enable = true;
    zed.enable = true;
  };

  home.sessionVariables = {
    MANPAGER = "less -R --use-color -Dd+B -Du+G";
  };

  # Global rules for coding agents, shared by pi and Claude Code. Linked to
  # the checkout like the config/ files, so edits apply at once.
  home.file =
    let
      rules = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.flakeDir}/${config.dotfiles.configDir}/AGENTS.md";
    in
    {
      ".pi/agent/AGENTS.md".source = rules;
      ".claude/CLAUDE.md".source = rules;
    };

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.shellAliases.tree = "tree -a -I .git";

  # Set once at install time; never bump on upgrade.
  home.stateVersion = "26.05";
}
