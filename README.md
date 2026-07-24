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
4. In Codespaces, strips signing-related Git config sections; otherwise, if `SSH_PRIVATE_KEY_ED25519` is set, writes that key into `~/.ssh`
5. Ensures Zsh is listed in `/etc/shells` and sets it as the login shell (`chsh`)

### What gets linked

The `shell/` Stow package maps these files into `~/`:

| Repo path | Home path |
| --- | --- |
| `shell/.zshrc` | `~/.zshrc` |
| `shell/.gitconfig` | `~/.gitconfig` |
| `shell/.gitignore_global` | `~/.gitignore_global` |
| `shell/.asdfrc` | `~/.asdfrc` |

### Assumptions

- Local (non-SSH) sessions use `code-insiders` as `$EDITOR` and as Git's diff/merge tool
- On Ona hosts, secrets from `/etc/profile.d/ona-secrets.sh` are sourced into Zsh

## Claude

Personal Claude Code configuration.

### Skills

- [`planning-commits`](claude/skills/planning-commits/SKILL.md) — conceptual and decompositional; helps structure work as a sequence of atomic commits.
- [`committing-changes`](claude/skills/committing-changes/SKILL.md) — execution-only; gut-checks the diff, writes a Conventional Commits message, runs the commit.
- [`replanning-branches`](claude/skills/replanning-branches/SKILL.md) — retroactive variant of `planning-commits`; re-shapes an already-committed branch into a clean atomic sequence on a fresh branch off the merge-base.

The three coordinate: `committing-changes` is the universal executor; `planning-commits` plans forward work; `replanning-branches` takes over as the planner when reshaping a branch's already-committed history.

The primary workflow the skills support is plan-led with in-flight replanning: lay out the atomic commit sequence up front (typically in plan mode), execute against it, and revise the plan when execution reveals drift. This avoids producing tangled working trees that resist clean splitting. See [`claude/docs/atomic-commits-framing.md`](claude/docs/atomic-commits-framing.md) for the design rationale, source articles, and decisions log behind the cluster.
