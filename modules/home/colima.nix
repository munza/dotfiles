# Colima: a Docker runtime in a lightweight VM, started at login, plus the
# docker command (compose and buildx included). Its config stays writable;
# settings set from the host are merged in on rebuild and win, e.g.
#   services.colima.profiles.default.settings = { cpu = 4; memory = 8; };
{ flake, ... }:
flake.lib.mkModule {
  name = "colima";
  description = "Colima and the docker command";
  enable = false;

  glue =
    { config, ... }:
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

      # The same docker colima uses; nixpkgs wraps it with compose and buildx.
      home.packages = [ config.services.colima.dockerPackage ];
    };
}
