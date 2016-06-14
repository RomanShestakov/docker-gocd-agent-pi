# Pull base image
FROM hypriot/rpi-java:latest

# install dependencies
RUN apt-get update \
    && apt-get install -y \
        curl \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install dependencies
RUN apt-get update \
    && apt-get install -y \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && git config --global core.preloadindex true \
    && git config --global gc.auto 256

# build time environment variables
ENV GO_VERSION=16.5.0-3305 \
    USER_NAME=go \
    USER_ID=999 \
    GROUP_NAME=go \
    GROUP_ID=999

# install go agent
RUN groupadd -r -g $GROUP_ID $GROUP_NAME \
    && useradd -r -g $GROUP_NAME -u $USER_ID -d /var/go $USER_NAME \
    && mkdir -p /var/lib/ \
    && mkdir -p /var/go \
    # && curl -fSL "https://download.go.cd/binaries/$GO_VERSION/deb/go-agent-$GO_VERSION.deb" -o go-agent.deb \
    && wget --no-check-certificate -O go-agent.zip https://download.go.cd/binaries/$GO_VERSION/generic/go-agent-$GO_VERSION.zip \
    && unzip go-agent.zip -d /var/lib/ \
    && ln -s /var/lib/go-agent-`echo ${GO_VERSION} | grep -o "[0-9][0-9].[0-9].[0-9]"` /var/lib/go-agent
    && rm -rf go-agent.zip \
    && sed -i -e "s/DAEMON=Y/DAEMON=N/" /etc/default/go-agent \
    && echo "export PATH=$PATH" | tee -a /var/go/.profile \
    && chown -R ${USER_NAME}:${GROUP_NAME} /var/lib/go-agent \
    && chown -R ${USER_NAME}:${GROUP_NAME} /var/go \
    && groupmod -g 200 ssh

# runtime environment variables
ENV GO_SERVER=localhost \
    GO_SERVER_PORT=8153 \
    AGENT_MEM=128m \
    AGENT_MAX_MEM=256m \
    AGENT_KEY="" \
    AGENT_RESOURCES="" \
    AGENT_ENVIRONMENTS="" \
    AGENT_HOSTNAME="" \
    DOCKER_GID_ON_HOST=""

COPY ./docker-entrypoint.sh /

RUN chmod 500 /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
