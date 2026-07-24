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

- [`planning-commits`](claude/skills/planning-commits/SKILL.md) — conceptual and decompositional; helps structure work as a sequence of atomic commits.
- [`committing-changes`](claude/skills/committing-changes/SKILL.md) — execution-only; gut-checks the diff, writes a Conventional Commits message, runs the commit.
- [`replanning-branches`](claude/skills/replanning-branches/SKILL.md) — retroactive variant of `planning-commits`; re-shapes an already-committed branch into a clean atomic sequence on a fresh branch off the merge-base.

The three coordinate: `committing-changes` is the universal executor; `planning-commits` plans forward work; `replanning-branches` takes over as the planner when reshaping a branch's already-committed history.

The primary workflow the skills support is plan-led with in-flight replanning: lay out the atomic commit sequence up front (typically in plan mode), execute against it, and revise the plan when execution reveals drift. This avoids producing tangled working trees that resist clean splitting. See [`claude/docs/atomic-commits-framing.md`](claude/docs/atomic-commits-framing.md) for the design rationale, source articles, and decisions log behind the cluster.
