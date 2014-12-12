
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

file '/tmp/platform_version' do
  owner 'root'
  group 'root'
  mode '0666'
  content node['platform_version']
end




=begin
http://s3.amazonaws.com/downloads.basho.com/riak/2.0/2.0.2/ubuntu/precise/riak_2.0.2-1_amd64.deb


remote_file "#{Chef::Config[:file_cache_path]}/riak_2.0.2-1_amd64.deb" do
  user "root"
  source "http://s3.amazonaws.com/downloads.basho.com/riak/2.0/2.0.2/ubuntu/trusty/riak_2.0.2-1_amd64.deb"     
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

=end




