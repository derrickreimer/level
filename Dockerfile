# Docker-based dev image for Level
#
# Some of Level's scripts currently assume Node.js and Elixir are present
# on the same host. Hence using the official Elixir image as base
# and installing Node.js with nvm for now as per the README, instead of
# using the official Node.js image in a separate container.
# Caveat: nvm is bootstrapping itself in .bashrc, so node is NOT available
# by default, only when bash is invoked with -i or -l.

# https://github.com/levelhq/level/blob/2e8ab628d4bb55115410c7e6543d8c9973fd8adf/mix.exs#L10
FROM elixir:1.6

RUN set -ex \
  && apt-get update \
  && apt-get install -y \
    apt-transport-https \
    build-essential \
    inotify-tools \
    libssl-dev \
    postgresql-client

WORKDIR /opt

# https://github.com/levelhq/level/blob/2e8ab628d4bb55115410c7e6543d8c9973fd8adf/README.md#nodejs
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

# For some reson nvm.sh bails if .nvmrc is present
# - using .nvmrc's contents as a cli parameter instead
ADD .nvmrc .desired-node-version
# bash -l ensures .bashrc is used, which is where nvm is bootstrapping itself
RUN bash -l -c 'echo "installing Node.js via nvm" \
  && nvm --version \
  && nvm install $(cat .desired-node-version) \
  && nvm alias default $(cat .desired-node-version) \
  && nvm use default \
  && set -ex \
  && node --version \
  && npm --version'

# https://github.com/levelhq/level/blame/2e8ab628d4bb55115410c7e6543d8c9973fd8adf/README.md#L13
# https://yarnpkg.com/en/docs/install#debian-stable
# Yarn is included in the official Node.js images, but is not provided by nvm.
RUN set -ex \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update && apt-get install -y yarn \
  && yarn --version

WORKDIR /opt/level

ADD *.exs *.lock *.config ./
RUN set -ex \
  && mix local.hex --force \
  && mix local.rebar --force \
  && mix deps.get

# https://github.com/levelhq/level/blob/master/script/bootstrap#L41-L44
RUN bash -l -c 'yarn global add elm-format'
# Docker-cached build of node_modules/
WORKDIR /opt/level/assets
ADD assets/package.json assets/yarn.lock ./
RUN bash -l -c 'yarn'

WORKDIR /opt/level

# Add entire project in Docker cache. Most of these files will be shadowed
# by the host bind mounts in docker-compose.yml though...
ADD . .

# Default entrypoint: waits for db continer, prepares the dev db, starts level server
CMD ./script/docker-dev/entrypoint
