# Base Docker container

Base container definition used across US CUNI projects.

Derived from the `gds_env` by Dani Arribas-Bel licensed under BSD 3-Clause (Copyright (c) 2018, Dani Arribas-Bel).

## Build a new version

Update the environment file and/or Dockerfile if you want to make changes to the container.

1. Update the `DOCKER_ENV_VERSION` in the `Dockerfile`, i.e. to `24.6` or `24.6.1` in case of a second version in the same month (example shows June 2024).
2. Build the container with the version tag

```sh
docker build -t ghcr.io/uscuni/base:24.7 .
```

3. Push the image to the GitHub Container Repository.

```sh
docker push ghcr.io/uscuni/base:24.7
```
