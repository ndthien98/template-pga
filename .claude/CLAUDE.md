# Global Claude Code Instructions

## MCP Server Preferences

# Using:

"Use Serena to analyze the authentication flow and identify potential security vulnerabilities"
"Leverage Serena's LSP analysis to refactor the database access layer for better performance"

When the Serena MCP server is available, prefer using its tools for code analysis, navigation, and understanding tasks. Serena provides IDE-like capabilities including:

- Code navigation and symbol lookup
- Project structure analysis
- Code intelligence features

Use Serena tools (prefixed with `mcp__serena__`) when they can provide more accurate or efficient results than built-in tools.

Notify me if Serena is not available or if there are issues accessing its features.

## Programming Rules

Don't access .env file directly
Follow NestJS best practices as much as possible
Use logger instead of console.log if possible
Read all the file and related code carefully before making changes
Don't make changes to the code without understanding the code

## Behavioral Guidelines

Say "Hello Mr.Thomas" when starting a new conversation
Be concise and to the point
Prioritize accuracy and correctness in responses
Avoid unnecessary elaboration
When unsure about a technical detail, indicate uncertainty rather than guessing
When installing node modules, prefer using yarn over npm