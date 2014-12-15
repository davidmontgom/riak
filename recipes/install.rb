


datacenter = node.name.split('-')[0]
server_type = node.name.split('-')[1]
location = node.name.split('-')[2]

package "libssl0.9.8" do
  action :install
end
package "python-dev" do
  action :install
end
package "python-setuptools" do
  action :install
end
package "python-pip" do
  action :install
end

execute "pexpect" do
  command "sudo pip install pexpect"
  action :run
end

script "openssl_bash" do
  interpreter "python"
  user "root"
  cwd "/var/"
code <<-PYCODE
import pexpect
import os
child = pexpect.spawn ('openssl genrsa -des3 -out server.key 1024')
child.expect ('key*')
child.sendline ('YYYY')
child.expect ("key*")
child.sendline ('YYYY')
child.expect(pexpect.EOF)
child = pexpect.spawn ('openssl req -new -key server.key -out server.csr')
child.expect ('key*')
child.sendline ('YYYY')
child.expect ('Country .*')
child.sendline ('US')
child.expect ('State .*')
child.sendline ('HI')
child.expect ('Locality .*')
child.sendline ('US')
child.expect ('Organization Name .*')
child.sendline ('US')
child.expect ('Organizational Unit Name .*')
child.sendline ('US')
child.expect ('Common Name .*')
child.sendline ('US')
child.expect ('Email .*')
child.sendline ('gg@gmail.com')
child.expect ('A .*')
child.sendline ("YYYY")
child.expect ('An .*')
child.sendline ("YYYY")
child.expect(pexpect.EOF)
cmd = "cp server.key server.key.org"
os.system(cmd)
child = pexpect.spawn ('openssl rsa -in server.key.org -out server.key')
child.expect ('Enter .*')
child.sendline ("YYYY")
child.expect(pexpect.EOF)
cmd = "openssl x509 -req -days 1000 -in server.csr -signkey server.key -out server.crt"
os.system(cmd)
PYCODE
  not_if {File.exists?("/var/server.crt")}
end


if node['platform_version']=='12.04'
  platform_name = 'precise'
end
if node['platform_version']=='14.04'
  platform_name = 'trusty'
end


remote_file "#{Chef::Config[:file_cache_path]}/riak_2.0.2-1_amd64.deb" do
  user "root"
  source "http://s3.amazonaws.com/downloads.basho.com/riak/2.0/2.0.2/ubuntu/#{platform_name}/riak_2.0.2-1_amd64.deb"     
  action :create_if_missing
end

dpkg_package "riak_deb" do
  source "#{Chef::Config[:file_cache_path]}/riak_2.0.2-1_amd64.deb"
  action :install
end

service "riak" do
  supports :restart => true,:start => true, :stop => true
  action [:start,:enable]
end


execute "riak-restart" do
  command "riak stop && riak start"
  action :nothing
end
 
#8098 8087
ipaddress = node[:ipaddress]  
public_ipaddress = ipaddress
if node.chef_environment=='local'
  ipaddress = '127.0.0.1'
  public_ipaddress = '127.0.0.1'
end

template "/etc/riak/riak.conf" do
  path "/etc/riak/riak.conf"
  source "riak-#{node['platform_version']}.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables :enviroment => node.chef_environment, :ipaddress => ipaddress, :public_ipaddress => public_ipaddress
  #notifies :run, "execute[riak-restart]", :delayed
  notifies :restart, resources(:service => "riak"), :immediately
end



if datacenter != "local"
  
data_bag("my_data_bag")
db = data_bag_item("my_data_bag", "my")
AWS_ACCESS_KEY_ID = db[node.chef_environment]['aws']['AWS_ACCESS_KEY_ID']
AWS_SECRET_ACCESS_KEY = db[node.chef_environment]['aws']['AWS_SECRET_ACCESS_KEY']
zone_id = db[node.chef_environment]['aws']['route53']['zone_id']
domain = db[node.chef_environment]['aws']['route53']['domain']

easy_install_package "boto" do
  action :install
end

script "riak_cluster_add" do
  interpreter "python"
  user "root"
  cwd "/root"
code <<-PYCODE
import os
from boto.route53.connection import Route53Connection
from boto.route53.record import ResourceRecordSets
from boto.route53.record import Record
import hashlib

conn = Route53Connection('#{AWS_ACCESS_KEY_ID}', '#{AWS_SECRET_ACCESS_KEY}')
records = conn.get_all_rrsets('#{zone_id}')
ipaddress = None
for record in records:
  if record.name.find('riak')>=0 and record.name.find('#{location}')>=0 and record.name.find('#{node.chef_environment}')>=0 and record.name.find('#{datacenter}')>=0:
    if record.resource_records[0]!='#{node[:ipaddress]}':
      ipaddress=record.resource_records[0]
      break

if ipaddress:
  cmd = "riak-admin cluster join riak@%s" % (ipaddress)
  os.system(cmd)
  cmd  = "riak-admin cluster plan"
  os.system(cmd)
  cmd = "riak-admin cluster commit"
  os.system(cmd)
  
os.system("touch #{Chef::Config[:file_cache_path]}/riak.lock")
PYCODE
not_if {File.exists?("#{Chef::Config[:file_cache_path]}/riak.lock")}
end

end





