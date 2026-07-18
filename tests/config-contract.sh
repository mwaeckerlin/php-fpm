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
    if echo "${CONFIG}" | grep -Eq 'display_errors\] = (on|yes|1)'; then
        _fail "${IMAGE}_display_errors_off" "pool forces display_errors on — errors would be shown to clients"
    else
        _pass "${IMAGE}_display_errors_off"
    fi
    if echo "${CONFIG}" | grep -Eq 'display_startup_errors\] = (on|yes|1)'; then
        _fail "${IMAGE}_display_startup_errors_off" "pool forces display_startup_errors on"
    else
        _pass "${IMAGE}_display_startup_errors_off"
    fi

    # errors must still be logged (observability must not be lost by the fix)
    if echo "${CONFIG}" | grep -Eq 'log_errors\] = (on|yes|1)'; then
        _pass "${IMAGE}_log_errors_on"
    else
        _fail "${IMAGE}_log_errors_on" "pool does not log errors to stderr"
    fi

    # the default module set includes php-imagick; its pecl loader is installed
    # by a conditional Dockerfile step — if that step is silently skipped, the
    # module is missing even though the package list requests it.
    MODULES=$(docker run --rm --pull=never "${IMAGE}" -m 2>&1)
    if echo "${MODULES}" | grep -qi '^imagick$'; then
        _pass "${IMAGE}_module_imagick"
    else
        _fail "${IMAGE}_module_imagick" "imagick module missing — conditional install step did not run"
    fi
fi

echo ""
echo "==> Config contract results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    echo "==> Failed contracts: ${FAILED_NAMES[*]}"
    exit 1
fi
