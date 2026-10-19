# Secrets shared by several Macs, kept encrypted in your repo and managed in
# one place. One Mac only? dotfiles.secrets.env is simpler.
#
# Decrypted at login with each Mac's SSH key (~/.ssh/id_ed25519) by sops-nix.
# Point it at sops-encrypted JSON files; later files win on a name clash, so
# a host's file can override a shared one:
#   dotfiles.secrets.sops.files = [ ./secrets/common.json ./secrets/my-mac.json ];
#
# Each secret is available to every shell as $<NAME>_FILE, a path to its
# decrypted value (github-token → $GITHUB_TOKEN_FILE). Plain values in the
# environment are opt-in, since every process you start inherits them:
#   dotfiles.secrets.sops.exportValues = [ "github-token" ];   # → $GITHUB_TOKEN
#
# Manage the files with sops; its recipients are each Mac's ssh-ed25519 public
# key, listed in .sops.yaml:
#   sops edit secrets/common.json                              add, change or remove
#   sops decrypt --extract '["github-token"]' secrets/common.json   print one
#   sops updatekeys secrets/*.json                             after .sops.yaml changes
{ inputs, ... }:
{ config, lib, ... }:
let
  cfg = config.dotfiles.secrets.sops;

  # sops keeps JSON keys in plaintext, so names are read without decrypting.
  namesIn = file: builtins.filter (name: name != "sops") (builtins.attrNames (lib.importJSON file));
  secrets = lib.foldl' (acc: file: acc // lib.genAttrs (namesIn file) (_: file)) { } cfg.files;

  envName = name: lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] name);
  pathOf = name: config.sops.secrets.${name}.path;
in
{
  imports = [ inputs.sops-nix.homeModules.sops ];

  options.dotfiles.secrets.sops = {
    files = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "sops-encrypted JSON files whose keys become secrets.";
    };
    exportValues = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "github-token" ];
      description = "Secrets to also export as plain values in interactive zsh.";
    };
  };

  config = lib.mkIf (cfg.files != [ ]) {
    sops = {
      age.sshKeyPaths = lib.mkDefault [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      secrets = lib.mapAttrs (_: file: {
        sopsFile = file;
        format = "json";
      }) secrets;
    };

    home.sessionVariables = lib.mapAttrs' (
      name: _: lib.nameValuePair "${envName name}_FILE" (pathOf name)
    ) secrets;

    # Guarded, since a shell can start before the secrets are decrypted.
    programs.zsh.initContent = lib.concatMapStrings (name: ''
      [[ -r "${pathOf name}" ]] && export ${envName name}="$(<"${pathOf name}")"
    '') cfg.exportValues;

    assertions = map (name: {
      assertion = secrets ? ${name};
      message = "dotfiles.secrets.sops.exportValues: no secret named \"${name}\" in dotfiles.secrets.sops.files.";
    }) cfg.exportValues;
  };
}
