# GitHub CLI, also used by git as the credential helper for github.com.
# Login state (`gh auth login`) stays out of the repo. Defaults add gh-dash,
# a terminal dashboard for PRs and issues (`gh dash`).
{ flake, ... }:
flake.lib.mkModule {
  name = "gh";
  description = "the GitHub CLI";
  glue.programs.gh.enable = true;
  defaults = { pkgs, ... }: { programs.gh.extensions = [ pkgs.gh-dash ]; };
}
