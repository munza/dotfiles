# Secrets for a single Mac: KEY=value lines in a file outside the repo, loaded
# into every zsh. Nothing is encrypted or committed, so keep the file private:
#   echo 'GITHUB_TOKEN=...' >> ~/.config/secrets.env && chmod 600 ~/.config/secrets.env
#
# Several Macs sharing the same secrets? Use dotfiles.secrets.sops instead.
{ config, lib, ... }:
let
  cfg = config.dotfiles.secrets.env;
in
{
  options.dotfiles.secrets.env = {
    enable = lib.mkEnableOption "loading secrets from a local env file" // {
      default = true;
    };
    file = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/secrets.env";
      defaultText = lib.literalExpression ''"''${config.xdg.configHome}/secrets.env"'';
      description = "The env file. A missing file is skipped.";
    };
  };

  # `set -a` exports every variable the file sets.
  config = lib.mkIf cfg.enable {
    programs.zsh.envExtra = ''
      if [[ -r "${cfg.file}" ]]; then
        set -a; source "${cfg.file}"; set +a
      fi
    '';
  };
}
