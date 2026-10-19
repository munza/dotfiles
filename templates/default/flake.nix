{
  description = "macOS setup built on munza/dotfiles";

  inputs = {
    dotfiles.url = "github:munza/dotfiles";

    # Pinned by munza/dotfiles, so you get the exact versions its CI tested.
    # `nix flake update dotfiles` moves them all together.
    nixpkgs.follows = "dotfiles/nixpkgs";
    nix-darwin.follows = "dotfiles/nix-darwin";
    home-manager.follows = "dotfiles/home-manager";
    blueprint.follows = "dotfiles/blueprint";
  };

  outputs =
    inputs:
    inputs.blueprint {
      inherit inputs;
      systems = [ "aarch64-darwin" ];
    };
}
