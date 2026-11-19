#!/bin/bash
set -euo pipefail

podman build -t dev-base:latest ./podman/base
podman build -t pi-agent:latest ./podman/agents/pi
podman build -t opencode-agent:latest ./podman/agents/opencode
