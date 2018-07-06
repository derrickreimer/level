## docker-compose-based dev environment

### Start all containers
...and display aggregated logs from all containers
```
docker-compose up --build
```

- `--build` ensures that the images are rebuilt first if the dependencies have changed

### Start the server container
...and attach to its stdout
```
docker-compose run --service-ports --rm level-dev
```

- also starts db container if it is not running already, thanks to
  depends_on in dockerfile.xml (can be overridden with `--no-deps`),
  but db container's logs are not displayed on screen as in the `up` case.
- `--service-ports` ensures 4000 is mapped to the host (happens automatically
  on `up` but not on `run`)
- `--rm` throws away the level container's state when we exit (by default it is
  persisted on disk and can be restarted).


### (Re)build the Level image
```
docker-compose build level-dev
```

- there is no `--build` flag when using `docker-compose run`, hence you might
  want to do `build` before `run`, or you might get a stale image if the project's
  dependencies have changed since the last build.


### Start an interactive bash shell in the server container
`docker-compose run --service-ports --rm level-dev bash -l`
...then, to start the server:
`./script/server`

### Run tests
```
docker-compose build level-dev
docker-compose run --rm level-dev ./script/elixir-test
docker-compose run --rm level-dev bash -l -c './script/elm-test' # need -l to invoke nvm
docker-compose run --rm level-dev ./script/static-analysis
```

### Open a database REPL
```
docker exec -ti level_level-dev-db_1 psql -U postgres -d level_dev
```

...assuming the db container is already running via some of the above commands


### Terminate all containers and destroy the database
```
docker-compose down
```
