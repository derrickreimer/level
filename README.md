# Sprinkle

[![CircleCI](https://circleci.com/gh/djreimer/sprinkle.svg?style=svg&circle-token=2fe7b2b3bc5f5f1b2ad1c6bcb8267cd9bfeb0e9a)](https://circleci.com/gh/djreimer/sprinkle)

## One-Click Deployment

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/djreimer/sprinkle/tree/master)

## Development Environment

You'll need to install the following dependencies first:

- [Elixir](https://elixir-lang.org/install.html) (>= 1.4.2)
- [PostgreSQL](https://postgresapp.com/) (>= 9.6.2)
- [Yarn](https://yarnpkg.com/en/docs/install) (>= 0.24.6)
- [Elm](https://guide.elm-lang.org/install.html) (0.18.0)
- [nvm](https://github.com/creationix/nvm) ([optional](#nodejs))

Run the bootstrap script to install the remaining dependencies and create your
development database:

```
cd sprinkle
script/bootstrap
```

If your local PostgreSQL install does not have a default `postgres` user,
define the `SPRINKLE_DB_USERNAME` and `SPRINKLE_DB_PASSWORD` environment variables
first in your shell environment:

```
export SPRINKLE_DB_USERNAME=xxx
export SPRINKLE_DB_PASSWORD=yyy
```

Then run the bootstrap script again.

Use the `mix phx.server` command to start up your local server and visit
[`localhost:4000`](http://localhost:4000) from your browser.

### Node.js

This repository includes a `.nvmrc` file targeting a specific version of Node
that is known the be compatibile with all current node dependencies. Things might work
with a newer version of Node, but the most guaranteed route is to install
[Node Version Manager](https://github.com/creationix/nvm) and run `nvm install` from
the project root.

Then, be sure to run `script/bootstrap` or `cd assets && yarn` to install node dependencies
with the correct version of node.

### Elm

Much of the front-end is powered by [Elm](http://elm-lang.org/).
The Elm code lives in the `assets/elm/src` directory and the corresponding test files
live in the `assets/elm/tests` directory.

To run the Elm test suite, execute `script/elm-test` from the project root.

Note: When you install a new Elm package dependency, make sure you also add the same
dependency in the `tests` directory (the tests maintain their own set of dependencies).

### Routing

Sprinkle uses subdomains to keep track of which team you are viewing. There are a variety
of different techniques for configuring a local TLD to point at localhost. One option is to
edit your `/etc/hosts` file with something like this to make the Phoenix app available
at http://launch.sprinkle.dev:4000:

```
127.0.0.1  launch.sprinkle.dev    # required
127.0.0.1  yourteam.sprinkle.dev  # need an entry like this for every team you create
```

**Caveat**: The hosts file approach does not support wildcard subdomains, so you
will have to add a new entry every time you create a new team. That's a pain.

Dnsmasq is a handy utility that can be used to forward all `.dev` requests to localhost.
[Follow these instructions](http://asciithoughts.com/posts/2014/02/23/setting-up-a-wildcard-dns-domain-on-mac-os-x/) to set it up on macOS.

## Documentation

To generate and view low-level API documentation locally, run the following script:

```
script/docs
```

## Copyright

&copy; 2017 Derrick Reimer

Licensed under the Apache License, Version 2.0.
