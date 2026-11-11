# GitLab CLI. Login state (`glab auth login`) stays out of the repo.
{ flake, ... }:
flake.lib.mkModule {
  name = "glab";
  description = "the GitLab CLI";
  glue = { pkgs, ... }: { home.packages = [ pkgs.glab ]; };
}
