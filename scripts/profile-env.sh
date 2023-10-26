#!/usr/bin/env bash

# This script modifies the environemnt, namely ~/.bashrc, to add custom features.

# The workspace in the devcontainer is preserved across rebuilds.
# The workspace is deleted whne the container (Codespace) is deleted.
# Use .cache to keep history and local scripts.
# .cache is excluded from git (i.e. in .gitignore)
mkdir -p "${PWD}/.cache/"

# Preserve history
[[ ! -L "${HOME}/.bash_history" ]] && ln -sf "${PWD}/.cache/bash_history" "${HOME}/.bash_history"
[[ ! -f "${PWD}/.cache/bash_history" ]] && touch "${PWD}/.cache/bash_history"

# Write history after every command to preserve it across rebuilds.
if ! grep -q '^### CUSTOM: Preserve Bash History ###$' "${HOME}/.bashrc"; then
    cat >> "${HOME}/.bashrc" <<'EOT'
### CUSTOM: Preserve Bash History ###
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND}"
EOT
fi

# Bash completion for Task
if [[ ! -f "${PWD}/.cache/task.bash" ]]; then
    curl --output "${PWD}/.cache/task.bash" --location https://raw.githubusercontent.com/go-task/task/main/completion/bash/task.bash
    # shellcheck source=/workspaces/clinicaltrials-etl/.cache/task.bash
    source "${PWD}/.cache/task.bash"
fi

if ! grep -q '^### CUSTOM: Task Bash Completion ###$' ~/.bashrc; then
    cat >> ~/.bashrc <<'EOT'
### CUSTOM: Task Bash Completion ###
[[ -f "${PWD}/.cache/task.bash" ]] && source "${PWD}/.cache/task.bash"
EOT
fi
