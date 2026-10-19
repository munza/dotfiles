# Zsh with suggestions, highlighting, shared history and fuzzy search;
# zoxide for jumping to directories, eza for listings.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.dotfiles.zsh.enable = lib.mkEnableOption "zsh and its companions" // {
    default = true;
  };

  config = lib.mkIf config.dotfiles.zsh.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
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
      ];

      initContent = ''
        # Case-insensitive completion.
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      '';
    };

    # Completions for tools that don't ship their own.
    home.packages = [
      pkgs.zsh-completions
      pkgs.fd
    ];

    programs.fzf = {
      enable = true;
      # fd respects .gitignore and is faster than find.
      defaultCommand = "fd --type f --hidden --exclude .git";
      fileWidget.command = "fd --type f --hidden --exclude .git";
      changeDirWidget.command = "fd --type d --hidden --exclude .git";
    };

    programs.zoxide.enable = true;

    programs.eza = {
      enable = true;
      git = true;
      icons = "auto";
    };
  };
}
