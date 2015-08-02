Blockbridge EPS Simulator
=========================

The Blockbridge simulator makes it easy to try Elastic Programmable Storage
(EPS) in a non-production environment. EPS provides secure multi-tenant iSCSI
block storage as a service. It implements hardware agnostic thin-provisioning,
snapshots, clones, automatic encryption, secure erase, replication, quality of
service, and a ton of other features. Tenant management and data are securely
isolated. Each tenant can exercise complete control over storage operation and
management with APIs and tools that are powerful and simple to use.

### Use Cases

* Secure Multi-tenant Storage for OpenStack
* Storage As A Container for Docker
* Storage As A Service / Self-Service for DevOps
* Disaster Tolerance
* High Performance
* IT Automation
* Application / Customer Isolation
* Simulate Performance and Failure Scenarios

### Not For Production Use

_Note_: The simulator is for non-production use only; no guarantee or warranty
is provided. Use at your own risk. The simulator is provided for trial and demo
purposes only. Please see the `Limitations` section below.

### Docker Container

The Blockbridge EPS simulator is available as a set of Docker containers. The
simulator has no dependencies on host software, other than Docker. No drivers
or special configuration is required. Setup takes about one minute depending on
your network connectivity.

This demonstration repository contains several scripts that instantiate and
configure simulator containers.  The scripts retrieve docker images from the
public docker hub.

### Supported Platforms

The Blockbridge storage simulator container runs on Docker on the following
platforms:

| Linux version      | Docker version | Docker installation
| ------------------ | -------------- | -------------------
| RHEL 7.1           | 1.5.0-dev+     | included
| CentosOS 7.1.1503  | 1.5.0-dev+     | included
| Ubuntu 14.04       | 1.6.0+         | https://docs.docker.com/installation/ubuntulinux/
| CoreOS 681+        | 1.6.0+         | included
| boot2docker 1.6.0+ | 1.6.0+         | included
| kitematic 0.5.25+  | 1.6.0+         | included

# Installation and Configuration

A minimal Blockbridge deployment consists of two nodes: management and
storage. Each node may be instantiated as a container. The containers may be
deployed on a single host or multiple hosts.

An instance of a simulator container operates either as a management node or a
storage node. Storage node instances provide iSCSI storage services (the data
path). Management node instances provide configuration services (the control
path). Management services are accessible via web UI, CLI, or API.  A single
management node supports many storage nodes.

This README describes how to start a simulator with public or private
networking. The next section details what the networking requirements are.

## Networking

A key part of successfully deploying the Blockbridge simulator beyond a trivial
use case lies in understanding how you're going to access it. Each simulator
container can be configured to present services on any network addresses you
choose. If you plan to use a single host with local data traffic, the default
private networking provided by Docker is all you need.  Otherwise, you will
need to define Public networking.

### Private Networking

With private networking:

- containers are run on a single host,
- management services are locally and remotely accessible, and
- data services are locally accessible.

If you plan for something fancier, read on.  Otherwise, skip ahead to
Examples.

### Public Networking

With public networking:

- containers may operate on multiple hosts,
- management services are remotely accessible, and
- data services are remotely accessible.

To access storage services from remote hosts, storage containers must be
supplied with a unique IP address. The address must be configured on a host
interface and be externally accessible.

### Multi-Host Deployments

If you plan to deploy containers on multiple hosts, all containers
(including the management container) must be supplied with unique IP
addresses. These addresses must be configured on host interfaces and be
externally accessible.

## Starting the Simulator

We have created several scripts for you to run and reference. Each example
directory contains a `run` script for instantiating a container with public or
private networking, a `stop` script to stop the container, a `start` script to
restart a stopped container, and a `cleanup` script to remove the container and
its volumes.

Additionally, there are scripts which allow you to independently operate a
single management node and single storage node. These may be used to operate
independent nodes in a multi-host deployment. In addition there are scripts for
turn-key setups comprised of a management node and one or three storage nodes.
These scripts are intended for demonstration using a single host.

### How to get the scripts?

Clone the Blockbridge demo repository from GitHub. Change directory to
the simulator scripts.

