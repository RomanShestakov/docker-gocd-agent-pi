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

ENV ERLANG_VERSION=17.5.3

# install go agent
RUN groupadd -r -g $GROUP_ID $GROUP_NAME \
    && useradd -r -g $GROUP_NAME -u $USER_ID -d /var/go $USER_NAME \
    && mkdir -p /var/lib/ \
    && mkdir -p /var/log/go-agent \
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
    GO_SERVER_PORT=8153 \
    AGENT_MEM=128m \
    AGENT_MAX_MEM=256m \
    AGENT_KEY="388b633a88de126531afa41eff9aa69e" \
    AGENT_RESOURCES="pi" \
    AGENT_ENVIRONMENTS="" \
    AGENT_HOSTNAME="gocd-pi" \
    DOCKER_GID_ON_HOST="" \
    DAEMON=N

# add erlang
RUN \
  apt-get update && \
  apt-get --fix-missing -y install build-essential autoconf libncurses5-dev \
  libgl1-mesa-dev libglu1-mesa-dev libpng3 libssh-dev unixodbc-dev openssl fop xsltproc \
  libmozjs185-1.0 libmozjs185-dev libcurl4-openssl-dev libicu-dev wget curl

RUN echo "deb http://binaries.erlang-solutions.com/debian wheezy contrib" >> /etc/apt/sources.list.d/erlang.list

# RUN cd /tmp; wget --no-check-certificate https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
#     dpkg -i erlang-solutions_1.0_all.deb

RUN apt-get update
#RUN apt-get -y install esl-erlang=1:$ERLANG_VERSION
RUN apt-get -y install esl-erlang erlang-mode


COPY ./docker-entrypoint.sh /

RUN chmod 500 /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
