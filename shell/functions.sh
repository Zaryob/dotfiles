# Functions shared by bash and zsh (interactive shells).

# Current git branch, or nothing outside a repository.
git_branch() {
    git symbolic-ref --quiet --short HEAD 2>/dev/null ||
        git rev-parse --short HEAD 2>/dev/null
}

# Active conda environment name, or nothing.
conda_env() {
    [ -n "${CONDA_DEFAULT_ENV:-}" ] && printf '%s' "${CONDA_DEFAULT_ENV##*/}"
}

# Load conda's shell hook from the first installation found.
# auto_activate: false in ~/.condarc keeps base inactive.
conda_init() {
    shell_name=bash
    [ -n "${ZSH_VERSION:-}" ] && shell_name=zsh
    for conda_home in "$HOME/miniconda3" "$HOME/miniforge3" "$HOME/anaconda3" \
        "${HOMEBREW_PREFIX:-/nonexistent}/Caskroom/miniconda/base" \
        "${HOMEBREW_PREFIX:-/nonexistent}/Caskroom/miniforge/base"; do
        if [ -x "$conda_home/bin/conda" ]; then
            if conda_setup=$("$conda_home/bin/conda" "shell.$shell_name" hook 2>/dev/null); then
                eval "$conda_setup"
            elif [ -r "$conda_home/etc/profile.d/conda.sh" ]; then
                . "$conda_home/etc/profile.d/conda.sh"
            fi
            break
        fi
    done
    unset shell_name conda_home conda_setup
}
