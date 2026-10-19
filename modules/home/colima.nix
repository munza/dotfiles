# Colima: a Docker runtime in a lightweight VM, started at login, plus the
# docker command. Its config stays writable; settings set from the host are
# merged in on rebuild and win.
{ flake, ... }:
flake.lib.mkModule {
  name = "colima";
  description = "Colima and the docker command";
  enable = false;

  glue =
    { pkgs, ... }:
    {
      services.colima = {
        enable = true;
        # Setting any profile replaces home-manager's default one, so restate it.
        profiles.default = {
          isActive = true;
          isService = true;
          setDockerHost = true;
          mutableSettings = true;
        };
      };
      home.packages = [ pkgs.docker-client ];
    };
}
