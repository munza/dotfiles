# Who the machine belongs to. Shared by the darwin and home-manager modules,
# so a host sets it once and home-manager receives the same values.
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.dotfiles.user = {
    name = mkOption {
      type = types.str;
      example = "alice";
      description = "Login name. Defaults to the single file name in hosts/<host>/users/.";
    };
    fullName = mkOption {
      type = types.str;
      example = "Alice Doe";
      description = "Full name, used for git commits.";
    };
    email = mkOption {
      type = types.str;
      example = "alice@example.com";
      description = "Email address, used for git commits.";
    };
  };
}
