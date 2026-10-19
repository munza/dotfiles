# AeroSpace on top of the module's bindings: small gaps between windows, and
# apps that misbehave when tiled float instead.
{
  programs.aerospace.settings = {
    gaps.inner = {
      horizontal = 8;
      vertical = 8;
    };

    on-window-detected =
      map
        (app: {
          "if".app-name-regex-substring = app;
          run = [ "layout floating" ];
        })
        [
          "finder"
          "opensuperwhisper"
        ];
  };
}
