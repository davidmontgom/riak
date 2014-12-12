default['riak']['version'] = "1.4.2-1"
default['riak']['data_dir'] = "/usr/lib/riak"

default['riak']['monit']['process_matching'] = "#{node['riak']['data_dir']}/erts-5.9.1/bin/beam.smp"
default['riak']['monit']['start_program'] = "riak start"
default['riak']['monit']['stop_program'] = "riak stop"
default['riak']['monit']['http_host'] = "localhost"
default['riak']['monit']['http_port'] = "8098"



