# Token Policy

This file defines the token optimization policies for AI agent rule files in the Monitored App project.

- Prefer loading canonical files instead of duplicating the same long guidance.
- If conflict exists between files, `CLAUDE.md` and `.claude/rules/*` win.