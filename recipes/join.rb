data_bag("my_data_bag")
db = data_bag_item("my_data_bag", "my")
aws_access_key_id = db[node.chef_environment]['aws']['AWS_ACCESS_KEY_ID']
aws_secret_access_key = db[node.chef_environment]['aws']['AWS_SECRET_ACCESS_KEY']


easy_install_package "boto" do
  action :install
end

region_id = node[:ec2][:placement_availability_zone]
if region_id.include? "eu-west"
   region = "eu-west-1"
end
if region_id.include? "us-west-1"
   region = "us-west-1"
end
if region_id.include? "us-west-2"
   region = "us-west-2"
end
if region_id.include? "us-east-1"
   region = "us-east-1"
end

ipaddress = node[:ipaddress]

execute "start_riak" do
  command "sudo riak start"
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/riak_start")}
end
file "#{Chef::Config[:file_cache_path]}/riak_start" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end


script "riak_join_new_node" do
  interpreter "python"
  user "root"
  cwd "/tmp"
code <<-PYCODE
import time
import os
import boto
import boto.ec2
from boto.ec2.connection import EC2Connection
time.sleep(2)
region_id=boto.ec2.get_region('#{region}',aws_access_key_id='#{aws_access_key_id}',aws_secret_access_key='#{aws_secret_access_key}')
conn = EC2Connection(region=region_id,aws_access_key_id='#{aws_access_key_id}', aws_secret_access_key='#{aws_secret_access_key}')
reservations = conn.get_all_instances()
instances = [i for r in reservations for i in r.instances]
       
master_join_ip=None
for i in instances:
    if '#{ipaddress}' != str(i.private_ip_address):
        if i.tags.has_key('role_type'):
          if str(i.tags['role_type']).strip()=='riak' and str(i.tags['environment']).strip()=='#{node.environment}':
              master_join_ip = str(i.private_ip_address)
              os.system('touch /tmp/bitch')
              break

if master_join_ip:  
    cmd = "sudo riak-admin cluster join riak@%s" % (master_join_ip)
    os.system(cmd)
    time.sleep(3)
    cmd = "sudo riak-admin cluster plan"
    os.system(cmd)
    time.sleep(3)
    cmd = "sudo riak-admin cluster commit"
    os.system(cmd)
    
PYCODE
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/riak_join_new")}
end



file "#{Chef::Config[:file_cache_path]}/riak_join_new" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end
