# Herdr look and plugin keys. Plugin actions are <plugin_id>.<action_id>
# (`herdr plugin action list`); herdr's defaults already use prefix+e and prefix+o.
{
  programs.herdr.settings = {
    theme = {
      name = "tokyo-night";
      auto_switch = true;
      dark_name = "tokyo-night";
      light_name = "tokyo-night-day";
    };

    ui = {
      status_indicators = "dots";
      show_agent_labels_on_pane_borders = true;
      toast.delivery = "terminal";
      sound.enabled = true;
    };

    keys.command = [
      {
        key = "cmd+r";
        type = "plugin_action";
        command = "persiyanov.reviewr.toggle";
        description = "review pane";
      }
      {
        key = "cmd+e";
        type = "plugin_action";
        command = "chmarax.herdr-nvim.toggle";
        description = "nvim sidebar";
      }
      {
        key = "prefix+f";
        type = "plugin_action";
        command = "chmarax.herdr-nvim.pick-file";
        description = "open file from agent output";
      }
      {
        key = "cmd+k";
        type = "plugin_action";
        command = "herdr-bar.open";
        description = "command bar";
      }
    ];
  };
}
