# Tawsif's Mac mini. A real host built on the same modules as hosts/example;
# see that file for how to make your own.
{
  flake,
  inputs,
  perSystem,
  ...
}:
{
  imports = [ flake.darwinModules.default ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = "macmini";

  dotfiles.user = {
    fullName = "Tawsif Aqib";
    email = "hello@tawsifaqib.com";
  };

  environment.systemPackages =
    (with perSystem.nixpkgs; [
      # Everyday CLI
      curl
      httpie
      jq
      yq-go # jq for YAML and TOML
      gping
      tealdeer
      tree
      watchexec # rerun a command on file changes
      hyperfine # benchmark commands
      bat
      ripgrep
      dust
      duf
      procs
      trash-cli
      gitleaks
      tuios # on trial next to herdr

      # Containers (docker itself comes with the colima module)
      kubectl
      k9s
      lazydocker

      # Build environments
      devenv
      openssl
      pkgconf

      # Languages and their tools
      beamPackages.elixir_1_20
      go
      golangci-lint
      gopls
      gotools
      delve
      python3
      uv
      rustc
      cargo
      clippy
      rustfmt
      rust-analyzer
      cargo-watch
      nodejs
      nixd
      nixfmt

      # Security and local AI
      nmap
      llama-cpp
    ])
    ++ (with perSystem.llm-agents; [
      claude-code
    ]);

  # Prebuilt binaries for devenv projects and the llm-agents packages.
  nix.settings = {
    extra-substituters = [
      "https://devenv.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  homebrew = {
    taps = [ "stablyai/orca" ];
    casks = [
      "appcleaner"
      "bruno"
      "claude"
      "discord"
      "firefox"
      "iina"
      "keka"
      "lightcraft"
      "linear"
      "llama-app"
      "opensuperwhisper"
      "pdfcraft"
      "proton-drive"
      "proton-pass"
      "protonvpn"
      "raycast"
      "slack"
      "stablyai/orca/orca"
      "tablepro"
      "tailscale-app"
      "vectorcraft"
    ];
    # Everything installed is declared above, so rebuilds may remove the rest.
    onActivation = {
      upgrade = true;
      cleanup = "zap";
    };
  };
  nix-homebrew = {
    enableRosetta = true;
    # Taps pinned as flake inputs: updated with `nix flake update`, read-only otherwise.
    # Keys are GitHub repos (user/homebrew-name), not tap names.
    mutableTaps = false;
    taps."stablyai/homebrew-orca" = inputs.homebrew-orca;
  };

  # Caps Lock is only ever pressed by accident; Esc is more useful.
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  system.startup.chime = false;

  networking.applicationFirewall = {
    allowSigned = true;
    allowSignedApp = false;
    blockAllIncoming = false;
  };

  system.defaults = {
    dock = {
      autohide = true;
      mineffect = "scale";
      minimize-to-application = true;
      show-recents = false;
      persistent-apps = [ ];
      # No hot corners.
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXDefaultSearchScope = "SCcf"; # search the current folder
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv"; # column view
      NewWindowTarget = "Home";
      QuitMenuItem = true;
      ShowExternalHardDrivesOnDesktop = false;
      ShowRemovableMediaOnDesktop = false;
      ShowPathbar = true;
      ShowStatusBar = true;
      _FXSortFoldersFirst = true;
      _FXSortFoldersFirstOnDesktop = false;
    };

    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyleSwitchesAutomatically = true;
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;
      AppleShowAllFiles = true; # in open and save dialogs too
      AppleTemperatureUnit = "Celsius";
      AppleScrollerPagingBehavior = true;
      AppleShowScrollBars = "Automatic";
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSDisableAutomaticTermination = false;
      NSTextShowsControlCharacters = true;
      "com.apple.keyboard.fnState" = false;
      "com.apple.mouse.tapBehavior" = 1; # tap to click
      "com.apple.sound.beep.feedback" = 0;
      "com.apple.swipescrolldirection" = false;
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

    WindowManager = {
      AppWindowGroupingBehavior = false;
      EnableTiledWindowMargins = false;
    };

    screencapture.location = "~/Pictures/Screenshots";
  };

  # Set once at install time; never bump on upgrade.
  system.stateVersion = 6;
}
