#!ruby
require 'set'

REMOTE_HOST = ARGV[0]
REMOTE_FS = ARGV[1]
LOCAL_FS = ARGV[2]

puts "remote_host: #{REMOTE_HOST}"
puts "remote_fs: #{REMOTE_FS}"
puts "local_fs: #{LOCAL_FS}"

def ssh_cmd(cmd)
  actual = "ssh -n -x -p22 -o Compression=no -o ConnectTimeout=10 #{REMOTE_HOST} '#{cmd}'"
  puts actual
  actual
end

remote_zfs_list = ssh_cmd("zfs list -H -r -d 1 -t snapshot -o name -s creation #{REMOTE_FS}")
remote_list = `#{remote_zfs_list}`.lines
remote_list.map!{|list| list.sub("#{REMOTE_FS}@", '').strip}

local_list = `zfs list -H -r -d 1 -t snapshot -o name -s creation #{LOCAL_FS}`.lines
local_list.map!{|list| list.sub("#{LOCAL_FS}@", '').strip}

common_list = remote_list.to_set.intersection(local_list.to_set).to_a

ancestor = common_list.sort_by { |entry| remote_list.index(entry) }.last
most_recent = remote_list.last

if ancestor != most_recent

  zfs_send = ssh_cmd("zfs send -I '#{REMOTE_FS}@#{ancestor}' '#{REMOTE_FS}@#{most_recent}'")
  zfs_receive = "zfs receive -F -u #{LOCAL_FS}"

  `#{zfs_send} | #{zfs_receive}`
end