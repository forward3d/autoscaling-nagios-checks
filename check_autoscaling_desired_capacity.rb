#!/usr/bin/env ruby

require 'aws-sdk'
require 'optparse'
require 'ostruct'
require 'pp'

options = OpenStruct.new
OptionParser.new do |opts|
  opts.banner = "Usage: check_autoscaling_desired_capacity.rb [options]"

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

# Look at desired capacity, and the number of instances launched;
# if they're mismatched, then we're not scaling because the spot price
# is too high, or we're scaling down, or scaling up.

instances_launched = as_group.auto_scaling_instances.length
desired_capacity   = as_group.desired_capacity
if instances_launched != desired_capacity
  puts "CRITICAL: desired capacity for #{options.autoscaling_group} is #{desired_capacity}, but #{instances_launched} instances running"
  exit 2
else
  puts "OK: desired capacity for #{options.autoscaling_group} is #{desired_capacity}, #{instances_launched} instances running"
  exit 0
end
