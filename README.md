# dotfiles

## Getting Started

### System Requirements

- [`zsh`](https://www.zsh.org)
- [`git`](https://git-scm.com)
- [`asdf`](https://github.com/asdf-vm/asdf)

### Installation

```sh
git clone git@github.com:zabrador/dotfiles.git ~/.dotfiles
sh .dotfiles/install.sh
```

## Claude

Personal Claude Code configuration.

### Skills

- [`commit-planning`](claude/skills/commit-planning/SKILL.md) — conceptual and decompositional; helps structure work as a sequence of atomic commits.
- [`atomic-commits`](claude/skills/atomic-commits/SKILL.md) — execution-only; gut-checks the diff, writes a Conventional Commits message, runs the commit.

The primary workflow the skills support is commit-as-you-go: pause at natural breakpoints during the work and commit before continuing, which avoids producing tangled working trees that resist clean splitting. See [`claude/docs/atomic-commits-framing.md`](claude/docs/atomic-commits-framing.md) for the design rationale, source articles, and decisions log behind the cluster.
