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
4. Deep-merges [`ai/claude/settings.json`](ai/claude/settings.json) into `~/.claude/settings.json` so Claude and Codex know which plugins to use
5. Deep-merges [`ai/pi/settings.json`](ai/pi/settings.json) into `~/.pi/agent/settings.json` to set the Pi package list
6. Updates each harness that's on `PATH` (`pi update --extensions`, `claude plugin marketplace update`, `codex plugin marketplace upgrade`)
7. In Codespaces, strips signing-related Git config sections; otherwise, if `SSH_PRIVATE_KEY_ED25519` is set, writes that key into `~/.ssh`
8. On Ona hosts, runs [`ona/setup.sh`](ona/setup.sh).
9. Ensures Zsh is listed in `/etc/shells` and sets it as the login shell (`chsh`)

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
- On Ona hosts, Ona's Claude integration writes root-owned files into `~vscode/.claude`; [`ona/fix-claude-remote-ownership.sh`](ona/fix-claude-remote-ownership.sh) watches the directory (via `inotifywait`, installed on demand) and hands ownership back to `vscode`

## AI

AI configuration and shared skills live under `ai/`:

```text
ai/
  plugin/
    skills/<skill>/    # Skill instructions and per-skill eval cases
    .claude-plugin/    # Existing plugin manifest
  evals/claude/        # Claude-specific evaluation runners and results
  docs/               # Design rationale and decisions
  claude/settings.json
  pi/settings.json     # Pi packages these dotfiles install
```

The root `.claude-plugin/marketplace.json` points at `ai/plugin/`, so personal
settings, framing docs, and eval runners stay outside the package. The current
installation and evaluation tools still target Claude Code.

### Installing the skills

Two channels — published packages, not home-directory Stow links. Codex reads the same `.claude-plugin/marketplace.json` Claude Code does.

- **As plugin:** the repo doubles as a Claude Code / Codex plugin marketplace, with [`ai/plugin/`](ai/plugin/) as the plugin root:

  ```
  /plugin marketplace add zabrador/dotfiles
  /plugin install zabrabot@zabrador
  ```

  ```sh
  codex plugin marketplace add zabrador/dotfiles
  codex plugin add zabrabot@zabrador
  ```

  Claude Code plugin skills invoke as `zabrabot:<skill-name>`.

- **With Pi:** `install.sh` writes the package list from [`ai/pi/settings.json`](ai/pi/settings.json) and runs `pi update --extensions`. To install only the skills, without the rest of these dotfiles:

  ```sh
  pi install git:github.com/zabrador/dotfiles
  pi update --extensions
  ```

  Pin an optional Git ref or tag in the install source when reproducibility matters. Add further packages to the repo list rather than with ad-hoc `pi install` — the next install replaces the home `packages` array with the repo's.

### Skills

- [`planning-commits`](ai/plugin/skills/planning-commits/SKILL.md) — conceptual and decompositional; helps structure work as a sequence of atomic commits.
- [`crafting-commits`](ai/plugin/skills/crafting-commits/SKILL.md) — the standard for what a good commit looks like: atomicity gut check, Conventional Commits format, and message honesty under amends and squashes.
- [`replanning-branches`](ai/plugin/skills/replanning-branches/SKILL.md) — retroactive variant of `planning-commits`; re-shapes an already-committed branch into a clean atomic sequence on a fresh branch off the merge-base.
- [`maintaining-prs`](ai/plugin/skills/maintaining-prs/SKILL.md) — PR maintenance; watches opt-in labeled PRs, triages CI failures, conflicts, and review feedback, and repairs whole stacks through a single cascade procedure.
- [`making-git-changes`](ai/plugin/skills/making-git-changes/SKILL.md) — execution mechanics for all git state changes (commit, amend, rebase, force-push, conflict resolution); routes to the planners when commit shape changes and checks every created or modified commit against `crafting-commits`.
- [`writing-comments`](ai/plugin/skills/writing-comments/SKILL.md) — the standard for TSDoc/docblocks and implementation comments: gates, interface vs. implementation volume, and durability. A standalone cluster; it does not govern README/ADR formats.

The skills coordinate across two git/PR clusters split by concern: atomic commits (`planning-commits` plans forward work and fix placement, `replanning-branches` takes over as the planner when reshaping a branch's already-committed history, `crafting-commits` holds the standard every commit must meet) and PR maintenance (`maintaining-prs` keeps open PRs green, consulting the atomic-commits skills for the shape of any repair). `making-git-changes` is the shared executor both clusters use for every git state change.

### Evals

Each skill may carry evals under its own directory (`ai/plugin/skills/<skill>/evals/`): `evals.json` holds behavioral task cases in the official [skill-creator](https://code.claude.com/docs/en/skills#evaluate-and-iterate-on-a-skill) schema, and `trigger-evals.json` holds routing cases (`{query, should_trigger}`). Run everything that exists for a skill (or `all`) with:

```sh
sh ai/evals/claude/run-evals.sh <skill-name>|all [runs-per-trigger-query]
```

or run one tier directly with `run-triggers.sh <skill> [runs]` / `run-behavioral.sh <skill>`. Trigger runs score a query as triggered when the Skill tool is consulted within the first few tool calls — deliberately looser than skill-creator's first-call-only contract, because the git skills mandate inspecting repository state before acting. Behavioral runs pair two headless sessions per case: an executor performs the task in a scratch workspace with the skill in hand, then a grader inspects the workspace and judges each expectation with cited evidence. Results are archived under `ai/evals/claude/results/` (gitignored) with the model pinned; treat rates statistically and re-baseline deliberately on model updates.

The primary workflow the commit skills support is plan-led with in-flight replanning: lay out the atomic commit sequence up front (during implementation planning), execute against it, and revise the plan when execution reveals drift. This avoids producing tangled working trees that resist clean splitting. See [`ai/docs/atomic-commits-framing.md`](ai/docs/atomic-commits-framing.md) for the commit-shaping cluster's design rationale, source articles, and decisions log, [`ai/docs/pr-maintenance-framing.md`](ai/docs/pr-maintenance-framing.md) for the PR-maintenance cluster and the whole-system ownership map, and [`ai/docs/commenting-framing.md`](ai/docs/commenting-framing.md) for the commenting skill.
