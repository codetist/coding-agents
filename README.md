# coding-agents

Unsophisticated  set of scripts and dockerfiles to build and run
images for `pi` and `opencode` agents, focused mainly on Java 
development, with some Node support for web frontend implementation.

> [!IMPORTANT]
> This repo is my **personal** approach to run containerized
> open source AI agents, powered by any LLM made available through 
> Open WebUI. It is not (and will never be) a general solution 
> for anybody. At most, it might be a useful inspiration for others.

## Structure
- [podman](./podman) - contains Dockerfiles to build all container
  images
- [config](./config) - contains essential (sample) config files to
  make agents work

## Requirements
- `macOS` (should mostly work on Linux)
- `Podman`
- `Open WebUI` with at least one available LLM through API

## Setup
- Setup directories and base configuration for `pi` and/or `opencode`
- Export required environment variables
  - `OPENWEBUI_API_BASEURL` - Base URL to access LLMs through Open WebUI,
    something like `https://openwebui.example.org/api`
  - `OPENWEBUI_API_TOKEN` - API token to access LLMs through `Open WebUI`
  - `OPENSERP_BASEURL` - Base URL to access `OpenSERP` for web access and
    search
- Add available models to
  [models.json (for Pi)](./config/agents/pi/models.json) and
  [opencode.json (for OpenCode)](./config/agents/opencode/opencode.json)
- Create `allowed-dirs.conf` from `allowed-dirs.conf.template` and add all
  directories that are allowed to use with agents

## Run
- build required Podman images via `./buildAgentImages.sh`
- run agents via `./launchAgent.sh <image>`, were `image` can be one
  of the following values:
  - `devbase` - start the foundational dev image (without any agents)
  - `pi` - start `Pi Coding Agent`
  - `opencode` - start `OpenCode` Agent



