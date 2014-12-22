


service "monit"
template "/etc/monit/conf.d/riak-monit.conf" do
  path "/etc/monit/conf.d/riak-monit.conf"
  source "riak-monit.conf.erb"
  owner "root"
  group "root"
  variables(
    :process_matching => "/usr/lib/riak/erts-5.10.3/bin/beam.smp", 
    :start_program =>  "riak start",
    :http_host => "localhost",
    :http_port => "8098"
  )
  notifies :restart, resources(:service => "monit")
end


=begin
service "monit"
template "/etc/monit/conf.d/riak-monit.conf" do
  path "/etc/monit/conf.d/riak-monit.conf"
  source "riak-monit.conf.erb"
  owner "root"
  group "root"
  variables(
    :process_matching => node['riak']['monit']['process_matching'],
    :start_program => node['riak']['monit']['start_program'],
    :http_host => node['riak']['monit']['http_host'],
    :http_port => node['riak']['monit']['http_port']
  )
  notifies :restart, resources(:service => "monit")
end
=end