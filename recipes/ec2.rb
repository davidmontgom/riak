
=begin
execute "bootstrap_ohai_ec2" do
  command "sudo mkdir -p /etc/chef/ohai/hints && sudo touch /etc/chef/ohai/hints/ec2.json"
  action :run
  ignore_failure true
  not_if {File.exists?("/etc/chef/ohai/hints/ec2.json")}
end
=end


directory "/etc/chef/ohai/hints" do
  owner "root"
  group "root"
  recursive true
  action :create
end

file "/etc/chef/ohai/hints/ec2.json" do
  owner "root"
  group "root"
  action :create
end

