# Bridge

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/djreimer/bridge/tree/master)

## Development Environment

You'll need to install the following dependencies first:

- [Elixir](https://elixir-lang.org/install.html) (>= 1.4.2)
- [PostgreSQL](https://postgresapp.com/) (>= 9.6.2)
- [Yarn](https://yarnpkg.com/en/docs/install) (>= 0.24.6)

Run the bootstrap script to install the remaining dependencies and create your
development database:

```
cd bridge
script/bootstrap
```

If your local PostgreSQL install does not have a default `postgres` user,
define the `BRIDGE_DB_USERNAME` and `BRIDGE_DB_PASSWORD` environment variables
first.

Run the `mix phx.server` to start up your local server and visit
[`localhost:4000`](http://localhost:4000) from your browser.

## Documentation

To generate and view low-level API documentation locally, run the following script:

```
script/docs
```

## Copyright

&copy; 2017 Derrick Reimer

Licensed under the Apache License, Version 2.0.
