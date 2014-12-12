
    
if node.has_key?("ec2") 
    public_hostname = node[:ec2][:public_hostname]
    private_hostname = node[:ec2][:hostname]
    private_ip_address = node[:ipaddress]
    public_ip_address = node[:ec2][:public_ipv4]
    dns = public_hostname
    ipaddress = public_ip_address
else
    ipaddress = node[:ipaddress]
    dns = ipaddress
end


  
execute "apt-update" do
  command "sudo apt-get update"
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/updateapt")}
end
file "#{Chef::Config[:file_cache_path]}/updateapt" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

package "libssl0.9.8" do
  action :install
end

include_recipe "ulimit"
user_ulimit "root" do
  filehandle_limit 61440 # optional
  filehandle_soft_limit 61440 # optional; not used if filehandle_limit is set)
  filehandle_hard_limit 61440 # optional; not used if filehandle_limit is set)
  #process_limit 61504 # optional
  #memory_limit 1024 # optional
  #core_limit 2048 # optional
end

#version = node['riak']['version']
version =  "1.4.2-1"
remote_file "#{Chef::Config[:file_cache_path]}/riak_#{version}_amd64.deb" do
  user "root"
  source "http://s3.amazonaws.com/downloads.basho.com/riak/1.4/1.4.2/ubuntu/precise/riak_1.4.2-1_amd64.deb"
  action :create_if_missing
end
dpkg_package "riak_deb" do
  source "#{Chef::Config[:file_cache_path]}/riak_#{version}_amd64.deb"
  action :install
end

bash "config_riak" do
  cwd "/tmp/"
  code <<-EOH
    riak stop
    #rm -rf /var/lib/riak/ring
  EOH
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/riak_lock")}
end 
  
template "/etc/riak/app.config" do
  path "/etc/riak/app.config"
  source "app.config.erb"
  owner "root"
  group "root"
  mode "0644"
  variables :enviroment => node.chef_environment, :ipaddress => ipaddress
  #notifies :restart, resources(:service => "riak"), :immediately
end

template "/etc/riak/vm.args" do
  path "/etc/riak/vm.args"
  source "vm.args.erb"
  owner "root"
  group "root"
  mode "0644"
  variables :enviroment => node.chef_environment, :ipaddress => ipaddress
  #notifies :restart, resources(:service => "riak"), :immediately
end

=begin
bash "config_riak" do
  cwd "/tmp/"
  code <<-EOH
    riak start
    riak-admin cluster replace riak@127.0.0.1 riak@#{ipaddress}
  EOH
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/riak_lock")}
end 
=end



#riak-admin cluster replace riak@127.0.0.1 riak@54.247.68.179















file "#{Chef::Config[:file_cache_path]}/riak_lock" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end





