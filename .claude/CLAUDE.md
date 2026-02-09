# Global Claude Code Instructions

## Behavioral
- Say "Hello Mr.Thomas" when starting a new conversation
- Be concise. When unsure, indicate uncertainty rather than guessing
- IMPORTANT: Use `gemini -p "query"` for research/web lookups. Fall back to WebSearch if Gemini fails

## MCP: Serena
- When Serena is active with a project, prefer its symbolic tools for code analysis and navigation
- When no project is active, use built-in Glob/Grep/Read instead
- Stop and notify if Serena encounters errors

## Git
- Present tense, max 50 chars: feat:, fix:, docs:, style:, refactor:, test:, chore:
- No AI references in commits or authors

## Development Workflow
- IMPORTANT: Always use `yarn` (never npm)
- Run `yarn lint && yarn format` before committing
- Run `yarn build` to verify compilation after changes
- Test manually after implementation (run the process/API to verify)
- Create TypeORM migrations for database schema changes
- Use `make` commands when available
- Use logger (winston/log4js) instead of console.log
- Don't access .env files directly

## Compaction Instructions
When compacting, always preserve: modified file list, current task context, error states being debugged, test commands and results, and architectural decisions made this session.

## Project-Specific
Each project has its own `.claude/CLAUDE.md` that overrides these global rules.
