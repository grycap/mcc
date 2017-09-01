# MCC - My Container Cluster
This is a tool that automates the creation of container based computing clusters. The basic workflow of this tool is the next:

1. Create a network that will be used to communicate the nodes in the cluster
2. Create a container that will act as the front-end of the cluster
3. Create some other containers that will act as the working nodes of the cluster

MCC automates all the tasks to create and configure the cluster. So it enables to contextualize the containers to execute a set of commands as the container are created. This enables, as an example, to include a script that installs a ssh-server in the container. Moreover, MCC tweaks the /etc/hosts file to enable an easy communication between the front-end and the working nodes (i.e. using nodeXX names).

## Examples of usage
A simple run of MCC will be the next:

```bash
$ ./mcc create --front-end-image ubuntu: --working-node-image ubuntu --nodes 2 --enter-cluster
```

That will create a ubuntu-based front-end cluster and will provide a shell script.

A more advanced usage will be the next one:

```bash
$ ./mcc create --front-end-image ubuntu: --working-node-image ubuntu --nodes 2 --device home --enter-cluster
```

This will create a cluster with a shared /home folder between the different nodes.

Other example, with contextualization is the next one:

```bash
$ ./mcc create --front-end-image images:alpine/3.4 --working-node-image images:alpine/3.4 --nodes 2 --context-folder context/alpine --device home --enter-cluster
```
This example creates an alpine-based cluster with one front-end and two computing nodes, it contextualizes the nodes by installing a ssh server (using the scripts provided in the MCC distro), and creates a shared /home folder accesible by all the nodes.

## Full ASCIINEMA session to install MCC and to create a cluster
[![MCC Install session](https://asciinema.org/a/eub9urzlhdz3k4h4z1rmr1uvc.png)](https://asciinema.org/a/eub9urzlhdz3k4h4z1rmr1uvc)

## Functions
The functions included in mcc are:

- list: lists the clusters that are running
- addnode: adds nodes to one cluster
- create: creates one cluster
- delete: deletes one cluster
- enter: enter in a running cluster
- delnode: deletes nodes from the cluster

Using the classic ```--help``` flag, each function will provide help about its usage. As an example:
```bash
$ ./mcc create --help
```

## MCC and LXD
MCC is currently very tightened to LXD, but it will be easy to implement some functions to integrate with e.g. Docker (see section 'Internals').

You will require a recent version of LXC and LXD. In particular, LXC v2.0.8 shipped with Ubuntu 16.04 does not support the required ``lxc network`` command. You can upgrade to the latest version of LXC and LXD with the commands:
```
sudo add-apt-repository ppa:ubuntu-lxc/lxc-stable
sudo add-apt-repository ppa:ubuntu-lxc/lxd-stable
sudo apt-get update
sudo apt-get upgrade lxc lxd
```

Anyway, it is advisable that you create a profile dedicated to _mcc_, in order to be able to manage the features of the containers. E.g. the _default_ profile contains a network device in _eth0_ and that will make that _mcc_ will not work. So it is recommended to create a profile named mcc:

```bash
lxc profile create mcc
```

And then configure _mcc_ to use it in the config file, by adding "-p mcc" to the variable LXC_LAUNCH_OPTS. E.g.:
```bash
LXC_LAUNCH_OPTS='-p mcc'
```

### Privileged containers
Sometimes you will need privileged containers. In that case, you can add that feature in the profile:

```bash
lxc profile set mcc security.privileged true
```

In my case, I needed to launch docker containers _inside_ the LXC-based _mcc_ cluster, and I wanted to set the user that launched the container using the _-u_ option of _docker run_.

## Internals (for developers)

### Multiple host
The current version is implemented for a single-host deployment. That means that all the containers will be executed in the same host. This is very useful for testing purposes.

In case that you want to make a multi-host environment, you should take into account the following advices:
- The networks should span accross the hosts (e.g. you should use a specific interface for the networks, and you should create all the networks in all the hosts, but only one of them should provide a DHCP server and a NAT services). For the case of **docker** you could create overlay networks.
- You should make the selection of the host in which the container is being deployed and deploy the container (e.g. using the remote API of lxd). For the case of **docker** you could use kubernetes or docker swarm.
- The device __sharedfolder__ could be implemented like this: use a nfs server that exports a path. Mount that path in all the virtualization hosts. MCC will create the path for the proper folder in that path, in the host that exports the shared folder, and all the containers will map the folder into them.

### Using other containers (e.g. docker)
This developments is a set of scripts that automate the creation of the cluster by abstracting different concepts such as "container", "cluster", "network" or "devices".

You should be able to use docker containers or virtual machines by creating the proper implementation for your platform. In this case, you should simply adapt the functions under the _platform_ folder to execute the effective commands for your platform. Some examples are (for the case of docker):

- **_CONTAINER__launch**: This function should end up by issuing a command like ```docker run ...```.
- **_CONTAINER__stop**: This function should issue a command like ```docker stop ...```.
- **_CONTAINER__exists**: This function could issue a command like ```docker ps``` to search for the container.
- **_NETWORK__get_node_ip**: This function probably would issue a command like ```docker inspect``` and then will get the output to get the IP address of the node.
