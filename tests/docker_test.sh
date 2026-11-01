#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
trial=$(mktemp -d)
trap 'rm -rf "$trial"' EXIT HUP INT TERM
mkdir "$trial/bin"

# Record exact argument boundaries without a Docker installation or daemon.
cat > "$trial/bin/docker" <<'DOCKER'
#!/bin/sh
: > "$DOCKER_TEST_OUTPUT"
if [ "$#" -gt 0 ]; then
    printf '%s\0' "$@" > "$DOCKER_TEST_OUTPUT"
fi
exit "${DOCKER_TEST_EXIT:-0}"
DOCKER
chmod +x "$trial/bin/docker"

cat > "$trial/check.sh" <<'CHECKS'
set -eu
. "$1"
DOCKER_TEST_OUTPUT="$2/actual"
export DOCKER_TEST_OUTPUT
expected_file="$2/expected"
checks=0

# __RUN__ separates the expected argv from the invocation under test.
check() {
    label=$1
    expected_exit=$2
    shift 2
    : > "$expected_file"
    while [ "$1" != __RUN__ ]; do
        printf '%s\0' "$1" >> "$expected_file"
        shift
    done
    shift
    if DOCKER_TEST_EXIT="$expected_exit" docker "$@"; then
        actual_exit=0
    else
        actual_exit=$?
    fi
    if [ "$actual_exit" -ne "$expected_exit" ]; then
        printf 'FAIL: %s: expected exit %s, got %s\n' \
            "$label" "$expected_exit" "$actual_exit" >&2
        exit 1
    fi
    if ! cmp -s "$expected_file" "$DOCKER_TEST_OUTPUT"; then
        printf 'FAIL: %s: Docker arguments changed unexpectedly\n' "$label" >&2
        printf 'Expected bytes:\n' >&2
        od -An -tx1c "$expected_file" >&2
        printf 'Actual bytes:\n' >&2
        od -An -tx1c "$DOCKER_TEST_OUTPUT" >&2
        exit 1
    fi
    checks=$((checks + 1))
}

check 'start Compose services' 0 compose up -d api worker __RUN__ cu api worker
check 'build and start Compose services' 0 compose up -d --build api __RUN__ cub api
check 'stop Compose project' 0 compose down --remove-orphans __RUN__ cd --remove-orphans
check 'follow service logs' 0 compose logs -f --tail=100 api __RUN__ cl api
check 'exec in a service' 0 compose exec api sh -c 'printf "%s" "hello world"' \
    __RUN__ ce api sh -c 'printf "%s" "hello world"'
check 'run a disposable container' 0 compose run --rm api bundle exec rake __RUN__ cr api bundle exec rake

check 'native command forwarding' 0 container inspect 'my container' __RUN__ container inspect 'my container'
check 'no arguments' 0 __RUN__
check 'empty first argument' 0 '' cu __RUN__ '' cu
check 'shell characters remain literal' 0 compose exec api '' 'two words' '*' '$HOME' '$(touch nope)' \
    'one; two' 'quote"value' "line
break" __RUN__ ce api '' 'two words' '*' '$HOME' '$(touch nope)' 'one; two' 'quote"value' "line
break"
check 'nested aliases remain literal' 0 compose exec api cu cub cd cl ce cr __RUN__ ce api cu cub cd cl ce cr
check 'native alias-like argument' 0 run --rm image cu __RUN__ run --rm image cu
check 'Compose is not rewritten twice' 0 compose cu __RUN__ compose cu

# Value-taking global flags may occur before any shorthand.
for flag in --context -c --host -H --config --log-level -l --tlscacert --tlscert --tlskey; do
    check "global flag $flag" 0 "$flag" 'value with spaces' compose up -d api \
        __RUN__ "$flag" 'value with spaces' cu api
done
for flag in --context --host --config --log-level --tlscacert --tlscert --tlskey; do
    check "equals global flag $flag" 0 "$flag=value with spaces" compose logs -f --tail=100 api \
        __RUN__ "$flag=value with spaces" cl api
done
check 'attached short context' 0 -cremote compose up -d __RUN__ -cremote cu
check 'attached short host' 0 '-Htcp://docker:2376' compose down __RUN__ '-Htcp://docker:2376' cd
check 'attached short log level' 0 -ldebug compose exec api sh __RUN__ -ldebug ce api sh

for flag in --debug -D -D=true -D=false --tls --tlsverify --debug=true --debug=false --tls=true --tls=false --tlsverify=true --tlsverify=false; do
    check "boolean global flag $flag" 0 "$flag" compose up -d __RUN__ "$flag" cu
done
check 'multiple global options' 0 --context remote --config '/some directory' --debug compose run --rm api echo hello \
    __RUN__ --context remote --config '/some directory' --debug cr api echo hello
check 'short flag cluster with attached value' 0 -Dcremote compose up -d __RUN__ -Dcremote cu
check 'short flag cluster with separate value' 0 -Dc remote compose up -d __RUN__ -Dc remote cu
check 'short flag cluster with equals value' 0 -Dc=remote compose up -d __RUN__ -Dc=remote cu
check 'leading command separator' 0 -- compose up -d api __RUN__ -- cu api
check 'separator after globals' 0 --context remote -- compose down __RUN__ --context remote -- cd
check 'alias options stay after expansion' 0 compose up -d -- --context '' __RUN__ cu -- --context ''

check 'unknown global option' 0 --future-flag cu api __RUN__ --future-flag cu api
check 'unknown equals option' 0 --future-flag=value cu __RUN__ --future-flag=value cu
check 'unknown short option' 0 -x cu __RUN__ -x cu
check 'unknown clustered option' 0 -Dx cu __RUN__ -Dx cu
check 'missing context value' 0 --context __RUN__ --context
check 'missing value after globals' 0 --debug --config __RUN__ --debug --config
check 'alias spelling used as flag value' 0 --context cu __RUN__ --context cu
check 'global options without a command' 0 --context remote --debug __RUN__ --context remote --debug
check 'leading help bypasses shortcuts' 0 --help cu __RUN__ --help cu
check 'leading version bypasses shortcuts' 0 --version cu __RUN__ --version cu
check 'clustered help bypasses shortcuts' 0 -Dh cu __RUN__ -Dh cu
check 'clustered version bypasses shortcuts' 0 -Dv cu __RUN__ -Dv cu
check 'shortcut help reaches Compose' 0 compose up -d --help __RUN__ cu --help
check 'native failure status' 37 inspect missing __RUN__ inspect missing
check 'alias failure status' 42 --context remote compose logs -f --tail=100 api __RUN__ --context remote cl api

printf 'PASS: %s Docker wrapper checks (%s)\n' "$checks" "${ZSH_VERSION:-bash $BASH_VERSION}"
CHECKS

PATH="$trial/bin:$PATH"
export PATH
bash --noprofile --norc "$trial/check.sh" "$repo/shell/functions.sh" "$trial"
if command -v zsh >/dev/null 2>&1; then
    zsh -f "$trial/check.sh" "$repo/shell/functions.sh" "$trial"
else
    printf 'SKIP: zsh is unavailable\n'
fi
