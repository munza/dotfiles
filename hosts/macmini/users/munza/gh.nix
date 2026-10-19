# GitHub CLI on top of the module's defaults: SSH for git operations
# (matching how gh was logged in) and Neovim as its editor.
{
  programs.gh.settings = {
    git_protocol = "ssh";
    editor = "nvim";
  };
}
