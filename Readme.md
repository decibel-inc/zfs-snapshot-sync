### Why

Simple, efficient way to backup zfs snapshots.  Meant to work with zfs-auto-snapshot or any other tool that periodically creates snapshots. The script establishes a common base and only sends missing snapshots.

### Assumptions

The local machine has ssh access to the remote machine.

### Usage

Assuming existing file system on remote machine, establish a local copy:

`ssh remote_host 'zfs send remote-tank/stuff' | zfs receive local-tank/stuff`

Then run zfs-snapshot-sync to periodically bring across any snapshots

`ruby zfs-snapshot-sync <remote-host> <remote-fs> <local-fs>`

For example

`ruby zfs-snapshot-sync file.server.com remote-tank/stuff local-tank/same-stuff`
