#!ruby
require 'set'

REMOTE_HOST = ARGV[0]
REMOTE_FS = ARGV[1]
LOCAL_FS = ARGV[2]
VERBOSE = ARGV[3]


if VERBOSE
  puts "remote_host: #{REMOTE_HOST}"
  puts "remote_fs: #{REMOTE_FS}"
  puts "local_fs: #{LOCAL_FS}"
end

def ssh_cmd(cmd)
  "ssh -n -x -p22 -o Compression=no -o ConnectTimeout=10 #{REMOTE_HOST} '#{cmd}'"
end

def zfs_list_snapshots_cmd(fs)
  "zfs list -H -r -d 1 -t snapshot -o name -s creation #{fs}"
end

def list_snapshots(list_cmd, host)
  puts list_cmd
  `#{list_cmd}`.lines.map do |line|
    line.sub("#{host}@", '').strip
  end
end

remote_snapshots_cmd = ssh_cmd(zfs_list_snapshots_cmd(REMOTE_FS))
remote_list = list_snapshots(remote_snapshots_cmd, REMOTE_FS)

local_list = list_snapshots(zfs_list_snapshots_cmd(LOCAL_FS), LOCAL_FS)

common_list = remote_list.to_set.intersection(local_list.to_set).to_a

ancestor = common_list.sort_by { |entry| remote_list.index(entry) }.last
most_recent = remote_list.last

if VERBOSE
  puts "Ancestor snapshot: #{ancestor}"
  puts "Most recent snapshot: #{most_recent}"
end

if ancestor != most_recent

  zfs_send = ssh_cmd("zfs send -I '#{REMOTE_FS}@#{ancestor}' '#{REMOTE_FS}@#{most_recent}'")
  zfs_receive = "zfs receive -F -u #{LOCAL_FS}"

  `#{zfs_send} | #{zfs_receive}`
end

if VERBOSE
  puts "Done"
end