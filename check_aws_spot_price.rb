#!/usr/bin/env ruby

require 'aws-sdk'
require 'optparse'
require 'ostruct'
require 'pp'

options = OpenStruct.new
OptionParser.new do |opts|
  opts.banner = "Usage: check_aws_spot_price.rb [options]"

  opts.on("-a", "--access_key access_key", "AWS access key") do |a|
    options.access_key = a
  end

  opts.on("-s", "--secret_key secret_key", "AWS secret key") do |s|
    options.secret_key = s
  end 

  opts.on("-g", "--autoscaling_group autoscaling_group", "Autoscaling group to inspect") do |g|
    options.autoscaling_group = g
  end

  opts.on("-r", "--region region", "Region to look at") do |r|
    options.region = r
  end

  opts.on("-d", "--debug", "Print debug output") do |d|
    options.debug = true
  end

end.parse!

# Validate options
missing_options = %w{access_key secret_key autoscaling_group region}.select do |param|
  options.send(param.to_sym) == nil
end

if missing_options.length > 0
  puts "Missing options, use --help for help: #{missing_options.join(", ")}"
  exit 1
end

# Auth with AWS
AWS.config({
  :access_key_id        => options.access_key,
  :secret_access_key    => options.secret_key,
  :region               => options.region
})

# Look for scaling group, and get launch config
as = AWS::AutoScaling.new
as_group = as.groups[options.autoscaling_group]
lc = as_group.launch_configuration

# If this is a VPC-based AS group, then it will have subnets listed in it
vpc = false
if as_group.subnets != nil
  vpc = true
end

# Look at each AZ the scaling group is in, and read the spot price for that AZ;
# if the launch config's bid price is below this, we can't launch instances, so that
# will raise a CRITICAL back to Nagios.

azs_in_danger = []
azs = []
ec2 = AWS::EC2.new
as_group.availability_zone_names.each do |az|

  # This will return a result set that contains the last price change only
  resp = ec2.client.describe_spot_price_history({
    :instance_types       => [lc.instance_type],
    :availability_zone    => az,
    :product_descriptions => [(vpc ? "Linux/UNIX (Amazon VPC)" : "Linux/UNIX")],
    :max_results          => 1
  })
  current_price = resp[:spot_price_history_set].first[:spot_price]
  last_change_time = resp[:spot_price_history_set].first[:timestamp]

  info = {
    :az => az, 
    :current_price => current_price, 
    :last_change_time => last_change_time, 
    :bid => lc.spot_price, 
    :vpc => vpc, 
    :instance_type => lc.instance_type
  }

  if lc.spot_price < current_price
    azs_in_danger << info
  else
    azs << info
  end

end

if azs_in_danger.length > 0
  output = azs_in_danger.map do |az_info|
    "AZ #{az_info[:az]}, instance type #{az_info[:instance_type]}, price is #{az_info[:current_price]} but bid is #{az_info[:bid]}, changed at #{az_info[:last_change_time]}"
  end.join("; ")
  puts "CRITICAL: #{output}"
  exit 2
else
  output = azs.map do |az_info|
    "AZ #{az_info[:az]}, instance type #{az_info[:instance_type]}, bid #{az_info[:bid]}, current price #{az_info[:current_price]}"
  end.join("; ")
  puts "OK: #{output}"
  exit 0
end
