#!/bin/bash
set -euo pipefail

# Local script directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# User home directory
USERHOME="${HOME}"

# Project directory to be mounted to agent
PROJECTDIR="$(realpath "$PWD")"

# Host NPM cache directory
NPM_CACHE="$(npm config get cache)"

#
# Usage
#
usage() {
    echo "Usage: $0 {pi|opencode|devbase}"
    exit 1
}

#
# Init
#
init() {
  # Check directory whitelist config file
  TARGET_IMAGE=$1
  ALLOWED_DIRS=( )
  CONFIG_FILE="${SCRIPT_DIR}/allowed-dirs.conf"

  if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "Error: Configuration file missing: ${CONFIG_FILE}" >&2
    exit 1
  fi

  # shellcheck disable=SC1090
  source "${CONFIG_FILE}"

  # Check current directory is whitelisted
  ALLOWED=false

  for dir in "${ALLOWED_DIRS[@]}"; do
    [[ -d "$dir" ]] || continue

      if [[ "$PROJECTDIR" == "$(realpath "$dir")" ]]; then
        ALLOWED=true
        break
      fi
    done

    if [[ "$ALLOWED" != true ]]; then
    echo "ERROR: Directory is not white-listed: $PROJECTDIR" >&2
    exit 1
  fi    

  PROJECT_NAME="$(basename -- "$PROJECTDIR")"
  CONTAINER_NAME="${TARGET_IMAGE}-${PROJECT_NAME}"
}

#
# run_container
#
run_container() {
  local -a CONTAINER_EXTRA_ARGS=("$@")

  echo "Launching agent container:"
  echo "Project name is $CONTAINER_NAME"
  echo "Project directory is $PROJECTDIR"
  echo "Using image $IMAGE"

  # Default Podman arguments,
  # valid for devbase image and all inherited images
  local -a CONTAINER_DEFAULT_ARGS=(
    --name "$CONTAINER_NAME"
    --security-opt=no-new-privileges
    --cap-drop=ALL
    --pids-limit=512
    # Add committer details without mounting full git config
    --env GIT_AUTHOR_NAME="$(git config user.name)"
    --env GIT_AUTHOR_EMAIL="$(git config user.email)"
    --env GIT_COMMITTER_NAME="$(git config user.name)"
    --env GIT_COMMITTER_EMAIL="$(git config user.email)"
    # As base image is a node image use /home/node as default home
    --env HOME=/home/node
    # Mount global NPM cache from client:
    # Content in NPM cache can include multi-platform versions
    # of dependencies at the same time.
    --env npm_config_cache=/home/node/.npm
    --env npm_config_prefer_offline=true
    --volume "${NPM_CACHE}:/home/node/.npm:rw"
    # Mount project dir
    --volume "${PROJECTDIR}:${PROJECTDIR}:rw"
    # Mount Maven settings and repo
    --volume "${HOME}/.m2:/home/node/.m2:rw"
    # Set project dir to be working dir
    --workdir "${PROJECTDIR}"
  )

  # Isolate existing macOS node_modules:
  # Optionally present node_modules directories are mounted to
  # a temporary volume without copying the hosts content. It is
  # done because Node dependencies might be OS specific. This
  # way the macOS dependencies stay unchanged while the containers
  # Linux dependencies might be different.
  local node_modules_dir
  while IFS= read -r -d '' node_modules_dir; do
    CONTAINER_DEFAULT_ARGS+=(
      --mount "type=volume,destination=${node_modules_dir}"
    )
  done < <(
    find "$PROJECTDIR" \
      -type d \
      -name node_modules \
      -prune \
      -print0
  )

  podman run --rm -it \
    --userns=keep-id:uid=1000,gid=1000 \
    "${CONTAINER_DEFAULT_ARGS[@]}" \
    "$@" \
    "$IMAGE"
}

#
# run_pi
#
run_pi() {
  IMAGE=$1
  PICONFIG="/${USERHOME}/.pi/agent"

  mkdir -p "$PICONFIG"

  CONTAINER_EXTRA_ARGS=(
    --env PI_CODING_AGENT_DIR=/home/node/.pi/agent
    --env OPENWEBUI_API_TOKEN
    --env OPENWEBUI_API_BASEURL
    --env OPENSERP_BASEURL
    --volume "${PICONFIG}:/home/node/.pi/agent:rw" \
  )

  run_container "${CONTAINER_EXTRA_ARGS[@]}"
}

#
# run_opencode
#
run_opencode() {
  IMAGE=$1
  OPENCODE_CONFIG="${USERHOME}/.config/opencode"
  OPENCODE_DATA="${USERHOME}/.local/share/opencode"
  OPENCODE_STATE="${USERHOME}/.local/state/opencode"
  OPENCODE_CACHE="${USERHOME}/.cache/opencode"  

  mkdir -p "$OPENCODE_CONFIG"
  mkdir -p "$OPENCODE_DATA"
  mkdir -p "$OPENCODE_STATE"
  mkdir -p "$OPENCODE_CACHE"

  CONTAINER_EXTRA_ARGS=(
    --env OPENWEBUI_API_TOKEN
    --env OPENWEBUI_API_BASEURL
    --env OPENSERP_BASEURL
    --volume "${OPENCODE_CONFIG}:/home/node/.config/opencode:rw"
    --volume "${OPENCODE_DATA}:/home/node/.local/share/opencode:rw"
    --volume "${OPENCODE_STATE}:/home/node/.local/state/opencode:rw"
    --volume "${OPENCODE_CACHE}:/home/node/.cache/opencode:rw"
  )

  run_container "${CONTAINER_EXTRA_ARGS[@]}"
}

#
# run_devbase
#
run_devbase() {
  IMAGE=$1

  run_container
}

#
# MAIN
#
[[ $# -eq 1 ]] || usage

case "$1" in
  pi)
    init "$1"
    run_pi "pi-agent:latest"
    ;;

  opencode)
    init "$1"
    run_opencode "opencode-agent:latest"
    ;;

  devbase)
    init "$1"
    run_devbase "dev-base:latest"
    ;;

  *)
    echo "Error: Unknown parameter '$1'" >&2
    usage
    ;;
esac

exit 0