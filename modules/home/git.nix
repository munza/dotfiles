# Git, with your name and email from dotfiles.user. Defaults add common
# settings, short aliases, and delta for readable diffs.
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
      ignores = [
        ".DS_Store"
        # Editor swap and backup files.
        "*.bak"
        "*.swn"
        "*.swo"
        "*.swp"
        "*.un~"
      ];
      settings = {
        init.defaultBranch = "main";
        pull.rebase = true;
        # First push of a new branch sets its upstream; no --set-upstream needed.
        push.autoSetupRemote = true;
        fetch.prune = true;
        # Conflicts also show the common ancestor, without repeating identical lines.
        merge.conflictStyle = "zdiff3";
        log.date = "iso";
        log.decorate = "full";

        alias = {
          am = "commit --amend";
          br = "branch --sort=-committerdate";
          cm = "commit -m";
          co = "checkout";
          cp = "cherry-pick";
          df = "diff";
          dfc = "diff --cached";
          fix = "commit --amend --no-edit";
          last = "log -1 HEAD --stat";
          lg = "log --graph --all --pretty=format:'%C(auto)%h%C(reset) - %C(auto)%d%C(reset) %s %C(green)(%cr)%C(reset) %C(bold blue)<%an>%C(reset)' --abbrev-commit";
          pff = "pull --ff-only";
          pfl = "push --force-with-lease origin HEAD";
          pl = "pull";
          ps = "push origin HEAD";
          rba = "rebase --abort";
          rbc = "rebase --continue";
          rbi = "rebase -i";
          recent = "log --oneline -20";
          root = "rev-parse --show-toplevel";
          st = "status";
          sta = "stash";
          std = "stash drop";
          stl = "stash list";
          stp = "stash pop";
          sw = "switch";
          swc = "switch -c";
          undo = "reset --soft HEAD~1";
          unstage = "restore --staged";
        };
      };
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        # n and N jump between files in a diff.
        navigate = true;
        line-numbers = true;
        # File paths and commit hashes become clickable links.
        hyperlinks = true;
      };
    };
  };
}
