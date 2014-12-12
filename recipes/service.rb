ipaddress = node[:ipaddress]


execute "riak-restart" do
  command "riak stop && riak start"
  action :nothing
end
   
template "/etc/riak/app.config" do
  path "/etc/riak/app.config"
  source "app.config.erb"
  owner "root"
  group "root"
  mode "0644"
  variables :enviroment => node.chef_environment, :ipaddress => ipaddress
  notifies :run, "execute[riak-restart]", :delayed
  #notifies :restart, resources(:service => "riak"), :immediately
end


template "/etc/riak/vm.args" do
  path "/etc/riak/vm.args"
  source "vm.args.erb"
  owner "root"
  group "root"
  mode "0644"
  variables :enviroment => node.chef_environment, :ipaddress => ipaddress
  notifies :run, "execute[riak-restart]", :delayed
  #notifies :restart, resources(:service => "riak"),:immediately
end


=begin
service "riak" do
  supports :restart => true,:start => true, :stop => true
  action [ :enable]
end
=end

=begin
execute "stop_riak" do
  command "service riak stop"
  action :run
  not_if {File.exists?("#{Chef::Config[:file_cache_path]}/reip")}
end
=end
