# Git, with your name and email from dotfiles.user. Defaults add common
# settings and delta for readable diffs.
{ flake, ... }:
flake.lib.mkModule {
  name = "git";
  description = "git";

  glue =
    { config, ... }:
    {
      programs.git = {
        enable = true;
        settings.user = {
          name = config.dotfiles.user.fullName;
          email = config.dotfiles.user.email;
        };
      };
    };

  defaults = {
    programs.git = {
      ignores = [ ".DS_Store" ];
      settings = {
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
