# dotfiles

## Getting Started

### System Requirements

- [`zsh`](https://www.zsh.org)
- [`git`](https://git-scm.com)
- [`asdf`](https://github.com/asdf-vm/asdf)
- A package manager: [Homebrew](https://brew.sh) or `apt` (used to install [GNU Stow](https://www.gnu.org/software/stow/) if missing)
- `sudo` (login-shell setup; also `apt` package installs)

### Installation

Clone into `~/.dotfiles`, then run the installer with an absolute path so the working directory does not matter:

```sh
git clone git@github.com:zabrador/dotfiles.git ~/.dotfiles
sh ~/.dotfiles/install.sh
```

The installer:

1. Installs Stow (via brew or apt) if needed
2. Clones [Antigen](https://github.com/zsh-users/antigen) into `~/.antigen` if missing
3. **Removes any existing home-directory files** that would collide with the Stow package, then links the package with Stow
4. Links each Claude skill from [`claude/skills/`](claude/skills/) into `~/.claude/skills/` (**removing any same-named skill already there**; other local skills are left alone)
5. In Codespaces, strips signing-related Git config sections; otherwise, if `SSH_PRIVATE_KEY_ED25519` is set, writes that key into `~/.ssh`
6. On Ona hosts, starts a background watcher that returns ownership of files under `~vscode/.claude` to the `vscode` user
7. Ensures Zsh is listed in `/etc/shells` and sets it as the login shell (`chsh`)

### What gets linked

The `shell/` Stow package maps these files into `~/`:

| Repo path | Home path |
| --- | --- |
| `shell/.zshrc` | `~/.zshrc` |
| `shell/.gitconfig` | `~/.gitconfig` |
| `shell/.gitignore_global` | `~/.gitignore_global` |
| `shell/.asdfrc` | `~/.asdfrc` |

The `claude/skills` Stow package links each skill directory into `~/.claude/skills/` (per-skill symlinks, not one folded directory link), so Claude Code picks the skills up as personal skills on every machine while locally created skills can live alongside them. Because the links point into the repo, editing a skill through `~/.claude/skills/` edits the repo's working tree.

### Assumptions

- Local (non-SSH) sessions use `code-insiders` as `$EDITOR` and as Git's diff/merge tool
- On Ona hosts, secrets from `/etc/profile.d/ona-secrets.sh` are sourced into Zsh
- On Ona hosts, Ona's Claude integration writes root-owned files into `~vscode/.claude`; [`ona/fix-claude-remote-ownership.sh`](ona/fix-claude-remote-ownership.sh) watches the directory (via `inotifywait`, installed on demand) and hands ownership back to `vscode`

## Claude

Personal Claude Code configuration.

### Skills

- [`planning-commits`](claude/skills/planning-commits/SKILL.md) — conceptual and decompositional; helps structure work as a sequence of atomic commits.
- [`committing-changes`](claude/skills/committing-changes/SKILL.md) — execution-only; gut-checks the diff, writes a Conventional Commits message, runs the commit.
- [`replanning-branches`](claude/skills/replanning-branches/SKILL.md) — retroactive variant of `planning-commits`; re-shapes an already-committed branch into a clean atomic sequence on a fresh branch off the merge-base.
- [`maintaining-prs`](claude/skills/maintaining-prs/SKILL.md) — PR maintenance; watches opt-in labeled PRs, triages CI failures, conflicts, and review feedback, and repairs whole stacks through a single cascade procedure.
- [`rewriting-history`](claude/skills/rewriting-history/SKILL.md) — execution doctrine for mutating git history safely (rebase, amend, force-push, conflict resolution); consulted by `maintaining-prs` and `replanning-branches`, and fires directly on ad-hoc rebase work.

The skills coordinate across two clusters split by concern: atomic commits (`planning-commits` plans forward work and fix placement, `replanning-branches` takes over as the planner when reshaping a branch's already-committed history, `committing-changes` executes forward commits) and PR maintenance (`maintaining-prs` keeps open PRs green, consulting the atomic-commits skills for the shape of any repair). `rewriting-history` is the shared executor both clusters use for history mutation.

The primary workflow the commit skills support is plan-led with in-flight replanning: lay out the atomic commit sequence up front (typically in plan mode), execute against it, and revise the plan when execution reveals drift. This avoids producing tangled working trees that resist clean splitting. See [`claude/docs/atomic-commits-framing.md`](claude/docs/atomic-commits-framing.md) for the commit-shaping cluster's design rationale, source articles, and decisions log, and [`claude/docs/pr-maintenance-framing.md`](claude/docs/pr-maintenance-framing.md) for the PR-maintenance cluster and the whole-system ownership map.
