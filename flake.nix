{
  description = "A reproducible macOS setup with nix-darwin and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";

    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.blueprint {
      inherit inputs;
      # No Linux host; x86_64-linux exists so CI can build checks on a Linux runner.
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
    };
}
