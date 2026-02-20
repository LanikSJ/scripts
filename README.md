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
  - [☁️ AWS](#aws)
  - [🐳 Docker](#docker)
  - [🔒 Expect](#expect)
  - [🐙 Git](#git)
  - [🌐 Hosting](#hosting)
  - [🍎 Mac](#mac)
  - [🗃️ Misc](#misc)
  - [🔐 SSL](#ssl)
  - [📝 Sublime](#sublime)
  - [⏱️ TTL](#ttl)
  - [🧪 Zoxide](#zoxide)
  - [🐚 zsh](#zsh)

## Directory Structure and Script Overviews

Here's a breakdown of the main script categories and a brief description of
their purpose:

### AWS

Scripts related to Amazon Web Services (AWS) ☁️ CLI interactions.

- `aws_version.sh`: Displays the installed AWS CLI version.

### Docker

Scripts for managing 🐳 Docker and container-related tasks.

- `colima.sh`: Automates the process of adding custom certificates to
  Colima (a container runtime for macOS and Linux) and restarting it.
- `colima_ssl.sh`: Additional Colima SSL configuration script.
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

Scripts for 🐙 Git repository management and operations.

- `branch-clean.sh`: Automates the cleanup and removal of old branches
  from Homebrew tap repositories.
- `cleanup-repos.sh`: A script for general repository cleanup.
- `gcpd.sh`: A Git command alias for `git commit --amend --no-edit`.
- `git-branch-all.sh`: Lists all branches across multiple repositories.
- `github-label.sh`: Manages GitHub labels for repositories.
- `github-workflows.sh`: Manages GitHub workflow configurations.
- `gpg-conf.sh`: Configures GPG for Git operations.
- `gwho.sh`: A Git command alias for showing Git user information.
- `merge-pr.sh`: Automates merging pull requests.
- `ubit.sh`: A Git command alias for undoing git add.
- `ugh.sh`: A Git command alias for undoing git reset.
- `ugl.sh`: A Git command alias for checking git log.

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

### TTL

Scripts for managing Time To Live (TTL) configurations.

- `_ttl`: TTL configuration file.

### Zoxide

Scripts for 🧪 Zoxide (a smarter cd command) integration.

- `clean.sh`: Cleans up Zoxide data.
- `cleanup.sh`: Zoxide cleanup utility.
- `import.sh`: Imports data into Zoxide.
- `verify.sh`: Verifies Zoxide installation and configuration.

### zsh

Scripts or configurations for the 🐚 Zsh shell.

- `aliases.zsh`: Zsh command aliases.
- `aws-sso.zsh`: AWS SSO authentication integration.
- `creds.sh`: Credentials management script.
- `exports.zsh`: Environment variable exports.
- `fastlane.zsh`: Fastlane configuration script.
- `fips.zsh`: FIPS mode configuration script.
- `ssh.zsh`: SSH configuration and key management script.

---

This `README.md` provides a better overview of the repository's
contents, making it easier to understand the purpose and functionality
of the scripts within.
