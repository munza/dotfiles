# Helpers exposed as flake.lib.
{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;

  # Priority 900: a plain host value (100) replaces it, and it never clashes
  # with the mkDefault (1000) that nixpkgs and home-manager use for their own.
  soft = lib.mkOverride 900;

  # Softens each setting, so a host value replaces it. Lists keep normal
  # priority, so host lists are added to them. Values already wrapped
  # (mergeable, mkForce, ...) stay as written; mkIf is looked into.
  softDefaults =
    value:
    if builtins.isList value then
      value
    else if builtins.isAttrs value then
      if lib.isType "if" value then
        value // { content = softDefaults value.content; }
      else if value ? _type then
        value
      else if lib.isDerivation value then
        soft value
      else
        lib.mapAttrs (_: softDefaults) value
    else
      soft value;

  # glue and defaults may be attrsets or module-style functions ({ pkgs, ... }: ...).
  call = f: args: if builtins.isFunction f then f args else f;
  argsOf = f: if builtins.isFunction f then builtins.functionArgs f else { };
in
{
  inherit softDefaults;

  # Keeps a value at normal priority, so it merges with the host's instead of
  # being replaced, and puts it first, e.g. shell code: initContent = mergeable "...";
  mergeable = lib.mkBefore;

  # A module with two switches, both on by default:
  #   dotfiles.<name>.enable    the whole module
  #   dotfiles.<name>.defaults  just its default settings
  # `glue` is what the module needs to work; `defaults` is its opinions. A host
  # can use the defaults, merge with them (set values: a value replaces one
  # default, a list is added to), or override them (defaults = false).
  mkModule =
    {
      name,
      description,
      enable ? true,
      imports ? [ ],
      glue ? { },
      defaults ? { },
    }:
    lib.setFunctionArgs (
      args:
      let
        cfg = args.config.dotfiles.${name};
      in
      {
        inherit imports;

        options.dotfiles.${name} = {
          enable = lib.mkEnableOption description // {
            default = enable;
          };
          defaults = lib.mkEnableOption "this module's default settings for ${description}" // {
            default = true;
          };
        };

        config = lib.mkIf cfg.enable (
          lib.mkMerge [
            (softDefaults (call glue args))
            (lib.mkIf cfg.defaults (softDefaults (call defaults args)))
          ]
        );
      }
    ) (argsOf glue // argsOf defaults // { config = false; });
}
