# ClamAV for on-demand virus scans. Its built-in database path is read-only in
# the Nix store, so the database lives in ~/.local/share/clamav instead:
#   clam-update     download or refresh the virus database
#   clam-scan DIR   scan DIR, listing only infected files
{ flake, ... }:
flake.lib.mkModule {
  name = "clamav";
  description = "ClamAV";
  enable = false;

  glue =
    { config, pkgs, ... }:
    let
      database = "${config.xdg.dataHome}/clamav";
      freshclamConf = "${config.xdg.configHome}/clamav/freshclam.conf";
    in
    {
      home.packages = [ pkgs.clamav ];

      xdg.configFile."clamav/freshclam.conf".text = ''
        DatabaseDirectory ${database}
        DatabaseMirror database.clamav.net
      '';

      home.shellAliases = {
        clam-update = ''mkdir -p "${database}" && freshclam --config-file="${freshclamConf}"'';
        # Fails when the database is over a week old, so a scan never silently uses stale data.
        clam-scan = ''clamscan --database="${database}" --recursive --infected --fail-if-cvd-older-than=7'';
      };
    };
}
