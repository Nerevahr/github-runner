# Github self-hosted runner Dockerfile and Kubernetes configuration

This repository contains a Dockerfile that builds a Docker image suitable for running a [self-hosted GitHub runner](https://docs.github.com/en/free-pro-team@latest/actions/hosting-your-own-runners). A Kubernetes Deployment file is also included that you can use as an example on how to deploy this container to a Kubernetes cluster.

You can build this image yourself, or use the Docker image from the [Docker Hub](https://hub.docker.com/repository/docker/michaelcoll/github-runner).

## Building the container

`docker build -t github-runner .`

## Features

* Organizational runners
* Labels
* Graceful shutdown
* Unregister on shutdown
* Packaged with maven, node, yarn, angular-cli

## Deploying to Kubernetes

1. Create the deployment:
```
$ kubectl apply -f deployment.yml
```

## Command line

Create an organization-wide runner.

```sh
docker run --name github-runner \
    -e ORG_NAME=organization \
    -e ORG_RUNNER=true \
    -e ACCESS_TOKEN=[a personal access toker with repo and admin scope] \
    -e LABELS=comma,separated,labels \
    michaelcoll/github-runner:latest
```

**The access token must have the repo and admin scope. The user that owns this access token must be part of the organisation.**
