# ![Level](https://user-images.githubusercontent.com/341387/44097665-e7f114e4-9fa3-11e8-8641-39fb338897bd.png)

[![CircleCI](https://circleci.com/gh/levelhq/level.svg?style=svg)](https://circleci.com/gh/levelhq/level)

Level is an alternative to real-time chat designed for the software development workflow. 

**Sign up at [level.app](https://level.app)** to reserve your handle and get on the updates list.

## Project Status

Level is currently in the **pre-launch** phase and under active development by a small groups of people. Most tasks are being tracked offline as the foundations of the product come together, in the interest of rapid development and reaching an alpha stage for companies to start using it as quickly as possible.

Interested in helping out? My goal is to (eventually) keep some tasks filed in the [issue tracker](https://github.com/levelhq/level/issues) marked as good candidates for community contribution.

## Development Environment

You'll need to install the following dependencies first:

- [Elixir](https://elixir-lang.org/install.html) ([version](https://github.com/levelhq/level/blob/master/mix.exs#L4))
- [PostgreSQL](https://postgresapp.com/) 10
- [Yarn](https://yarnpkg.com/en/docs/install)
- [Node](#nodejs) ([version](https://github.com/levelhq/level/blob/master/.nvmrc))

Run the bootstrap script to install the remaining dependencies and create your
development database:

```
cd level
script/bootstrap
```

If your local PostgreSQL install does not have a default `postgres` user,
open the `config/dev.secret.exs` file and update the credentials.
Then, run the bootstrap script again.

Use the `script/server` command to start up your local server and visit
[`localhost:4000`](http://localhost:4000) from your browser.

### Node.js

This repository includes a `.nvmrc` file targeting a specific version of Node
that is known to be compatible with all current node dependencies. Things might work
with a newer version of Node, but the most guaranteed route is to install
[Node Version Manager](https://github.com/creationix/nvm) and run `nvm install` from
the project root.

Then, be sure to run `script/bootstrap` to install node dependencies with the
correct version of node.

### Elm

Much of the front-end is powered by [Elm](http://elm-lang.org/).
The Elm code lives in the `assets/elm/src` directory and the corresponding test files
live in the `assets/elm/tests` directory.

To run the Elm test suite, execute `script/elm-test` from the project root.

## Documentation

To generate and view the project documentation locally, run the following script:

```
script/docs
```

## Deployment

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/levelhq/level/tree/master)

## Copyright

&copy; 2018 Level Technologies, LLC

Licensed under the Apache License, Version 2.0.
