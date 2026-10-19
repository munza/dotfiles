# Checks flake.lib.mkModule: a host can use, merge with or override defaults.
{ pkgs, flake, ... }:
let
  inherit (pkgs) lib;

  eval =
    host:
    (lib.evalModules {
      modules = [
        {
          options = {
            text = lib.mkOption { type = lib.types.str; };
            lines = lib.mkOption { type = lib.types.lines; };
            items = lib.mkOption { type = lib.types.listOf lib.types.str; };
            glued = lib.mkOption { type = lib.types.bool; };
          };
          # An upstream module's own default for the same option.
          config.text = lib.mkDefault "upstream";
        }
        (flake.lib.mkModule {
          name = "demo";
          description = "demo";
          glue.glued = true;
          defaults = {
            text = "default";
            lines = flake.lib.mergeable "default line";
            items = [ "default" ];
          };
        })
        host
      ];
    }).config;

  failures = lib.runTests {
    testUseDefaults = {
      expr = with eval { }; [
        text
        lines
        items
        glued
      ];
      expected = [
        "default"
        "default line"
        [ "default" ]
        true
      ];
    };
    testMerge = {
      expr =
        with eval {
          text = "host";
          lines = "host line";
          items = [ "host" ];
        }; [
          text
          lines
          items
        ];
      expected = [
        "host"
        "default line\nhost line"
        [
          "host"
          "default"
        ]
      ];
    };
    testOverride = {
      expr =
        with eval {
          dotfiles.demo.defaults = false;
          text = "host";
          lines = "host line";
          items = [ "host" ];
        }; [
          text
          lines
          items
          glued
        ];
      expected = [
        "host"
        "host line"
        [ "host" ]
        true
      ];
    };
    testDisable = {
      expr =
        (eval {
          dotfiles.demo.enable = false;
          text = "host";
          lines = "";
          items = [ ];
          glued = false;
        }).glued;
      expected = false;
    };
  };
in
if failures == [ ] then
  pkgs.runCommand "lib-tests" { } "touch $out"
else
  throw "flake.lib tests failed: ${builtins.toJSON failures}"
