# podman maintains a base image that's already set up for both rootful and rootless usage of nested podman
FROM quay.io/podman/stable:latest

# do our customizations as root
USER root

# install ansible-builder
RUN python3 -m ensurepip && python3 -m pip install ansible-builder

# actually default the final image to use an unprivileged user inside the container; rootless podman FTW
USER podman
WORKDIR /home/podman

