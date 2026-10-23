# Pi settings, merged into ~/.pi/agent/settings.json on rebuild.
{
  programs.pi-coding-agent.settings = {
    packages = [ "npm:pi-web-access" ];
    defaultThinkingLevel = "medium";
  };
}