```bash
git clone https://github.com/blockbridge/blockbridge-demo.git
cd blockbridge-demo
```

### The simplest way to get started using a single host

The easiest way to get started is to deploy the simulator with private
container networking using one of the 'complete' setup scripts.

    ./simulator/complete_two_node/run_private.sh

The `complete_two_node` script launches a management node container,
links a storage node container to it, sets up a default device for
storage, generates default user account credentials and prints out the
summary of what happened to the container logs.

### I have another https application!  Can I change the port?

Yes!  If, say, you wanted to change the port to 4433 (from 443), start
the simulator like this:

```bash
BB_MN_SSL_PORT=4433 ./simulator/complete_two_node/run_private.sh
```

### A more flexible setup with public networking

If you'd like to access the storage from a remote host, you can run the
simulator containers with public networking configured. This will assign an
accessible IP address to each container and open ports on the host that NAT to
the containers. Each container that starts should be allocated and assigned an
externally accessible IP address.

Note that in a `complete_two_node` setup, you need only a single IP address
because storage containers and management containers provide services on
non-overlapping ports. Any single external address on the system may be used.

Let's run the complete two-node setup again with public addresses. The IP
addresses can be specified on the command line, exported to the shell
environment, or edited in the script directly.

Here, start the nodes directly from the command line:

    BB_MN_SIM_IP="172.16.5.17" BB_SN_SIM_IP="172.16.5.17" ./simulator/complete_two_node/run-public.sh

and... Bob's your uncle.

# Simulator Parameters

The simulator takes much of its configuration from parameters supplied to
`docker run` when it starts.  This section describes these parameters and their
preferred values in detail.

## Run a Management Node

* `--name "bbsim-mn"`: the name of the container
* `--env BB_SIM_MODE="management"`: specifies to run the simulator in management mode
* `--privileged`: The simulator allocates POSIX message queues with
  requirements beyond the default system limits, and it queries network link
  state. Since the simulator is supported on platforms with both selinux
  enabled and disabled for Docker, specifying `--privileged` allows for a
  common set of parameters for all platforms. On non-selinux enabled platforms,
  it is possible instead to use a subset of capabilities by specifying
  `--cap-add sys_resource --cap-add net_admin`.
* `--ulimit msgqueue=-1`: Large message queues are required for log messages.
  This removes system limits (ie: ulimit -q unlimited)

With public networking:

* `--env BB_SIM_IP="$BB_MN_SIM_IP"`: Defines the host address to assign to the
  container. This IP must exist on the host system that is running the
  container and be externally accessible.
* `--publish "$BB_MN_SIM_IP:443:443"`: Publish the management node IP address
  on port 443. The host port can be modified to listen on any other port as
  needed. The container port must be 443.
* `--publish "$BB_MN_SIM_IP:80:80"`: Publish the management node IP address on
  port 80 for https redirect. The host port can be modified to listen on any
  other port as needed. The container port must be 80.

## Run a Storage Node

* `--name "bbsim-sn1"`: Defines the name of the container. Storage nodes are
  named bbsim-sn1, bbsim-sn2, etc.
* `--env BB_SIM_MODE="storage"`: Specifies to run the simulator in storage mode.
* `--env BLOCKBRIDGE_API_KEY="$BB_MN_API_KEY"`: The API key generated or set in
  the management node must be passed to each storage node.
* `--privileged`: This is required for message queue allocation and network
  link state as described above.
* `--ulimit msgqueue=-1`: Large message queues are required for log messages
  and statistics. This removes system limits (ie: ulimit -q unlimited).
* `--ulimit memlock=-1`: memory beyond the default system limits is locked by
  the storage processor. This removes system limits (ie: ulimit -l unlimited)

With private networking:

* `--link bbsim-mn:mn`: Link to the management node container `bbsim-mn` with alias of `mn`.

With public networking:

* `--env BLOCKBRIDGE_API_HOST="$BB_MN_SIM_IP:$BB_MN_SSL_PORT"`: Specify the
  management node public IP address, and the management node port (default is
  443).
* `--publish $BB_SN_SIM_IP:3260:3260`: Publish the public IP address specified
  to the container for port 3260 (iSCSI) for storage services.

