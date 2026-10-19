{ pkgs, perSystem }:
pkgs.mkShell {
  packages = [
    perSystem.self.formatter
    pkgs.gitleaks
  ];

  # Git doesn't track hook config, so the dev shell enables the repo's hooks.
  shellHook = ''
    git config core.hooksPath .githooks
  '';
}
