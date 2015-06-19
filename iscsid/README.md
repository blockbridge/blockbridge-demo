iSCSI Daemon (iscsid) Container
================================================

Blockbridge storage is accessed over iSCSI. In order to facilitate using
Blockbridge Storage as a Container, we have provided a thin wrapper around
iscsid to run iscsid in a container.

This allows an iSCSI initiator to work on CoreOS and other container-only
operating systems, in addition to standard non-container platforms.

If your host is already running iscsid, we suggest disabling it and running it
through this container instead. While not strictly necessary, the Blockbridge
demo scripts that consume iscsid all expect iscsid to be running as a
container.

# Disable Host iscsid

If your host is running iscsid, a helper script can disable it:

    ./disable-host-iscsid.sh

# Run iscsid Container

Then simply run the iscsid container:

    ./run.sh

An iscsid container should now be running:

    $ docker ps
    CONTAINER ID IMAGE                     COMMAND      CREATED        STATUS        PORTS NAMES
    352611edad6d blockbridge/iscsid:latest "/bb/iscsid" 18 minutes ago Up 3 seconds  iscsid

# Run Parameters Description

The iscsid container requires specific parameters specified to docker run. They
are described here in detail.

* *--name "iscsid"* The name of the container
* *--privileged* The iscsid container loads a kernel module, and communicates
  via a NETLINK socket. Both of these are privileged operations.
* *--detach* Run the container in the background
* *--restart always* Restart the container on exit, and on boot.
* *--volume /proc/1/ns:/parent-ns* The container modifies the network namespace
  for the container to be its parent network namespace. This allows the iscsid
  container to run without host networking, allows the iSCSI initiator to
  talk to iscsid over the UNIX domain socket, and allows for iscsid to talk to
  the kernel over a NETLINK socket. When iscsid is made to correctly support network
  namespaces in the kernel, then this may not be needed.

# Where to go from here

Now that iscsid is running, its time to try out Blockbridge Storage as a
Container (Staac). See https://github.com/blockbridge/blockbridge-demo/staac.
