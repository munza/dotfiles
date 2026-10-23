# Global rules

## This machine

- macOS, managed by Nix (nix-darwin + home-manager) from ~/.dotfiles.
- Don't install tools globally (brew install, npm -g, pip install --user, nix-env -i). Use the project's dev shell, `nix run` or `, <cmd>` for one-offs, or tell me what to add to the dotfiles.
- Use `trash` instead of `rm -rf` outside /tmp and your own scratch files.

## Git

- Never commit unless I ask. Show what changed and wait for my go-ahead.
- Never push unless I ask. Always `git pull` before pushing.
- Never rewrite history that's already pushed (force push, rebase of pushed commits) without asking.

## Working style

- Ask before anything hard to undo: deleting data, migrations, changing shared config, sending anything to an external service.
- If tests or checks fail, say so with the output. Don't claim success you haven't verified.
- Don't hard-wrap Markdown: one line per paragraph or list item.
