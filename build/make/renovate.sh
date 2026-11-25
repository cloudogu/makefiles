#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Updates <PREFIX>_CHECKSUM (sha256) in Dockerfiles for every <PREFIX>_URL whose resolved value changed compared to HEAD.
# Variables are read from one-variable ENV/ARG lines (NAME=value) and expanded in file order, like Docker does.

usage() {
    echo "Usage: $0 update-checksums <file>..." >&2
    exit 2
}

# Prints "NAME=value" for every ENV/ARG line that defines exactly one variable.
read_vars() {
    sed -n -E 's/^[[:space:]]*(ENV|ARG)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=(.*)$/\2=\3/p'
}

# Expands ${NAME} references in $2 with the values of the associative array named $1.
# Unknown references stay as they are.
expand() {
    local -n known="$1"
    local value="$2"
    local result=""
    local name
    while true; do
        # shellcheck disable=SC2016 # matches a literal ${...}
        case "${value}" in
            *'${'*'}'*) ;;
            *) break ;;
        esac
        result+="${value%%\$\{*}"
        value="${value#*\$\{}"
        name="${value%%\}*}"
        value="${value#*\}}"
        if test -n "${known[${name}]+set}"; then
            result+="${known[${name}]}"
        else
            result+="\${${name}}"
        fi
    done
    printf '%s' "${result}${value}"
}

# Fills the associative array named $1 with the expanded variables read from stdin.
load_vars() {
    local -n target="$1"
    local name value
    while IFS='=' read -r name value; do
        # shellcheck disable=SC2034 # written through the nameref
        target["${name}"]="$(expand "$1" "${value}")"
    done < <(read_vars)
}

update_checksums() {
    test "$#" -gt 0 || usage
    git rev-parse --verify --quiet HEAD > /dev/null || {
        echo "Error: not inside a git repository with at least one commit" >&2
        exit 1
    }

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    # shellcheck disable=SC2064 # expand tmp_dir now, it is local
    trap "rm -rf '${tmp_dir}'" EXIT

    # Compute every checksum before touching any file, so a failed download leaves all files unchanged.
    local updates=()
    local file name prefix url old_url checksum
    for file in "$@"; do
        local -A current=() previous=()
        load_vars current < "${file}"
        load_vars previous < <(git show "HEAD:./${file}" 2> /dev/null || true)

        while IFS='=' read -r name _; do
            prefix="${name%_CHECKSUM}"
            test -n "${current[${prefix}_URL]+set}" || {
                echo "Error: ${file}: ${name} has no ${prefix}_URL" >&2
                exit 1
            }
            url="${current[${prefix}_URL]}"
            case "${url}" in
                *'$'*)
                    echo "Error: ${file}: ${prefix}_URL has unresolved variables: ${url}" >&2
                    exit 1
                    ;;
            esac

            old_url="${previous[${prefix}_URL]-}"
            if test "${url}" = "${old_url}" && test -n "${previous[${name}]+set}"; then
                echo "${file}: ${name} unchanged" >&2
                continue
            fi

            echo "${file}: downloading ${url}" >&2
            curl --fail --silent --show-error --location --retry 3 \
                --proto '=https' --proto-redir '=https' \
                --output "${tmp_dir}/download" "${url}"
            checksum="$(sha256sum < "${tmp_dir}/download" | cut -d' ' -f1)"
            updates+=("${file}" "${name}" "${checksum}")
        done < <(read_vars < "${file}" | grep -E '^[A-Za-z0-9_]+_CHECKSUM=' || true)
        unset current previous
    done

    local i
    for ((i = 0; i < ${#updates[@]}; i += 3)); do
        file="${updates[i]}"
        name="${updates[i + 1]}"
        checksum="${updates[i + 2]}"
        sed -i -E "s/^([[:space:]]*(ENV|ARG)[[:space:]]+${name}=).*/\1${checksum}/" "${file}"
        echo "${file}: ${name} updated to ${checksum}" >&2
    done
}

case "${1-}" in
    update-checksums)
        shift
        update_checksums "$@"
        ;;
    *) usage ;;
esac
