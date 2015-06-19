Blockbridge Storage as a Container (StaaC)
==========================================

Automated, Portable and Secure. Storage As A Container integrates Blockbridge
programmable storage with container based applications. Move applications
between hosts without data transfers and without generating load on your
infrastructure. Build diverse storage services with any level of performance,
scale, security, resiliency and cost.

Blockbridge provides Building Blocks to provide storage services to an
application. The first implementation of these primitives is the Blockbridge
`autovol` container.

# Autovol

The `autovol` container provisions storage, formats it, mounts it, and exports
the volume for use by an application. The application container then consumes
the volume normally using standard docker `--volumes-from autovol` command
syntax. The `autovol` volume is persistent, usable with any filesystem,
requires no host software or modification, works in manual or orchestrated
workflows, and has zero-copy migration to any host.

Run the `autovol` container for your application, then run your application.
Your data follows your application.

# MongoDB Example

As an example of `autovol` in action, we've created sample scripts to run a
MongoDB application with `autovol` backed persistent storage for the data.

The basic flow of using `autovol` for an application for the first time:

1. choose parameters for storage
1. run autovol container with those parameters in the environment
1. wait for autovol to start
1. run the application 

## Choose Parameters

`autovol` requires configuration parameters. They describe where to provision
storage, provide a unique label (for the application that is consuming it),
specify a storage capacity and provisioning attributes. These parameters are
passed

*BLOCKBRIDGE_API_HOST*: Blockbridge Management node IP address
*BLOCKBRIDGE_API_KEY*: Blockbridge management API token
*LABEL*: unique label for the storage service for the application
*CAPACITY*: storage capacity to provision
*ATTRIBUTES*: storage attributes. This determines what kind of storage to
provision, and is specific to the types of storage available on the Blockbridge
storage nodes. Can be attributes such as "+ssd" and "+cambridge" to provision
storage backed by an SSD in Cambridge.

## Run the application

Edit the `env.sh` script with the desired parameters. Then run the application:

    ./run.sh

This script will launch `autovol`, wait for the storage to be attached to the
host, then launch a MongoDB container consuming the storage.

## Additional Scripts

Scripts are also provided to `stop.sh` a running application, `start.sh` a
stopped application, and `cleanup.sh` the application.

## Try it out

Try two hosts. Run MongoDB on one host with the `run.sh` script. Then
`stop.sh`. And then `run.sh` it on a second host with the same `env.sh` script.
Your MongoDB has moved hosts. And the data has been attached to each host
on-demand.

# Future Containers

`autovol` is just the start. Stay tuned for future storage services,
including snapshots, raid devices, and more..
