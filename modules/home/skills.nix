# Agent skills, installed with the `skills` CLI (skills.sh) on every switch, so
# each one is refreshed to the latest from its repo. They land in
# ~/.agents/skills, which pi and other agents read, and are linked into
# ~/.claude/skills unless `claude = false`. Skills other tools install (Orca,
# herdr) are left alone. Removing an entry doesn't uninstall the skill:
#   skills remove -g <name>
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.skills;

  install =
    entry:
    let
      agents = [ "pi" ] ++ lib.optional entry.claude "claude-code";
      args = [
        "add"
        entry.source
        "-g"
        "-y"
        "-s"
      ]
      ++ entry.skills
      ++ lib.concatMap (agent: [
        "-a"
        agent
      ]) agents;
    in
    ''
      run ${lib.getExe pkgs.skills} ${lib.escapeShellArgs args} > /dev/null \
        || warnEcho "skills: could not install ${entry.source}; keeping what is there"
    '';
in
{
  options.dotfiles.skills = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          source = lib.mkOption {
            type = lib.types.str;
            example = "anthropics/skills";
            description = "Repo the skills come from, in any form `skills add` takes.";
          };
          skills = lib.mkOption {
            type = lib.types.nonEmptyListOf lib.types.str;
            example = [ "skill-creator" ];
            description = "Skills to install from it.";
          };
          claude = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Also link them into ~/.claude/skills for Claude Code.";
          };
        };
      }
    );
    default = [ ];
    description = "Agent skills to install, and refresh on every switch.";
  };

  config = lib.mkIf (cfg != [ ]) {
    # The CLI fetches repos with git; a failed fetch warns instead of failing the
    # switch. XDG_STATE_HOME keeps its lock file where your shell's `skills` looks.
    home.activation.agentSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      (
        export DISABLE_TELEMETRY=1 XDG_STATE_HOME="${config.xdg.stateHome}" PATH="${pkgs.git}/bin:$PATH"
        ${lib.concatMapStrings install cfg}
      )
    '';
  };
}
