#!/usr/bin/ruby
require 'set'
require 'open3'

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
  `#{list_cmd}`.lines.map do |line|
    line.sub("#{host}@", '').strip
  end
end

_, _, status = Open3.capture3("zfs list #{LOCAL_FS}")
local_fs_exists = status == 0

remote_snapshots_cmd = ssh_cmd(zfs_list_snapshots_cmd(REMOTE_FS))
remote_list = list_snapshots(remote_snapshots_cmd, REMOTE_FS)
oldest = remote_list.first
most_recent = remote_list.last


if local_fs_exists
  local_list = list_snapshots(zfs_list_snapshots_cmd(LOCAL_FS), LOCAL_FS)
  common_list = remote_list.to_set.intersection(local_list.to_set).to_a
  ancestor = common_list.sort_by { |entry| remote_list.index(entry) }.last
  
  zfs_send_arguments = "-I '#{REMOTE_FS}@#{ancestor}' '#{REMOTE_FS}@#{most_recent}'"
  zfs_receive_arguments = "-F -u #{LOCAL_FS}"
else
  zfs_send_arguments = "#{REMOTE_FS}@#{oldest}"
  zfs_receive_arguments = "#{LOCAL_FS}@#{oldest}"
end

if VERBOSE
  puts "Ancestor snapshot: #{ancestor}"
  puts "Most recent snapshot: #{most_recent}"
end

zfs_send = ssh_cmd("zfs send #{zfs_send_arguments}")
zfs_receive = "zfs receive #{zfs_receive_arguments}"

if ancestor != most_recent
  `#{zfs_send} | #{zfs_receive}`
end

if VERBOSE
  puts "Done"
end
