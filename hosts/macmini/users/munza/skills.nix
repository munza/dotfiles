# Agent skills, refreshed on every switch. Orca and herdr manage their own.
{
  dotfiles.skills = [
    {
      source = "vercel-labs/skills";
      skills = [ "find-skills" ];
    }
    {
      source = "vercel-labs/agent-skills";
      skills = [ "web-design-guidelines" ];
    }
    {
      source = "pbakaus/impeccable";
      skills = [ "impeccable" ];
    }
    {
      source = "mattpocock/skills";
      skills = [
        "diagnosing-bugs"
        "tdd"
        "codebase-design" # tdd's vocabulary
        "grilling"
        "prototype"
        "writing-for-agents"
        "wizard"
        "pr"
      ];
    }
    {
      # Claude Code gets skill-creator from the claude.ai account.
      source = "anthropics/skills";
      skills = [
        "skill-creator"
        "webapp-testing"
        "mcp-builder"
      ];
      claude = false;
    }
  ];
}
