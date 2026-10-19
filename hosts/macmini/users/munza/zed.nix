# Zed with vim mode and a space leader, on top of the module's defaults.
{ config, pkgs, ... }:
let
  # q closes a panel while you're in it.
  closeWithQ = context: action: {
    inherit context;
    bindings.q = action;
  };
in
{
  # For the Lua formatter below.
  programs.zed-editor.extraPackages = [ pkgs.stylua ];

  programs.zed-editor.userKeymaps = [
    {
      context = "Editor";
      bindings = {
        ctrl-h = [
          "workspace::ActivatePaneInDirection"
          "Left"
        ];
        ctrl-l = [
          "workspace::ActivatePaneInDirection"
          "Right"
        ];
        ctrl-k = [
          "workspace::ActivatePaneInDirection"
          "Up"
        ];
        ctrl-j = [
          "workspace::ActivatePaneInDirection"
          "Down"
        ];
      };
    }
    {
      context = "Editor && vim_mode == normal";
      bindings = {
        # Panels: Toggle (not ToggleFocus, which never hides) opens and focuses
        # a panel, and closes it when pressed again from inside.
        "space a a" = "agent::Toggle";
        "space f e" = "project_panel::Toggle";
        "space g g" = "git_panel::Toggle";
        "space d d" = "debug_panel::Toggle";
        "space t t" = "terminal_panel::Toggle";

        # Code
        "g d" = "editor::GoToDefinition";
        "g D" = "editor::GoToDefinitionSplit";
        "g i" = "editor::GoToImplementation";
        "g r" = "editor::FindAllReferences";
        "space c a" = "editor::ToggleCodeActions";
        "space c r" = "editor::Rename";
        "space c f" = "editor::Format";

        # Diagnostics
        "] d" = "editor::GoToDiagnostic";
        "[ d" = "editor::GoToPreviousDiagnostic";
        "space x x" = "diagnostics::Deploy";

        # Git
        "space g d" = "git::Diff";
        "space g b" = "editor::ToggleGitBlameInline";
        "] h" = "editor::GoToHunk";
        "[ h" = "editor::GoToPreviousHunk";
        "space g f" = "git::Fetch";
        "space g p" = "git::Push";
        "space g shift-p" = "git::ForcePush";
        "space g l" = "git::Pull";
        "space g shift-l" = "git::PullRebase";
        "space g s" = "git::StageAll";
        "space g u" = "git::UnstageAll";

        # Buffers and files
        shift-h = "pane::ActivatePreviousItem";
        shift-l = "pane::ActivateNextItem";
        ctrl-s = "workspace::Save";
        "space f f" = "file_finder::Toggle";
      };
    }
    {
      context = "Editor && vim_mode == visual";
      bindings."g c" = "editor::ToggleComments";
    }
    {
      # Space moves right in Zed's vim keymap, which closes which-key before it
      # shows; unbinding it makes space a pure leader key.
      context = "VimControl && !menu";
      bindings.space = null;
    }
    {
      context = "Workspace";
      bindings = {
        "ctrl-w w" = "workspace::FocusNextPart";
        "ctrl-w shift-w" = "workspace::FocusPreviousPart";
        "ctrl-\\" = "terminal_panel::Toggle";
      };
    }
    {
      # ctrl-j/k in lists, matching the pane keys above.
      context = "menu";
      bindings = {
        ctrl-j = "menu::SelectNext";
        ctrl-k = "menu::SelectPrevious";
      };
    }
    # `!Editor` and `not_editing` keep q from firing while typing.
    (closeWithQ "ProjectPanel && not_editing" "project_panel::Toggle")
    (closeWithQ "GitPanel && !Editor" "git_panel::Toggle")
    (closeWithQ "AgentPanel && !Editor" "agent::Toggle")
    (closeWithQ "DebugPanel && !Editor" "debug_panel::Toggle")
  ];

  programs.zed-editor.userSettings = {
    theme = {
      mode = "system";
      light = "Dayfox - opaque";
      dark = "Nightfox - opaque";
    };
    ui_font_family = config.dotfiles.fonts.mono.name;
    ui_font_size = 16;
    buffer_font_size = 15;
    agent_ui_font_size = 16;
    agent_buffer_font_size = 15;
    use_system_window_tabs = true;
    show_whitespaces = "trailing";
    indent_guides = {
      enabled = true;
      coloring = "indent_aware";
    };

    vim_mode = true;
    vim = {
      cursor_shape = {
        normal = "hollow";
        insert = "bar";
      };
      toggle_relative_line_numbers = true;
    };
    relative_line_numbers = "enabled";
    which_key = {
      enabled = true;
      delay_ms = 200;
    };

    tab_size = 2;
    format_on_save = "on";
    vertical_scroll_margin = 4;
    horizontal_scroll_margin = 8;
    colorize_brackets = true;
    code_lens = "menu";
    toolbar.code_actions = true;
    show_signature_help_after_edits = false;
    auto_signature_help = false;
    show_edit_predictions = true;

    redact_private_values = true;
    session.trust_all_worktrees = true;

    cli_default_open_behavior = "existing_window";
    gutter.line_numbers = true;
    status_bar.show_active_file = false;
    debugger.dock = "bottom";
    terminal.dock = "bottom";
    file_finder.modal_max_width = "large";
    file_scan_exclusions = [
      "**/.git"
      "**/.svn"
      "**/.hg"
      "**/CVS"
      "**/.DS_Store"
      "**/Thumbs.db"
      "**/.classpath"
      "**/.settings"
      "**/node_modules"
      "**/dist"
      "**/out"
      "**/.next"
      "**/.turbo"
    ];

    project_panel = {
      hide_hidden = false;
      hide_gitignore = false;
      hide_root = true;
      folder_indicator = "chevron";
      file_icons = true;
      entry_spacing = "comfortable";
      git_status_indicator = true;
      diagnostic_badges = true;
      show_diagnostics = "errors";
      auto_fold_dirs = false;
    };

    git.inline_blame.enabled = true;
    git_panel = {
      collapse_untracked_diff = true;
      show_count_badge = true;
      diff_stats = true;
      file_icons = true;
      tree_view = true;
      dock = "right";
    };

    tabs = {
      file_icons = true;
      git_status = true;
      show_diagnostics = "errors";
    };

    edit_predictions = {
      model = "subtle";
      provider = "copilot";
    };
    agent = {
      dock = "left";
      use_modifier_to_send = true;
      single_file_review = true;
      agent_follow = true;
    };

    languages.Lua.formatter.external = {
      command = "stylua";
      arguments = [
        "--syntax=Lua54"
        "--respect-ignores"
        "--stdin-filepath"
        "{buffer_path}"
        "-"
      ];
    };
  };
}
