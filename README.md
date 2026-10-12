# Personal Scripts Repository

![Scripts](https://img.shields.io/badge/Scripts-blue)
![AWS](https://img.shields.io/badge/AWS-orange)
![Docker](https://img.shields.io/badge/Docker-informational)
![Git](https://img.shields.io/badge/Git-red)
![macOS](https://img.shields.io/badge/macOS-lightgrey)

This repository houses a collection of personal scripts designed to
automate various tasks across different domains, including AWS, Docker,
Git, system administration, and more. These scripts are intended for
personal use to streamline workflows and manage common development and
operational tasks.

## Table of Contents

- [Directory Structure and Script Overviews](#directory-structure-and-script-overviews)
  - [🕵️ Agent](#agent)
  - [☁️ AWS](#aws)
  - [✅ Completions](#completions)
  - [🐳 Docker](#docker)
  - [🔒 Expect](#expect)
  - [🐙 Git](#git)
  - [🌐 Hosting](#hosting)
  - [🍎 Mac](#mac)
  - [🗃️ Misc](#misc)
  - [🐍 Python](#python)
  - [🧹 Shellcheck](#shellcheck)
  - [🔐 SSL](#ssl)
  - [📝 Sublime](#sublime)
  - [🕸️ Web](#web)
  - [🧪 Zoxide](#zoxide)
  - [🐚 zsh](#zsh)
- [Repository Meta Files](#repository-meta-files)

## Directory Structure and Script Overviews

Here's a breakdown of the main script categories and a brief description of
their purpose:

### Agent

Scripts related to AI agent configuration.

- `update_rules.sh`: Copies the central `AGENTS.md` from the repository root into each project, ensuring consistent
  agent rules across all LanikSJ repositories.

### AWS

Scripts related to Amazon Web Services (AWS) ☁️ CLI interactions.

- `aws_version.sh`: Displays the installed AWS CLI version.

### Completions

Shell completion files ✅ for various command-line tools to enhance productivity and reduce typing errors.

- `_agy`: Completion definitions for the Antigravity (`agy`) CLI.
- `_cline`: Completion definitions for Cline command-line interface tool.
- `_fop`: Completion definitions for FOP (File Operations) utility.
- `_ttl`: Completion definitions for TTL (Time To Live) related commands.

These completion files provide intelligent auto-completion for command arguments, options, and file paths when using the
respective tools in supported shells (bash, zsh, fish).

### Docker

Scripts for managing 🐳 Docker and container-related tasks.

- `colima.sh`: Automates the process of adding custom certificates to
  Colima (a container runtime for macOS and Linux) and restarting it.
- `colima_ssl.sh`: Fetches and installs MITM certificates needed to pull
  images from Docker Hub and GitHub Container Registry in Colima.
- `dfimage.sh`: A wrapper script to run the `dfimage` Docker image, likely for
  analyzing Docker image layers.
- `tags.sh`: Lists all available tags for a specified Docker image on Docker Hub,
  with optional filtering.

### Expect

Scripts utilizing 🔒 `expect` for automating interactions with command-line programs,
particularly for SSH and SCP operations.

- `expect.sh`: A generic `expect` script for automating SSH logins and executing
commands on remote hosts.
- `ldap_sync.sh`: A wrapper script that uses `scp_ubu.sh` to synchronize LDAP configuration
  files across multiple Ubuntu servers.
- `scp_rh.sh`: An `expect` script for secure copying files to/from
Red Hat-based systems.
- `scp_ubu.sh`: An `expect` script for secure copying files to/from
Ubuntu-based systems.
- `ssh_co.sh`: An `expect` script for SSH connections to CentOS systems.
- `ssh_mac.sh`: An `expect` script for SSH connections to macOS systems.
- `ssh_rh.sh`: An `expect` script for SSH connections to Red Hat-based
systems.
- `ssh_ubu.sh`: An `expect` script for SSH connections to Ubuntu-based
systems.
- `wrapper.sh`: A general wrapper script for other `expect` scripts.

### Git

Scripts for 🐙 Git repository management and operations, including GitHub automation and workflow management.

- `branch-clean.sh`: Automates the cleanup and removal of old branches
  from Homebrew tap repositories.
- `cleanup-repos.sh`: A script for general repository cleanup and maintenance.
- `create_rulesets.sh`: Creates a GitHub ruleset for each repository owned by
  the LanikSJ account that prevents deleting the default branch.
- `gcpd.sh`: A Git utility that pulls the latest changes, cleans up orphaned and local‑only branches, and deletes them automatically.
- `git-branch-all.sh`: Lists all branches across multiple repositories for comprehensive branch management.
- `github-label.sh`: Manages GitHub labels for repositories, including creation, deletion, and organization.
- `github-workflows.sh`: Manages GitHub workflow configurations and automation scripts.
- `gpg-conf.sh`: Configures GPG for Git operations, including key setup and signing configuration.
- `gwho.sh`: Shows who modified each line of a file by summarizing `git blame` output with per-author counts.
- `merge-pr.sh`: Waits for a pull request's checks to complete, then squash-merges it after validation.
- `ubit.sh`: Updates all BitBucket repositories: prunes remote branches, pulls
  the latest changes, and cleans up local branches.
- `ugh.sh`: Updates all GitHub repositories: pulls the latest changes, prunes
  remote branches, and deletes old local branches.
- `ugl.sh`: Updates all GitLab repositories, pulling the latest changes and
  cleaning up stale branches.

### Hosting

Scripts for hosting-related tasks, particularly for the "Sloth" project.

- `sloth/backup.sh`: A script to perform backups of specified directories and upload
them to an FTP server.

### Mac

Scripts specific to 🍎 macOS environments.

- `bcupg.sh`: Backup GPG keys script.
- `beyond.sh`: Beyond Compare for macOS related script.
- `brewfile.sh`: Homebrew Bundle management script.
- `color.sh`: Color utilities script.
- `dhcp.zsh`: DHCP configuration script.
- `freedns.sh`: FreeDNS update script.
- `getent.sh`: Getent wrapper script.
- `hostname.sh`: Hostname management script.
- `hwinfo.sh`: Hardware information script.
- `ip_address.sh`: IP address retrieval script.
- `memclean.sh`: Memory cleanup script.
- `memory.sh`: Memory usage monitoring script.
- `myip.zsh`: Public IP address retrieval script.
- `netrestart.sh`: Network restart script.
- `openwith.sh`: Open with application script.
- `prompt.sh`: Terminal prompt configuration script.
- `pylint.sh`: Pylint configuration script.
- `rand_pass.sh`: Random password generator script.
- `rDNS.sh`: Reverse DNS lookup script.
- `recycle.sh`: Recycle bin management script.
- `shortcuts.sh`: macOS shortcuts management script.
- `ssh_agent.zsh`: SSH agent management script.
- `umac.zsh`: macOS-specific utilities script.
- `unode.zsh`: Node.js version management script.
- `upip.zsh`: Python pip upgrade script.
- `watch.sh`: File watching script.
- `wav2mp3.sh`: Audio conversion script (WAV to MP3).
- `ytdl.sh`: YouTube download script.

### Misc

A collection of 🗃️ miscellaneous utility scripts.

- `array.sh`: Array manipulation utilities.
- `firefox-update.sh`: Firefox browser update script.

### Python

Standalone 🐍 Python scripts.

- `ring_rename_files.py`: Renames Ring doorbell video files from
  `Ring_YYYYMMDD_HHMM_UUID.mp4` to `RingVideo_YYYYMMDD_HHMM.mp4`.

### Shellcheck

Helper scripts for automating 🧹 ShellCheck fixes across shell scripts.

- `fix-remaining.py`: Fixes remaining ShellCheck warnings, such as unquoted
  variable expansions (SC2086) and non-constant `source` paths (SC1091).
- `fix-shellcheck.py`: Applies common ShellCheck fixes, including `read -r`
  (SC2162), backtick substitution (SC2006), and `source` disables (SC1090).
- `fix-targeted.py`: Fixes targeted ShellCheck warnings, such as removing
  ineffective `$()` wrappers around commands (SC2091).

### SSL

Scripts related to 🔐 SSL certificate management.

- `check_all_hostnames.sh`: Checks SSL certificates for all hostnames.
- `check_ssl_expiry.py`: Python script to check SSL certificate expiry dates.
- `get-cert.sh`: Retrieves SSL certificates from a host.
- `poodle.sh`: POODLE vulnerability scanner script.
- `ssl-expire.sh`: Checks SSL certificate expiration dates.

### Sublime

Scripts or configurations for 📝 Sublime Text editor.

- `sublime-merge.sh`: Sublime Merge configuration script.
- `sublime-text.sh`: Sublime Text configuration script.

### Web

Scripts for testing 🕸️ web latency and HTTP response times.

- `curl-response.sh`: Prints a detailed curl timing breakdown
  (DNS, connect, TLS, transfer) for a request using curl's write-out format.
- `google-response-time.py`: Measures HTTP response times for a website
  (default: google.com) and reports min, max, and average latency.

### Zoxide

Scripts for 🧪 Zoxide (a smarter cd command) integration.

- `clean.sh`: Removes stale or pattern-matching entries from the Zoxide
  database, with dry-run support.
- `import.sh`: Imports data into Zoxide.
- `verify.sh`: Verifies Zoxide installation and configuration.

### zsh

Scripts or configurations for the 🐚 Zsh shell.

- `aliases.zsh`: Zsh command aliases.
- `aws-sso.zsh`: AWS SSO authentication integration.
- `exports.zsh`: Environment variable exports.
- `fastlane.zsh`: Zsh completion for `bundle exec fastlane`, parsing lane
  names from the project's Fastfile.
- `fips.zsh`: FIPS mode configuration script.
- `ssh.zsh`: SSH configuration and key management script.

## Repository Meta Files

Supporting files at the repository root and under `.github/`:

- `AGENTS.md`: Central coding standards and agent rules, copied into other
  LanikSJ repositories by `agent/update_rules.sh`.
- `LICENSE`: Project license.
- `SECURITY.md`: Security vulnerability reporting policy.
- `.editorconfig`: Editor formatting conventions (indent style, charset, EOF).
- `.gitignore`: Ignore rules for generated and operating system files.
- `.markdownlint.json`: Configuration for markdownlint (line length 200).
- `.github/`: Contributing guidelines, code of conduct, issue and pull request
  templates, Dependabot configuration, funding links, and the automated
  license year update workflow.

---

This `README.md` provides a better overview of the repository's
contents, making it easier to understand the purpose and functionality
of the scripts within.
