# Running Bitfeed with Docker

## Images

Client and server container images are automatically built for each tagged release and available from the [Github Container Registry](https://github.com/bitfeed-project?tab=packages&repo_name=bitfeed):

Use like
```yml
image: ghcr.io/bitfeed-project/bitfeed-client:v2.1.2
```

```yml
image: ghcr.io/bitfeed-project/bitfeed-server:v2.1.2
```

Alternatively, build your own containers from source using the provided Dockerfiles:

#### Front end client
```shell
cd client
docker build . -t bitfeed/client:<version>
```

#### API Server
```shell
cd server
docker build . -t bitfeed/server:<version>
```

## Orchestration

Check out [`docker-compose.yml`](https://github.com/bitfeed-project/bitfeed/blob/master/docker-compose.yml) for an example configuration, which exposes the front end client on port 3000, and connects to a locally running Bitcoin node.