# Two-line prompt: path, git and nix-shell on the first line, the prompt on the second.
{
  # Nerd Font glyphs instead of emoji for every module's icon.
  programs.starship.presets = [ "nerd-font-symbols" ];

  programs.starship.settings = {
    format = ''
      $username$hostname$directory$git_branch$git_status$nix_shell$cmd_duration
      $character'';

    username.format = "[$user]($style) ";
    hostname = {
      ssh_only = true;
      format = "[@$hostname]($style) ";
    };
    directory = {
      truncation_length = 3;
      truncate_to_repo = true;
    };
    git_branch.format = "[$symbol$branch]($style) ";
    git_status.format = "([$all_status$ahead_behind]($style) )";
    nix_shell.format = "[$symbol$state]($style) ";
    cmd_duration = {
      min_time = 2000;
      format = "[$duration]($style) ";
    };
    character = {
      success_symbol = "[❯](green)";
      error_symbol = "[❯](red)";
    };
  };
}
