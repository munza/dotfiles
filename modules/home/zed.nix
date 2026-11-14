# Zed editor, using the font from dotfiles.fonts.mono. settings.json and
# keymap.json stay writable: changes made in Zed are kept, and only the keys
# set here are re-applied on rebuild. Defaults turn telemetry off and set up
# Nix editing (nixd, formatting with nixfmt).
#
# Zed itself comes from the Homebrew cask (prebuilt, updates itself), which the
# Homebrew module adds when this is on: nixpkgs' zed-editor is often not in the
# binary cache after an update, so a switch would compile it. With no Nix
# wrapper, the tools Zed runs go on the shell's PATH. To use nixpkgs' build
# instead, set programs.zed-editor.package = pkgs.zed-editor.
{ flake, ... }:
flake.lib.mkModule {
  name = "zed";
  description = "the Zed editor";
  enable = false;

  glue =
    { config, lib, ... }:
    {
      programs.zed-editor = {
        enable = true;
        package = null;
        userSettings.buffer_font_family = config.dotfiles.fonts.mono.name;
      };
      # nixpkgs names the CLI zeditor, since another program is called zed.
      home.shellAliases.zed = lib.mkIf (config.programs.zed-editor.package != null) "zeditor";
    };

  defaults =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.nixd
        pkgs.nixfmt
      ];
      programs.zed-editor = {
        extensions = [ "nix" ];

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
