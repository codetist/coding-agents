FROM localhost/dev-base

RUN npm install -g @opencode/cli && opencode --version

USER node
ENV HOME=/home/node
ENV XDG_CONFIG_HOME=/home/node/.config
ENV XDG_DATA_HOME=/home/node/.local/share
ENV XDG_STATE_HOME=/home/node/.local/state
ENV XDG_CACHE_HOME=/home/node/.cache

WORKDIR /workspace

ENTRYPOINT ["opencode"]
