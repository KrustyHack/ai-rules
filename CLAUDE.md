# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a collection of AI coding rules and guidelines for the Cursor IDE. The project provides curated rules that enhance AI-assisted development by establishing coding standards, security practices, and quality guidelines.

## Architecture

### Structure
- `rules/` - Contains the complete rule collection in `.cursor/rules/ack/` format
- `install.sh` - Installation script that copies rules to project directories
- `README.md` - User documentation and installation instructions

### Rule Categories
The project includes 8 specialized rule files:
- **global.mdc** - Universal rules (uses context7)
- **cursor_rules.mdc** - Guidelines for creating/maintaining Cursor rules
- **security.mdc** - Security best practices (CSRF, SQL injection, XSS prevention)
- **codequality.mdc** - Code quality standards and development practices
- **clean_code.mdc** - Clean coding principles
- **python.mdc** - Python-specific conventions
- **git_rules.mdc** - Git workflow and commit standards
- **self_improve.mdc** - Continuous learning and optimization

## Development Commands

This project has no build system, package.json, or test framework - it's a simple shell script distribution system.

### Installation Testing
```bash
# Test the installer locally
./install.sh

# Check rule files
find rules/ -name "*.mdc" -type f
```

### Rule Development
- All rules use the `.mdc` format for Cursor IDE compatibility
- Rules follow the structure defined in `cursor_rules.mdc`
- Each rule must have frontmatter with `description`, `globs`, and `alwaysApply` fields

## Key Development Practices

### Rule Creation Standards
- Use frontmatter metadata format:
  ```markdown
  ---
  description: Clear, one-line description
  globs: applicable/file/patterns
  alwaysApply: boolean
  ---
  ```
- Include both positive (✅ DO) and negative (❌ DON'T) examples
- Reference actual code patterns over theoretical examples
- Keep rules DRY by cross-referencing related rules

### Security Focus
The project emphasizes defensive security practices:
- CSRF protection implementation
- SQL injection prevention
- XSS mitigation strategies
- Security-first development approach

### Code Quality Philosophy
Based on `codequality.mdc`, the project enforces:
- File-by-file change methodology
- Evidence-based development (no speculation)
- Preservation of existing functionality
- Single-chunk edit delivery
- No unnecessary confirmations or summaries