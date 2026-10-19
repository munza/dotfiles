# Git with your name and email from dotfiles.user, a few modern defaults,
# and delta for readable diffs.
{ config, lib, ... }:
let
  inherit (config.dotfiles) user;
in
{
  options.dotfiles.git.enable = lib.mkEnableOption "git" // {
    default = true;
  };

  config = lib.mkIf config.dotfiles.git.enable {
    programs.git = {
      enable = true;
      ignores = [ ".DS_Store" ];

      settings = {
        user.name = user.fullName;
        user.email = user.email;

        init.defaultBranch = "main";
        pull.rebase = true;
        # First push of a new branch sets its upstream; no --set-upstream needed.
        push.autoSetupRemote = true;
        fetch.prune = true;
        # Conflicts also show the common ancestor, without repeating identical lines.
        merge.conflictStyle = "zdiff3";
      };
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      # n and N jump between files in a diff.
      options.navigate = true;
    };
  };
}
