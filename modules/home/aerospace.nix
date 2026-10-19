# AeroSpace tiling window manager, started at login. Defaults are AeroSpace's
# own core bindings: alt to focus, alt-shift to move, alt-<n> for workspaces
# 1-9, and alt-shift-; for a service mode whose actions return to main.
#
# AeroSpace drops all its built-in defaults once a config file exists, so the
# defaults live here; change single bindings from the host, e.g.
#   programs.aerospace.settings.mode.main.binding.alt-f = "fullscreen";
# Service-mode bindings are lists, so replace one with lib.mkForce [ ... ].
{ flake, ... }:
flake.lib.mkModule {
  name = "aerospace";
  description = "the AeroSpace window manager";
  enable = false;

  glue.programs.aerospace = {
    enable = true;
    launchd.enable = true;
  };

  defaults =
    { lib, ... }:
    let
      workspaces = map toString (lib.range 1 9);
      forWorkspaces = key: command: lib.genAttrs' workspaces (n: lib.nameValuePair (key n) (command n));
    in
    {
      programs.aerospace.settings = {
        config-version = 2;

        mode.main.binding = {
          alt-slash = "layout tiles horizontal vertical";
          alt-comma = "layout accordion horizontal vertical";

          alt-h = "focus left";
          alt-j = "focus down";
          alt-k = "focus up";
          alt-l = "focus right";

          alt-shift-h = "move left";
          alt-shift-j = "move down";
          alt-shift-k = "move up";
          alt-shift-l = "move right";

          alt-minus = "resize smart -50";
          alt-equal = "resize smart +50";

          alt-tab = "workspace-back-and-forth";
          alt-shift-tab = "move-workspace-to-monitor --wrap-around next";
          alt-shift-semicolon = "mode service";
        }
        // forWorkspaces (n: "alt-${n}") (n: "workspace ${n}")
        // forWorkspaces (n: "alt-shift-${n}") (n: "move-node-to-workspace ${n}");

        mode.service.binding =
          lib.mapAttrs
            (_: command: [
              command
              "mode main"
            ])
            {
              esc = "reload-config";
              r = "flatten-workspace-tree";
              f = "layout floating tiling";
              backspace = "close-all-windows-but-current";
              alt-shift-h = "join-with left";
              alt-shift-j = "join-with down";
              alt-shift-k = "join-with up";
              alt-shift-l = "join-with right";
            };
      };
    };
}
