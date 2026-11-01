# Functions shared by bash and zsh (interactive shells).

# Git-style Docker shortcuts. Preserve leading global options and leave native
# commands (including unknown options) to Docker itself.
docker() {
    local -a docker_original_args docker_global_args
    local docker_short_flags docker_short_flag docker_needs_value docker_shortcut
    docker_original_args=("$@")
    docker_global_args=()

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --config|--context|-c|--host|-H|--log-level|-l|--tlscacert|--tlscert|--tlskey)
                [ "$#" -ge 2 ] || break
                docker_global_args+=("$1" "$2")
                shift 2 ;;
            --config=*|--context=*|--host=*|--log-level=*|--tlscacert=*|--tlscert=*|--tlskey=*|\
            --debug|--debug=*|--tls|--tls=*|--tlsverify|--tlsverify=*)
                docker_global_args+=("$1")
                shift ;;
            --)
                docker_global_args+=("$1")
                shift
                break ;;
            --*) break ;;
            -?*)
                # Short flags may be grouped (-Dc remote) or carry their value
                # in the same argument (-Dcremote, -H=unix:///var/run/docker.sock).
                docker_short_flags=${1#-}
                docker_needs_value=false
                while [ -n "$docker_short_flags" ]; do
                    docker_short_flag=${docker_short_flags%"${docker_short_flags#?}"}
                    docker_short_flags=${docker_short_flags#?}
                    case "$docker_short_flag" in
                        D)
                            case "$docker_short_flags" in "="*) docker_short_flags= ;; esac ;;
                        c|H|l)
                            if [ -z "$docker_short_flags" ]; then
                                [ "$#" -ge 2 ] || break 2
                                docker_needs_value=true
                            fi
                            docker_short_flags= ;;
                        *) break 2 ;;
                    esac
                done
                docker_global_args+=("$1")
                shift
                if [ "$docker_needs_value" = true ]; then
                    docker_global_args+=("$1")
                    shift
                fi ;;
            *) break ;;
        esac
    done

    docker_shortcut=${1:-}
    case "$docker_shortcut" in
        cu|cub|cd|cl|ce|cr) shift ;;
        *)
            command docker ${docker_original_args[@]+"${docker_original_args[@]}"}
            return ;;
    esac
    case "$docker_shortcut" in
        cu)  set -- compose up -d "$@" ;;
        cub) set -- compose up -d --build "$@" ;;
        cd)  set -- compose down "$@" ;;
        cl)  set -- compose logs -f --tail=100 "$@" ;;
        ce)  set -- compose exec "$@" ;;
        cr)  set -- compose run --rm "$@" ;;
    esac
    # The conditional expansion also handles empty arrays with Bash 3.2 nounset.
    command docker ${docker_global_args[@]+"${docker_global_args[@]}"} "$@"
}

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
