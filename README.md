# Personal Scripts Repository

This repository houses a collection of personal scripts designed to
automate various tasks across different domains, including AWS, Docker,
Git, system administration, and more. These scripts are intended for
personal use to streamline workflows and manage common development and
operational tasks.

## Directory Structure and Script Overviews

Here's a breakdown of the main script categories and a brief description of
their purpose:

### `aws/`

Scripts related to Amazon Web Services (AWS) CLI interactions.

- `aws_version.sh`: Displays the installed AWS CLI version.

### `docker/`

Scripts for managing Docker and container-related tasks.

- `colima.sh`: Automates the process of adding custom certificates to
  Colima (a container runtime for macOS and Linux) and restarting it.
- `dfimage.sh`: A wrapper script to run the `dfimage` Docker image, likely for
analyzing Docker image layers.
- `tags.sh`: Lists all available tags for a specified Docker image on Docker Hub,
with optional filtering.

### `expect/`

Scripts utilizing `expect` for automating interactions with command-line programs,
particularly for SSH and SCP operations.

- `expect.sh`: A generic `expect` script for automating SSH logins and executing
commands on remote hosts.
- `ldap_sync.sh`: A wrapper script that uses `scp_ubu.sh` (likely
  another `expect` script for SCP) to synchronize LDAP configuration
  files across multiple Ubuntu servers.
- `scp_rh.sh`: (Inferred) An `expect` script for secure copying files to/from
Red Hat-based systems.
- `scp_ubu.sh`: (Inferred) An `expect` script for secure copying files to/from
Ubuntu-based systems.
- `ssh_co.sh`: (Inferred) An `expect` script for SSH connections to a specific
type of host (e.g., CentOS).
- `ssh_mac.sh`: (Inferred) An `expect` script for SSH connections to macOS systems.
- `ssh_rh.sh`: (Inferred) An `expect` script for SSH connections to Red Hat-based
systems.
- `ssh_ubu.sh`: (Inferred) An `expect` script for SSH connections to Ubuntu-based
systems.
- `wrapper.sh`: (Inferred) A general wrapper script, possibly for other `expect`
scripts.

### `git/`

Scripts for Git repository management and operations.

- `branch-clean.sh`: Automates the cleanup and removal of old branches
  from Homebrew tap repositories.
- `cleanup-repos.sh`: (Inferred) A script for general repository cleanup.
- `dropbox-ignore.sh`: (Inferred) Helps in managing `.gitignore` for Dropbox-synced
repositories.
- `dropbox-remove.sh`: (Inferred) Likely for removing Dropbox-related files
from Git.
- `gcpd.sh`: (Inferred) A Git command alias or script, possibly for
`git commit --amend--no-edit`.
- `git-branch-all.sh`: (Inferred) Lists all branches across multiple repositories.
- `gpg-conf-github.sh`: (Inferred) Configures GPG for GitHub.
- `gpg-conf-work.sh`: (Inferred) Configures GPG for work-related Git operations.
- `gwho.sh`: (Inferred) A Git command alias or script, possibly for showing Git
user information.
- `merge-pr.sh`: (Inferred) Automates merging pull requests.
- `ubit.sh`: (Inferred) A Git command alias or script.
- `ugh.sh`: (Inferred) A Git command alias or script.
- `ugl.sh`: (Inferred) A Git command alias or script.

### `hosting/sloth/`

Scripts specifically for hosting-related tasks, particularly for the "Sloth" project.

- `backup.sh`: A script to perform backups of specified directories and upload
them to an FTP server.

### `jobs/`

(Inferred) Likely contains scripts for scheduled jobs or background tasks.

### `mac/`

(Inferred) Scripts specific to macOS environments.

### `misc/`

(Inferred) A collection of miscellaneous utility scripts.

### `ssl/`

(Inferred) Scripts related to SSL certificate management.

### `sublime/`

(Inferred) Scripts or configurations for Sublime Text editor.

### `zsh/`

(Inferred) Scripts or configurations for the Zsh shell.

---

This `README.md` provides a better overview of the repository's
contents, making it easier to understand the purpose and functionality
of the scripts within.
