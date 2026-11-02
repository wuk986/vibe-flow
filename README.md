# vibe-flow

Kanban-getriebener Vibe-Coding-Workflow für Claude Code, für jedes Projekt. Das Board (GitHub Projects oder Forgejo) ist die Source of Truth: Issue, Plan, umgesetzte Arbeit und Testanleitung stehen dort.

```
/issue → Backlog → /work → In Progress → Review → (manuell prüfen) → /done → Done
                              ↑                 │
                              └── /work <n> <Feedback>
```

| Befehl | Was passiert |
|---|---|
| `/init-project` | CLAUDE.md (ggf. via `/init`), Board mit 4 Spalten, Labels, Test-/Lint-Befehl, Sprachen, optional graphify |
| `/issue <Beschreibung>` | Issue mit Ziel, Akzeptanzkriterien, Out of scope, Typ- und Area-Labels; nach deinem OK in Backlog |
| `/work [#n] [Feedback]` | Branch, Plan-Kommentar, test-first umsetzen, Self-Review, Tests + Lint grün, PR, Übergabe-Kommentar, Review |
| `/done [#n]` | Nach deiner manuellen Prüfung: Squash-Merge, Issue schließen, Done |

## Dateien

- [PRINCIPLES.md](PRINCIPLES.md): Coding-Prinzipien (nach [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)), die einzige Quelle dafür
- [CONVENTIONS.md](CONVENTIONS.md): Status, Labels, Sprachen, CLAUDE.md-Abschnitt
- [forges/](forges/): Adapter für GitHub (`gh`) und Forgejo (REST + Claude in Chrome für das Board)
- [skills/](skills/): die vier Skills

## Installation

```bash
git clone https://github.com/wuk986/vibe-flow.git ~/.claude/vibe-flow
```

Linux/macOS:

```bash
bash ~/.claude/vibe-flow/install.sh
```

Windows (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File $HOME\.claude\vibe-flow\install.ps1
```

Das Skript verlinkt die Skills nach `~/.claude/skills` (Symlinks bzw. Junctions). Liegt der Clone woanders, wird er zusätzlich als `~/.claude/vibe-flow` verlinkt. Update: `git pull`; ein neuer Skill braucht einen erneuten Lauf des Skripts.

## Voraussetzungen

- **GitHub:** `gh`, angemeldet, mit Scope `project` (`gh auth refresh -s project`)
- **Forgejo:** Umgebungsvariable `FORGEJO_TOKEN`, `curl`; Claude in Chrome für das Board
- **Optional:** [graphify](https://pypi.org/project/graphifyy/) (`uv tool install graphifyy`)
