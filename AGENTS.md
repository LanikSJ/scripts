# Agent Rules & Project Standards for LanikSJ/scripts

## Repository Overview

This is a personal collection of scripts, tools, and projects covering:

- Shell scripts for automation (AWS, Docker, Git, system administration).
- Web development projects (browser extensions, desktop apps).
- Developer tools and utilities.
- Personal configurations and themes.

## Code Standards and Practices

### Shell Scripts (BASH & ZSH)

- Use `#!/usr/bin/env bash` for bash and `#!/usr/bin/env zsh` for zsh.
- Always include `set -euo pipefail` for error handling in bash/zsh scripts.
- Follow the template structure in `scripts/TEMPLATE.sh` for new scripts.
- **Shellcheck Compliance**: ALL shell scripts MUST be shellcheck compliant with zero warnings or errors.
- Include proper usage documentation and help functions.
- Use consistent logging with colors and icons (see `TEMPLATE.sh`).
- **ALL shell scripts MUST use emoji icons in every `log()` / `echo` message that outputs to the console** for visual scannability
  (e.g., `✅ Success`, `❌ Error`, `⚠️ Warning`, `ℹ️ Info`, `🚫 Fatal`, `⚙️ Processing`, `📋 Summary`, `⏭️ Skipping`).
- Implement dry-run functionality where applicable.

### Script Synchronization Requirements (CRITICAL)

- **MANDATORY**: When updating shell scripts that share common patterns
  (e.g., `git_update()`), ensure consistent implementation across ALL
  related scripts.
- **Synchronized Pairs**:
  - `scripts/git/ugh.sh` and `scripts/mac/umac.zsh` MUST maintain identical git repository management logic.
  - The `git_update()` and `update_git_repos()` functions MUST be identical between these scripts.
- **Output Formatting**:
  - `ugh.sh` and `umac.zsh --only=git` MUST produce identical output.
  - Starting message: `"📂 Updating LanikSJ repositories"`
  - Completion message: `"LanikSJ repositories updated"`
  - Icon: `GIT_ICON="📂"`
  - Log levels: `log_info()`, `log_success()`, `log_warning()`, `log_error()`.

### Shell Compatibility Requirements

- **CRITICAL**: Ensure cross-shell compatibility between bash and zsh.
- Avoid `wait -n` (bash-only) and `${!array[@]}` (bash-only).
- Use standard `wait` and portable array iteration patterns.

### Markdown Compliance Requirements (MANDATORY)

- **ALL markdown files (.md) MUST pass markdownlint validation with zero errors or warnings**
- Run `markdownlint <filename>` on every markdown file before considering it complete
- Follow the project's `.markdownlint.json` configuration strictly
- Address ALL markdownlint issues immediately - no exceptions or workarounds
- Common requirements include:
  - Maximum line length of 80 characters (MD013)
  - Consistent heading styles and hierarchy
  - Proper list formatting and indentation
  - Blank lines around headings and code blocks
  - Consistent link and reference formatting
  - No trailing whitespace
  - Files must end with newlines
  - Proper table formatting when applicable
- Use `markdownlint --fix <filename>` for auto-fixable issues when available
- Validate markdown files in CI/CD pipelines where applicable

## Development Guidelines

### Commit Message Convention

- Use the conventional commit format: `type(scope): description`
- Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`
- Commit descriptions should be a bullet list of changes made
- Example:

  ```text
  docs(AGENTS.md): update agent rules for cloudflare-worker project

  - this file had the wrong data from a totally different repository
  ```

#### Commit Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Formatting (white-space, etc)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding or correcting tests
- **chore**: Changes to build process or auxiliary tools

#### Scope Guidelines

- **action**: main action logic
- **docs**: documentation
- **tests**: test-related
- **ci**: CI/CD configuration
- **deps**: dependency updates

### Pre-Implementation Testing

- **MANDATORY**: Test all changes in a safe environment before implementing them in production scripts.
- Create backup copies before modification.
- Use dry-run modes to validate behavior.
- Test in both interactive and non-interactive environments.

### Security Considerations

- Never commit sensitive information (API keys, passwords, etc.).
- Use environment variables for configuration.
- **Vulnerability Scanning**:
  - Node.js: `npm audit` / `yarn audit`.
  - Python: `pip-audit` / `safety`.
  - Docker: `docker scout` / `trivy`.

## GitHub & Automation Standards

These rules apply specifically to files in `.github/*` (workflows, templates, and documentation).

### Quality Gates (MANDATORY)

Before completing any change in `.github/`:

1. ✅ Run `markdownlint` validation (if .md file).
2. ✅ Ensure project standards are followed.
3. ✅ Verify contribution guidelines are up-to-date.
4. ✅ Check that automation maintains project standards.

### Templates and Workflows

- Ensure issue and pull request templates provide clear guidelines.
- Include project-specific troubleshooting sections.
- Reference existing project documentation.

### Automation and CI/CD

- Project workflows must include automated testing stages.
- Code quality checks must be integrated into CI/CD.
- Release automation must be properly configured.

## Cline Rules Maintenance

- **MANDATORY**: Update this file whenever making changes to scripts that
  introduce new coding patterns, utility functions, or bug fixes that
  should be applied consistently.
- This file serves as the **Single Source of Truth** for coding standards.

### Alias Management

- **Source of truth**: `zsh/aliases.zsh`
- That file is symlinked to `~/.oh-my-zsh/custom/aliases.zsh` (Oh My Zsh
  auto-sources it)
- Aliases are organized into sections with comment headers
  (`# OS`, `# Brew`, `# Git`, etc.)
- Commands with rich subcommand trees that are aliased to a different name
  should include `compdef` for tab-completion
  (e.g., `alias cz='chezmoi'; compdef cz='chezmoi'`)
- Aliases that preserve the original command name (e.g., `cat='bat -p'`)
  don't need `compdef`
- Aliases pointing to scripts (`~/bin/...`) don't need `compdef`
