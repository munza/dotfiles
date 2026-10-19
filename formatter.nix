{
  pkgs,
  inputs,
  flake,
  ...
}:
let
  treefmt = inputs.treefmt-nix.lib.evalModule pkgs {
    projectRootFile = "flake.nix";
    programs = {
      nixfmt.enable = true;
      deadnix.enable = true;
      statix.enable = true;
      shfmt.enable = true;
      shellcheck.enable = true;
    };
  };
in
# Blueprint turns passthru.tests into flake checks, so `nix flake check` also checks formatting.
treefmt.config.build.wrapper.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    tests.check = treefmt.config.build.check flake;
  };
})
