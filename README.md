## containerized ansible-builder + rootless podman in rootless podman

The `podman` container runtime has long supported "true" container runtime nesting; taking advantage
of this allows for easy ephemeral ansible-builder test environments. This project provides a sample
Containerfile that can be used to splat a collection checkout into an EE definition, build the
EE via ansible-builder, and run ansible-test sanity on the results, all within a completely
isolated rootless podman session.

This could serve as a prototype for an isolated/ephemeral PE validation environment, as well as
a future Galaxy/AH importer (probably with some additional guardrails around internet access and
strict runtime limits). 


```
# tested on Fedora 38 w/ podman 4.6.2 installed and SELinux in enforcing mode, YMMV on other distros/configs

# run the following from inside a checkout of this project

# build a container with podman and ansible-builder inside it (defined in ./Containerfile)
podman build . -t builder-in-a-can

# clone a collection to stuff into an EE into this directory
git clone https://github.com/ansible-collections/ansible.utils

# fire up an ephemeral instance of the builder-in-a-can container under rootless podman that maps this dir to /host_files
# disable selinux label propagation
# run a command to keep it alive for awhile so we can mess around with it and it'll eventually disappear
podman run -v .:/host_files --security-opt label=disable --rm --name=test-builds -d builder-in-a-can:latest sleep 360

# generate an EE def that copies in the collection to test
cat execution-environment.yml

# run builder inside our container against the EE def we created (podman inception!)
podman exec -it test-builds ansible-builder build -v3 -f /host_files/execution-environment.yml -t test-ee

# now run an interactive bash session in an ephemeral instance of the EE we just created, inside our container (podman inception again!)
# only running with "--user root" in the innermost container because `ansible-test sanity` needs to be able to write to the collection install location
# when doing this "for real", could run galaxy importer test scripts or whatever instead of an interactive session
podman exec -it test-builds podman run --user root -it test-ee bash

# from there, poke at the installed collection, run ansible-test sanity, whatever else we want...

# verify we installed the collection from source
ansible-galaxy collection list

# run ansible-test sanity tests under the install dir
(cd /usr/share/ansible/collections/ansible_collections/ansible/utils && ansible-test sanity -v --python 3.9)

# after 360s timeout elapses, the entire thing disappears
```
