include_recipe "aws"
data_bag("my_data_bag")
db = data_bag_item("my_data_bag", "my")
aws = db[ node.chef_environment]['aws']
AWS_ACCESS_KEY_ID = aws['AWS_ACCESS_KEY_ID']
AWS_SECRET_ACCESS_KEY = aws['AWS_SECRET_ACCESS_KEY']

aws_resource_tag node['ec2']['instance_id'] do
  aws_access_key aws['AWS_ACCESS_KEY_ID']
  aws_secret_access_key aws['AWS_SECRET_ACCESS_KEY']
  tags({"role_type" => "riak",
        "node_name" => "#{node.name}",
        "environment" => node.chef_environment})
  action :update
  ignore_failure true
end