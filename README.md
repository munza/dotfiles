# dotfiles

My Nix configuration for **macOS** — nix-darwin and home-manager from a single flake, set up so anyone can fork it and make it their own.

Built with [blueprint](https://github.com/numtide/blueprint) for auto-discovery of hosts and modules, [nix-darwin](https://github.com/nix-darwin/nix-darwin) for the system, [home-manager](https://github.com/nix-community/home-manager) for user-level config, [nix-homebrew](https://github.com/zhaofengli/nix-homebrew) for GUI apps, and [nh](https://github.com/nix-community/nh) for rebuilds with a package diff.

## Structure

```
.
├── flake.nix                  # Inputs & blueprint entry point
├── formatter.nix              # treefmt (nixfmt, deadnix, statix, shfmt, shellcheck)
├── devshell.nix               # gitleaks + formatter; turns on the pre-commit hook
├── .githooks/pre-commit       # blocks commits containing credentials
├── .github/workflows/         # CI: leak scan + nix flake check
├── lib/
│   └── default.nix            # flake.lib.mkModule — modules with use / merge / override
├── checks/                    # tests for lib and the secrets modules
├── modules/
│   ├── common/user.nix        # dotfiles.user — name and email, shared by both sides
│   ├── darwin/
│   │   ├── default.nix        # entry point a host imports
│   │   ├── nix.nix            # flakes, garbage collection, store optimisation
│   │   ├── homebrew.nix       # Homebrew via nix-homebrew; undeclared apps left alone
│   │   └── system.nix         # Touch ID for sudo, firewall, no guest login
│   └── home/                  # one module per tool, shared across hosts
│       ├── zsh.nix  git.nix  gh.nix  starship.nix  fzf.nix  zoxide.nix  eza.nix
│       ├── direnv.nix  nix-index.nix  nh.nix  fonts.nix
│       ├── ghostty.nix  zed.nix  neovim.nix  aerospace.nix  herdr.nix  colima.nix
│       ├── yazi.nix  lazygit.nix  btop.nix  clamav.nix
│       ├── secrets-env.nix    # secrets for one Mac — a local env file
│       ├── secrets-sops.nix   # secrets shared by several Macs — sops in the repo
│       └── config-links.nix   # links a host's config/ files into ~/.config
└── hosts/
    ├── example/               # copy this to make your own host
    │   ├── darwin-configuration.nix
    │   ├── users/example.nix
    │   └── config/            # editable starter files: starship, ghostty, nvim
    └── macmini/               # my Mac Mini (aarch64-darwin)
        ├── darwin-configuration.nix
        ├── users/munza/       # home-manager config, one file per tool
        └── config/nvim/       # my Neovim config
```

## What You Get

On by default — turn one off with `dotfiles.<name>.enable = false`:

- **zsh** — suggestions, highlighting, shared history, history search on ↑/↓
- **git** — your name and email, common settings and aliases, delta for diffs
- **gh** — GitHub CLI and git credential helper, with gh-dash
- **starship** — prompt, from an editable `starship.toml` in the host's `config/`
- **fzf, zoxide, eza** — fuzzy finding, jumping to directories, a better `ls` (`ll`)
- **direnv** — per-project environments, cached with nix-direnv
- **nix-index** — tells you which package has a missing command; `, <command>` runs it without installing
- **nh** — rebuild with a package diff and a confirm
- **fonts** — JetBrains Mono Nerd Font for the terminal and editor (`dotfiles.fonts.mono` to change it)
- **secrets.env** — loads `~/.config/secrets.env` into every shell

Opt in with `dotfiles.<name>.enable = true`:

- **ghostty**, **zed**, **neovim** — terminal and editors
- **aerospace** — tiling window manager
- **herdr** — terminal session manager
- **colima** — Docker in a lightweight VM, with `docker`, `docker compose` and `docker buildx`
- **yazi**, **lazygit**, **btop** — file manager, git TUI, resource monitor
- **clamav** — on-demand virus scans (`clam-update`, `clam-scan`)

On the system side: Nix with flakes and garbage collection, Homebrew installed for you, and Touch ID for `sudo` (inside tmux and herdr too), firewall on, no guest login.

## Quick Start

On a Mac with Apple silicon:

1. **Install the command line tools** — Homebrew and Neovim's parsers need a compiler:

   ```sh
   xcode-select --install
   ```

2. **Install Nix:**

   ```sh
   sh <(curl -L https://nixos.org/nix/install)
   ```

3. **Clone your fork** into `~/.dotfiles` — `nh` and the editable config files expect it there:

   ```sh
   git clone https://github.com/<you>/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

4. **Copy the example host** — named after your Mac, with a user file named after your login:

   ```sh
   cp -r hosts/example "hosts/$(scutil --get LocalHostName)"
   mv "hosts/$(scutil --get LocalHostName)/users/example.nix" \
      "hosts/$(scutil --get LocalHostName)/users/$(whoami).nix"
   ```

5. **Customise** — your name and email in `hosts/<mac-name>/darwin-configuration.nix`, and the apps you want in `hosts/<mac-name>/users/<login>.nix`.

6. **Track the new host** — flakes only see files git knows about:

   ```sh
   git add hosts
   ```

7. **Move the installer's shell files aside** — the Nix installer adds a few lines to these, and nix-darwin takes them over but won't overwrite changes it didn't make:

   ```sh
   sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
   sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
   ```

8. **Build & switch** — the first time, before nix-darwin is installed:

   ```sh
   sudo nix --extra-experimental-features 'nix-command flakes' \
     run --inputs-from . 'nix-darwin#darwin-rebuild' -- \
     switch --flake ".#$(scutil --get LocalHostName)"
   ```

Then open a new terminal. Files already in the way, like an old `~/.zshrc`, go to the Trash rather than being overwritten.

`hosts/macmini` is my own Mac — delete it in your fork, or keep it around as a fuller example.

## Daily Use

```sh
nh darwin switch --ask            # build, show the package diff, switch on yes
nh darwin switch --update --ask   # same, after updating flake inputs
nh search <term>                  # find a package
nh clean all --keep-since 30d     # delete old generations
sudo darwin-rebuild --rollback    # back to the previous generation
```

All of these work from any directory. In zsh, quote anything with a `#` in it (`'.#my-mac'`) — `#` is a glob character there.

## Configuration Guide

### Hosts

A host is two files:

- `hosts/<mac-name>/darwin-configuration.nix` — the machine: Homebrew apps, macOS settings
- `hosts/<mac-name>/users/<login>.nix` — your home: which apps are on, and their settings

The user file can also be a folder, with a `home-configuration.nix` and one file per tool — that's how [`hosts/macmini`](hosts/macmini/users/munza) is laid out.

```nix
# darwin-configuration.nix
homebrew.casks = [ "firefox" "raycast" ];
system.defaults.dock.autohide = true;
```

### Defaults: Use, Merge or Override

Every module ships defaults, and for each one a host chooses:

```nix
{ lib, ... }:
{
  # use them — do nothing

  # merge — a value replaces that one default, a list is added to
  programs.git.settings.pull.rebase = false;
  programs.git.ignores = [ "*.log" ];

  # override — drop the module's defaults, keep only what it needs to work
  dotfiles.zsh.defaults = false;
  programs.zsh.autosuggestion.enable = true;

  # replace a whole list
  programs.zsh.setOptions = lib.mkForce [ "AUTO_PUSHD" ];
}
```

The modules are built on [`flake.lib.mkModule`](lib/default.nix), so a new one gets the same behaviour for free.

### Editable Files

Some config is nicer to edit by hand than through Nix. Each host has a `config/` folder next to its other files — Starship's config and the Neovim config live there and are linked into `~/.config`, so you edit them in place, no rebuild. Ghostty also reads `config/ghostty/config` on top of its Nix settings. Zed, Herdr and Colima keep their own settings files writable, with your Nix settings merged in on every rebuild.

### Secrets

Two ways, depending on how many Macs need them:

- **One Mac** — put `KEY=value` lines in `~/.config/secrets.env`, outside the repo, and `chmod 600` it. Every zsh loads it.
- **Several Macs** — keep [sops](https://github.com/getsops/sops)-encrypted JSON files in the repo, decrypted at login with each Mac's SSH key. See [`modules/home/secrets-sops.nix`](modules/home/secrets-sops.nix).

## Development

```sh
nix fmt            # format everything
nix flake check    # run the checks and evaluate every host
```

`direnv allow` in the repo turns on a pre-commit hook that blocks commits containing credentials. CI runs the same leak scan and `nix flake check` on every push.

## Licence

[MIT](LICENSE)
