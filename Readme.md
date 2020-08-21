### Why

Simple, efficient way to backup zfs snapshots.  Meant to work with zfs-auto-snapshot or any other tool that periodically creates snapshots. The script establishes a common base and only sends missing snapshots.

### Assumptions

The local machine has ssh access to the remote machine.

### Usage

The first time zfs-snapshot-sync is executd it will bring across the oldest snapshot.

```
<remote>@snapshot-1  ->  <local>@snapshot-1
<remote>@snapshot-2
```

On the next execution it will incrementally bring across the remaining snapsjots including any new ones:

```
<remote>@snapshot-1  ->  <local>@snapshot-1
<remote>@snapshot-2  ->  <local>@snapshot-1
<remote>@snapshot-2  ->  <local>@snapshot-1
```

Hence all you have to do is run zfs-snapshot-sync from time to time.

`ruby zfs-snapshot-sync <remote-host> <remote-fs> <local-fs>`

For example

`ruby zfs-snapshot-sync file.server.com remote-tank/stuff local-tank/same-stuff`
