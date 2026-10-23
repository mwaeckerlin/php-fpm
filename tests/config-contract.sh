#!/usr/bin/env bash
# Config contract: the shipped image must be production-safe.
#
# A production php-fpm must never display errors to clients (information
# leak: paths, stack context, configuration details) and the default module
# set must actually be present — a silently skipped install step would ship
# a crippled image.
#
# The checks run the shipped binary itself instead of inspecting files:
#   php-fpm -tt  dumps the effective pool configuration,
#   php-fpm -m   lists the compiled-in and loaded modules.
# `--pull=never` keeps docker from silently pulling a stale image from the
# registry when the local build is missing; that would test the wrong artefact.
#
# Usage: tests/config-contract.sh IMAGE

set -uo pipefail

IMAGE="${1:?usage: tests/config-contract.sh IMAGE}"

PASS=0
FAIL=0
declare -a FAILED_NAMES

_pass() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
_fail() { FAIL=$((FAIL + 1)); FAILED_NAMES+=("$1"); echo "  FAIL  $1: $2"; }

echo "==> Config contract: production-safe php-fpm"

if ! docker image inspect "${IMAGE}" > /dev/null 2>&1; then
    _fail "${IMAGE}_image_exists" "image not built — run 'npm run build' first"
else
    CONFIG=$(docker run --rm --pull=never "${IMAGE}" -tt 2>&1)

    # display_errors must be forced off for every pool (php_admin_flag, so an
    # application cannot re-enable it); errors still go to stderr via log_errors.
    if grep -Eq 'display_errors\] = (on|yes|1)' <<<"${CONFIG}"; then
        _fail "${IMAGE}_display_errors_off" "pool forces display_errors on — errors would be shown to clients"
    else
        _pass "${IMAGE}_display_errors_off"
    fi
    if grep -Eq 'display_startup_errors\] = (on|yes|1)' <<<"${CONFIG}"; then
        _fail "${IMAGE}_display_startup_errors_off" "pool forces display_startup_errors on"
    else
        _pass "${IMAGE}_display_startup_errors_off"
    fi

    # errors must still be logged (observability must not be lost by the fix)
    if grep -Eq 'log_errors\] = (on|yes|1)' <<<"${CONFIG}"; then
        _pass "${IMAGE}_log_errors_on"
    else
        _fail "${IMAGE}_log_errors_on" "pool does not log errors to stderr"
    fi

    # CVE-2026-109619
    if grep -Eq 'fatal_error_backtraces\] = (off|no|0)' <<<"${CONFIG}"; then
        _pass "${IMAGE}_fatal_error_backtraces_locked"
    else
        _fail "${IMAGE}_fatal_error_backtraces_locked" "the pool does not lock fatal_error_backtraces off"
    fi
    if grep -Eq 'session\.upload_progress\.enabled\] = (off|no|0)' <<<"${CONFIG}"; then
        _pass "${IMAGE}_session_upload_progress_locked"
    else
        _fail "${IMAGE}_session_upload_progress_locked" "the pool does not lock session.upload_progress.enabled off"
    fi
    INFO=$(docker run --rm --pull=never "${IMAGE}" -i 2>&1)
    if grep -Eiq 'session\.upload_progress\.enabled( => |</td><td class="v">)(Off|0)' <<<"${INFO}"; then
        _pass "${IMAGE}_session_upload_progress_off"
    else
        _fail "${IMAGE}_session_upload_progress_off" "$(grep -i 'session.upload_progress.enabled' <<<"${INFO}" || echo 'setting not reported')"
    fi

    # the image has no shell, so a caller must see these functions as unavailable and take its own way
    if grep -q '^disable_functions => exec,shell_exec,system,passthru' <<<"${INFO}"; then
        _pass "${IMAGE}_shell_functions_disabled_in_php_fpm"
    else
        _fail "${IMAGE}_shell_functions_disabled_in_php_fpm" "$(grep '^disable_functions' <<<"${INFO}" || echo 'setting not reported')"
    fi
    CLI=$(docker run --rm --pull=never --entrypoint /usr/bin/php "${IMAGE}" -r 'foreach (["exec", "shell_exec", "system", "passthru", "proc_open"] as $f) echo $f, "=", function_exists($f) ? "on" : "off", "\n";' 2>&1)
    if [[ "${CLI}" == $'exec=off\nshell_exec=off\nsystem=off\npassthru=off\nproc_open=on' ]]; then
        _pass "${IMAGE}_shell_functions_disabled_in_cli_proc_open_kept"
    else
        _fail "${IMAGE}_shell_functions_disabled_in_cli_proc_open_kept" "$(echo ${CLI})"
    fi

    # the default module set includes php-imagick; its pecl loader is installed
    # by a conditional Dockerfile step — if that step is silently skipped, the
    # module is missing even though the package list requests it.
    MODULES=$(docker run --rm --pull=never "${IMAGE}" -m 2>&1)
    if grep -qi '^imagick$' <<<"${MODULES}"; then
        _pass "${IMAGE}_module_imagick"
    else
        _fail "${IMAGE}_module_imagick" "imagick module missing — conditional install step did not run"
    fi

    # php-fpm -i reports the values the FastCGI SAPI uses; the CLI forces its own time limits
    _limits() {
        docker run --rm --pull=never "$@" "${IMAGE}" -i 2>&1 \
            | sed -n -E 's/^(memory_limit|upload_max_filesize|post_max_size|max_file_uploads|max_execution_time|max_input_time) => ([^ ]+) => .*/\1=\2/p'
    }
    EXPECTED=$'max_execution_time=30\nmax_file_uploads=1000\nmax_input_time=60\nmemory_limit=512M\npost_max_size=100G\nupload_max_filesize=10G'
    DEFAULTS=$(_limits)
    if [[ "${DEFAULTS}" == "${EXPECTED}" ]]; then
        _pass "${IMAGE}_php_limits_default"
    else
        _fail "${IMAGE}_php_limits_default" "$(echo ${DEFAULTS})"
    fi
    EXPECTED=$'max_execution_time=11\nmax_file_uploads=7\nmax_input_time=12\nmemory_limit=256M\npost_max_size=3G\nupload_max_filesize=2G'
    SET=$(_limits -e MEMORY_LIMIT=256M -e UPLOAD_MAX_FILESIZE=2G -e POST_MAX_SIZE=3G \
        -e MAX_FILE_UPLOADS=7 -e MAX_EXECUTION_TIME=11 -e MAX_INPUT_TIME=12)
    if [[ "${SET}" == "${EXPECTED}" ]]; then
        _pass "${IMAGE}_php_limits_from_environment"
    else
        _fail "${IMAGE}_php_limits_from_environment" "$(echo ${SET})"
    fi
    _opcache() {
        docker run --rm --pull=never "$@" "${IMAGE}" -i 2>&1 \
            | sed -n -E 's/^(opcache\.memory_consumption|opcache\.interned_strings_buffer) => ([^ ]+) => .*/\1=\2/p'
    }
    EXPECTED=$'opcache.interned_strings_buffer=32\nopcache.memory_consumption=128'
    DEFAULTS=$(_opcache)
    if [[ "${DEFAULTS}" == "${EXPECTED}" ]]; then
        _pass "${IMAGE}_opcache_default"
    else
        _fail "${IMAGE}_opcache_default" "$(echo ${DEFAULTS})"
    fi
    EXPECTED=$'opcache.interned_strings_buffer=64\nopcache.memory_consumption=256'
    SET=$(_opcache -e OPCACHE_INTERNED_STRINGS_BUFFER=64 -e OPCACHE_MEMORY_CONSUMPTION=256)
    if [[ "${SET}" == "${EXPECTED}" ]]; then
        _pass "${IMAGE}_opcache_from_environment"
    else
        _fail "${IMAGE}_opcache_from_environment" "$(echo ${SET})"
    fi

    # grep reads the whole output: grep -q stops at the first match, php-fpm then dies on SIGPIPE and pipefail fails the check
    if grep -q 'pm.max_children = 50$' <<<"${CONFIG}"; then
        _pass "${IMAGE}_max_children_default"
    else
        _fail "${IMAGE}_max_children_default" "pm.max_children is not 50"
    fi
    SET_CONFIG=$(docker run --rm --pull=never -e MAX_CHILDREN=9 "${IMAGE}" -tt 2>&1)
    if grep -q 'pm.max_children = 9$' <<<"${SET_CONFIG}"; then
        _pass "${IMAGE}_max_children_from_environment"
    else
        _fail "${IMAGE}_max_children_from_environment" "MAX_CHILDREN=9 does not reach pm.max_children"
    fi

    if docker run --rm --pull=never --entrypoint /usr/bin/php "${IMAGE}" /usr/local/bin/health.php > /dev/null 2>&1; then
        _fail "${IMAGE}_unhealthy_without_php_fpm" "health.php reports healthy although php-fpm does not run"
    else
        _pass "${IMAGE}_unhealthy_without_php_fpm"
    fi
    CONTAINER=$(docker run -d --rm --pull=never "${IMAGE}")
    HEALTHY=no
    for attempt in 1 2 3 4 5 6 7 8 9 10; do
        if docker exec "${CONTAINER}" /usr/bin/php /usr/local/bin/health.php > /dev/null 2>&1; then
            HEALTHY=yes
            break
        fi
        sleep 1
    done
    docker stop "${CONTAINER}" > /dev/null 2>&1
    if [[ "${HEALTHY}" == yes ]]; then
        _pass "${IMAGE}_healthy_with_php_fpm"
    else
        _fail "${IMAGE}_healthy_with_php_fpm" "health.php got no pong from the running php-fpm"
    fi
    if docker image inspect --format '{{json .Config.Healthcheck.Test}}' "${IMAGE}" | grep -q 'health.php'; then
        _pass "${IMAGE}_healthcheck_declared"
    else
        _fail "${IMAGE}_healthcheck_declared" "the image declares no HEALTHCHECK with health.php"
    fi
fi

echo ""
echo "==> Config contract results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    echo "==> Failed contracts: ${FAILED_NAMES[*]}"
    exit 1
fi
