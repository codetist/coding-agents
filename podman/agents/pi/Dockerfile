
FROM localhost/dev-base

#
# Pi Coding Agent
#
RUN npm install -g @earendil-works/pi-coding-agent && pi --version

RUN mkdir -p /workspace /home/node/.pi/agent \
    && chown -R node:node /workspace /home/node/.pi

ENV HOME=/home/node
ENV PI_CODING_AGENT_DIR=/home/node/.pi/agent

#
# Container use
#
USER node
WORKDIR /workspace
ENTRYPOINT ["pi"]
