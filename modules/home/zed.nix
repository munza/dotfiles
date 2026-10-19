# Zed editor, using the font from dotfiles.fonts.mono. settings.json and
# keymap.json stay writable: changes made in Zed are kept, and only the keys
# set here are re-applied on rebuild. Defaults turn telemetry off and set up
# Nix editing (nixd, formatting with nixfmt).
{ flake, ... }:
flake.lib.mkModule {
  name = "zed";
  description = "the Zed editor";
  enable = false;

  glue =
    { config, ... }:
    {
      programs.zed-editor = {
        enable = true;
        userSettings.buffer_font_family = config.dotfiles.fonts.mono.name;
      };
    };

  defaults =
    { pkgs, ... }:
    {
      programs.zed-editor = {
        extensions = [ "nix" ];
        # On Zed's PATH only, not your shell's.
        extraPackages = [
          pkgs.nixd
          pkgs.nixfmt
        ];

        userSettings = {
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
          languages.Nix.language_servers = [
            "nixd"
            "!nil"
          ];
          lsp.nixd.initialization_options.formatting.command = [ "nixfmt" ];
        };
      };
    };
}
