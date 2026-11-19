
FROM node:26-bookworm-slim

ARG MAVEN_VERSION=3.9.16
ARG JDK_VERSION=25

#
# Base tools
#
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       build-essential \
       ca-certificates \
       curl \
       fd-find \
       file \
       findutils \
       git \
       gpg \
       gzip \
       jq \
       less \
       make \
       patch \
       procps \
       ripgrep \
       shellcheck \
       sqlite3 \
       tar \
       tree \
       unzip \
       wget \
       zip \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

#
# Locale and timezone (German)
#
RUN apt-get update \
    && apt-get install -y --no-install-recommends locales \
    && sed -i 's/^# *\(de_DE.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=de_DE.UTF-8
ENV LANGUAGE=de_DE:de
ENV LC_ALL=de_DE.UTF-8
ENV TZ=Europe/Berlin

#
# Corretto JDK
#
RUN curl -fsSL https://apt.corretto.aws/corretto.key \
      | gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" \
      > /etc/apt/sources.list.d/corretto.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       java-$JDK_VERSION-amazon-corretto-jdk \
    && rm -rf /var/lib/apt/lists/*

RUN JAVA_PATH="$(readlink -f "$(command -v javac)")" \
    && JAVA_DIR="$(dirname "$(dirname "$JAVA_PATH")")" \
    && ln -s "$JAVA_DIR" /opt/java-home

ENV JAVA_HOME=/opt/java-home

#
# Maven
#
RUN curl -fsSL \
      "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
      -o /tmp/maven.tar.gz \
    && mkdir -p /opt/maven \
    && tar -xzf /tmp/maven.tar.gz \
       -C /opt/maven --strip-components=1 \
    && rm /tmp/maven.tar.gz

ENV MAVEN_HOME=/opt/maven
ENV PATH="${MAVEN_HOME}/bin:${PATH}"

#
# Container use
#
USER root
WORKDIR /workspace
ENTRYPOINT ["/bin/bash"]
