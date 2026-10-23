# Pi settings, merged into ~/.pi/agent/settings.json on rebuild.
{
  programs.pi-coding-agent.settings = {
    packages = [
      "npm:@juicesharp/rpiv-ask-user-question"
      "npm:@juicesharp/rpiv-todo"
      "npm:@narumitw/pi-usage"
      "npm:@plannotator/pi-extension"
      "npm:pi-intercom"
      "npm:pi-subagents"
      "npm:pi-web-access"
    ];
    defaultThinkingLevel = "medium";
    theme = "system";
  };
}
