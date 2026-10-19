# Checks the secrets modules: the env file is loaded, and against fake sops
# files, names come from the JSON keys, later files win, and only listed
# secrets are exported as values.
{ pkgs, flake, ... }:
let
  inherit (pkgs) lib;

  fakeSops = name: secrets: builtins.toFile name (builtins.toJSON (secrets // { sops = { }; }));
  common = fakeSops "common.json" {
    github-token = "ENC[x]";
    shared = "ENC[x]";
  };
  host = fakeSops "host.json" { shared = "ENC[y]"; };

  home =
    (flake.darwinConfigurations.example.extendModules {
      modules = [
        {
          dotfiles.home.dotfiles.secrets.sops = {
            files = [
              common
              host
            ];
            exportValues = [ "github-token" ];
          };
        }
      ];
    }).config.home-manager.users.example;

  failures = lib.runTests {
    testEnvFileLoaded = {
      expr = lib.hasInfix ''source "/Users/example/.config/secrets.env"'' home.programs.zsh.envExtra;
      expected = true;
    };
    testNamesAndOverride = {
      expr = lib.mapAttrs (_: secret: secret.sopsFile) home.sops.secrets;
      expected = {
        github-token = common;
        shared = host;
      };
    };
    testFileVariables = {
      expr = builtins.filter (lib.hasSuffix "_FILE") (builtins.attrNames home.home.sessionVariables);
      expected = [
        "GITHUB_TOKEN_FILE"
        "SHARED_FILE"
      ];
    };
    testOnlyListedValuesExported = {
      expr = map (name: lib.hasInfix "export ${name}=" home.programs.zsh.initContent) [
        "GITHUB_TOKEN"
        "SHARED"
      ];
      expected = [
        true
        false
      ];
    };
  };
in
if failures == [ ] then
  pkgs.runCommand "secrets-tests" { } "touch $out"
else
  throw "secrets module tests failed: ${builtins.toJSON failures}"
