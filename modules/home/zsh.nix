# Zsh, managed by home-manager so other tools (direnv, starship, fzf, ...) hook
# into it. Defaults add suggestions, highlighting and shared history.
{ flake, ... }:
flake.lib.mkModule {
  name = "zsh";
  description = "zsh";

  glue.programs.zsh.enable = true;

  defaults =
    { pkgs, ... }:
    {
      programs.zsh = {
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        # Up and down search history for what's already typed.
        historySubstringSearch.enable = true;
        # Typing a directory name, or `..`, changes into it.
        autocd = true;

        history = {
          size = 50000;
          save = 50000;
          share = true;
          ignoreAllDups = true;
          # A command starting with a space stays out of history.
          ignoreSpace = true;
        };

        setOptions = [
          "AUTO_PUSHD"
          "PUSHD_IGNORE_DUPS"
          "PUSHD_SILENT"
          "EXTENDED_GLOB"
          # `cd name` also tries $name, so named directories work without `~`.
          "CDABLE_VARS"
          # Offers to fix a mistyped command.
          "CORRECT"
        ];

        initContent = flake.lib.mergeable ''
          # Case-insensitive completion.
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        '';
      };

      # Completions for tools that don't ship their own.
      home.packages = [ pkgs.zsh-completions ];
    };
}
