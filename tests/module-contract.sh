#!/usr/bin/env bash
# Module contract: php-fpm and the PHP CLI load every module of
# tests/expected-modules.txt.
#
# With a PHP branch such as 8.4, it also checks that php-fpm and the PHP CLI
# run exactly that branch, which the tag of the image promises.
#
# Usage: tests/module-contract.sh IMAGE [PHP_BRANCH]

set -uo pipefail
cd "$(dirname "$0")/.."

IMAGE="${1:?usage: tests/module-contract.sh IMAGE [PHP_BRANCH]}"
BRANCH="${2:-}"
PASS=0
FAIL=0
declare -a FAILED_NAMES

_pass() { PASS=$((PASS + 1)); echo "  PASS  $1"; }
_fail() { FAIL=$((FAIL + 1)); FAILED_NAMES+=("$1"); echo "  FAIL  $1: $2"; }

_modules() {
    docker run --rm --pull=never --entrypoint "$1" "${IMAGE}" -m 2>&1 \
        | grep -v -E '^\[|^$' | tr '[:upper:]' '[:lower:]' | sort -u
}

echo "==> Module contract: ${IMAGE}"
echo "        PHP in the image: $(docker run --rm --pull=never "${IMAGE}" -v 2>&1 | head -n 1)"

# a module written as name@8.5 is part of PHP from that branch on
php_branch=$(docker run --rm --pull=never --entrypoint /usr/bin/php "${IMAGE}" -r 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION;' 2>&1)
expected=$(grep -v -E '^#|^$' tests/expected-modules.txt | while IFS= read -r line; do
    module="${line%@*}"
    since="${line#"${module}"}"
    since="${since#@}"
    if [[ -z "${since}" || "$(printf '%s\n' "${since}" "${php_branch}" | sort -V | head -n 1)" == "${since}" ]]; then
        printf '%s\n' "${module}"
    fi
done | tr '[:upper:]' '[:lower:]' | sort -u)

for binary in /usr/sbin/php-fpm /usr/bin/php; do
    loaded=$(_modules "${binary}")
    missing=$(printf '%s\n' "${expected}" | comm -23 - <(printf '%s\n' "${loaded}"))
    name="modules_of_$(basename "${binary}")"
    echo "        loaded by ${binary}: $(echo ${loaded})"
    if [[ -z "${missing}" ]]; then
        _pass "${name}"
    else
        _fail "${name}" "missing: $(echo ${missing}); loaded: $(echo ${loaded})"
    fi
    if [[ -n "${BRANCH}" ]]; then
        version=$(docker run --rm --pull=never --entrypoint "${binary}" "${IMAGE}" -v 2>&1 | head -n 1)
        if [[ "${version}" == "PHP ${BRANCH}."* ]]; then
            _pass "php_branch_of_$(basename "${binary}") (${BRANCH})"
        else
            _fail "php_branch_of_$(basename "${binary}")" "expected PHP ${BRANCH}, got: ${version}"
        fi
    fi
done

echo ""
echo "==> Module contract results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
    echo "==> Failed contracts: ${FAILED_NAMES[*]}"
    exit 1
fi
