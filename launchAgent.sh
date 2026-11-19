#!/bin/bash
set -euo pipefail

# User home directory
USERHOME="${HOME}"

# Directory whitelist
ALLOWED_DIRS=(
    "${USERHOME}/Projekte/pi-podman-agent"
    "${USERHOME}/Projekte/coding-agents"
)

# Project directory to be mounted to agent
PROJECTDIR="$(realpath "$PWD")"

# Image to runf
TARGETIMAGE=$1

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
  # Check whitelist
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
  CONTAINER_NAME="${TARGETIMAGE}-${PROJECT_NAME}"

  echo "Project:   $PROJECTDIR"
  echo "Container: $CONTAINER_NAME"  
}

#
# run_pi
#
run_pi() {
  IMAGE=$1
  PICONFIG="/${USERHOME}/.pi/agent"

  mkdir -p "$PICONFIG"

  podman run --rm -it \
    --name "$CONTAINER_NAME" \
    --security-opt=no-new-privileges \
    --cap-drop=ALL \
    --pids-limit=256 \
    --userns=keep-id:uid=1000,gid=1000 \
    --env HOME=/home/node \
    --env PI_CODING_AGENT_DIR=/home/node/.pi/agent \
    --env OPENWEBUI_API_TOKEN \
    --env OPENWEBUI_API_BASEURL \
    --env OPENSERP_BASEURL \
    --env GIT_AUTHOR_NAME="$(git config user.name)" \
    --env GIT_AUTHOR_EMAIL="$(git config user.email)" \
    --env GIT_COMMITTER_NAME="$(git config user.name)" \
    --env GIT_COMMITTER_EMAIL="$(git config user.email)" \
    --volume "${PICONFIG}:/home/node/.pi/agent:rw" \
    --volume "${PROJECTDIR}:${PROJECTDIR}:rw" \
    --volume "${HOME}/.m2:/home/node/.m2:rw" \
    --workdir "${PROJECTDIR}" \
    "$IMAGE"    
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

  podman run --rm -it \
    --name "$CONTAINER_NAME" \
    --security-opt=no-new-privileges \
    --cap-drop=ALL \
    --pids-limit=256 \
    --userns=keep-id:uid=1000,gid=1000 \
    --env HOME=/home/node \
    --env OPENWEBUI_API_TOKEN \
    --env OPENWEBUI_API_BASEURL \
    --env OPENSERP_BASEURL \
    --env GIT_AUTHOR_NAME="$(git config user.name)" \
    --env GIT_AUTHOR_EMAIL="$(git config user.email)" \
    --env GIT_COMMITTER_NAME="$(git config user.name)" \
    --env GIT_COMMITTER_EMAIL="$(git config user.email)" \
    --volume "${OPENCODE_CONFIG}:/home/node/.config/opencode:rw" \
    --volume "${OPENCODE_DATA}:/home/node/.local/share/opencode:rw" \
    --volume "${OPENCODE_STATE}:/home/node/.local/state/opencode:rw" \
    --volume "${OPENCODE_CACHE}:/home/node/.cache/opencode:rw" \
    --volume "${PROJECTDIR}:${PROJECTDIR}:rw" \
    --volume "${HOME}/.m2:/home/node/.m2:rw" \
    --workdir "${PROJECTDIR}" \
    "$IMAGE"
}

#
# run_devbase
#
run_devbase() {
  IMAGE=$1

   podman run --rm -it \
    --name "$CONTAINER_NAME" \
    --security-opt=no-new-privileges \
    --cap-drop=ALL \
    --pids-limit=256 \
    --userns=keep-id:uid=1000,gid=1000 \
    --env HOME=/home/node \
    --env GIT_AUTHOR_NAME="$(git config user.name)" \
    --env GIT_AUTHOR_EMAIL="$(git config user.email)" \
    --env GIT_COMMITTER_NAME="$(git config user.name)" \
    --env GIT_COMMITTER_EMAIL="$(git config user.email)" \
    --volume "${PROJECTDIR}:${PROJECTDIR}:rw" \
    --volume "${HOME}/.m2:/home/node/.m2:rw" \
    --workdir "${PROJECTDIR}" \
    "$IMAGE" 
}

#
# MAIN
#
[[ $# -eq 1 ]] || usage

case "$1" in
  pi)
    init
    run_pi "pi-agent:latest"
    ;;

  opencode)
    init
    run_opencode "opencode-agent:latest"
    ;;

  devbase)
    init
    run_devbase "dev-base:latest"
    ;;

  *)
    echo "Error: Unknown parameter '$1'" >&2
    usage
    ;;
esac

exit 0