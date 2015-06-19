Blockbridge Command Line Tool
=============================

The Blockbridge CLI provides a tool to manage Blockbridge storage services. The
command line tool allows the user to provision new storage, perform actions on
that storage, query status and information about the storage services, and so
forth.

The Blockbridge CLI can run on any host, and can be configured to connect to
any Blockbridge Management API endpoint. However, a shell wrapper around the
CLI is available as a container for ease of administration in a container
workflow.

The Blockbridge CLI container can run in one of two modes. Either the
management node is local and the CLI is linked directly to it. Or the
management node is remote, and an IP address must be configured for the
management API host.

# Local Management

To manage a local Blockbridge management node, run the local helper script:

    ./run-local.sh

This will spawn a Blockbridge CLI shell that is linked to the local management
node.

Once connected, login with the configured user credentials for the user, or an
API token.

    bbcli> auth login
    Enter user or access token: block
    Password for block: **********

Note: the login session will only be valid for the lifetime of the container
(and also may time out due to inactvity). Exiting the CLI stops the container.
Next time the CLI container is started, you will be required to login again.

# Remote Management

If managing a remote Blockbridge management node, set an IP address in the
BLOCKBRIDGE_API_HOST environment variable (or edit run-remote.sh script to set
one). Then run the remote script:

    ./run-remote.sh

And login as shown above.

# Command Line Help

The Blockbridge CLI is full featured. Each command has detailed help. For a
list of commands type:

    help

To provision and view storage services, use the commands under:

    vss

Management commands for disks, snapshots, etc. can be found under:

    disk
    snapshot

# Examples

Provision a storage service with a disk:

    bbcli> vss provision -c 32GiB --with-disk
    == Created vss: service-1 (VSS1862194C40626440)

    == VSS: service-1 (VSS1862194C40626440)
    label                 service-1                
    serial                VSS1862194C40626440      
    created               2015-06-09 21:21:28 +0000
    status                online                   
    current time          2015-06-09T21:21+00:00   

List information about the newly created disk:

    bbcli> disk
    label [2]  serial               vss [1]                          capacity  size size limit  status
    ---------  -------------------  -------------------------------  -------- -------  ----------  ------
    disk-1     DSK1962E94C40626440  service-1 (VSS1862194C40626440)  32.0GiB 1.13MiB  none        online


    bbcli> disk info
    == Virtual disk: disk-1 (DSK1962E94C40626440)
    label                 disk-1                         
    serial                DSK1962E94C40626440            
    created               2015-06-09 21:21:28 +0000      
    status                online                         
    vss                   service-1 (VSS1862194C40626440)
    capacity              32.0GiB                        
    encryption            aes256-gcm                     
    vault                 unlocked                       
    tags                  -none-      
