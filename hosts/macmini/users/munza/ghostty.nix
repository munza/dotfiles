# Ghostty look on top of the module's defaults.
{
  programs.ghostty.settings = {
    theme = "dark:Nightfox,light:Dayfox";
    font-size = 15;
    font-feature = "+calt,+liga,+dlig,+ss01,+ss02,+ss03,+ss04,+ss05";

    # No tab bar or title bar; the window stays resizable from its edges.
    macos-titlebar-style = "hidden";

    # Ghostty's ⌘K clears the screen; unbinding it passes it to herdr's command bar.
    keybind = [ "super+k=unbind" ];

    clipboard-read = "allow";
    clipboard-write = "allow";
  };
}
