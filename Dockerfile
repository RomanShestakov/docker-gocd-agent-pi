# Pull base image
FROM hypriot/rpi-java:latest

# install dependencies
RUN apt-get update \
    && apt-get install -y curl unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install dependencies
RUN apt-get update \
    && apt-get install -y git \
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
    && wget --no-check-certificate -O go-agent.zip https://download.go.cd/binaries/$GO_VERSION/generic/go-agent-$GO_VERSION.zip \
    && unzip go-agent.zip -d /var/lib/ \
    && mv /var/lib/go-agent-$(echo ${GO_VERSION} | grep -o "[0-9][0-9].[0-9].[0-9]") /var/lib/go-agent \
    && rm -rf go-agent.zip \
    && echo "export PATH=$PATH" | tee -a /var/go/.profile \
    && chmod 775 -R /var/lib/go-agent \
    && chown -R ${USER_NAME}:${GROUP_NAME} /var/lib/go-agent \
    && chown -R ${USER_NAME}:${GROUP_NAME} /var/go


# runtime environment variables
ENV GO_SERVER=192.168.1.79 \
    GO_SERVER_PORT=32783 \
    AGENT_MEM=128m \
    AGENT_MAX_MEM=256m \
    AGENT_KEY="388b633a88de126531afa41eff9aa69e" \
    AGENT_RESOURCES="" \
    AGENT_ENVIRONMENTS="" \
    AGENT_HOSTNAME="" \
    DOCKER_GID_ON_HOST="" \
    DAEMON=N

COPY ./docker-entrypoint.sh /

RUN chmod 500 /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
