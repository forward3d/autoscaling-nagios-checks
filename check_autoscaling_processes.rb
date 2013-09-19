#!/usr/bin/env ruby

require 'aws-sdk'
require 'optparse'
require 'ostruct'
require 'pp'

options = OpenStruct.new
OptionParser.new do |opts|
  opts.banner = "Usage: check_autoscaling_processes.rb [options]"

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

if as_group.suspended_processes.empty?
  puts "OK: no processes suspended"
  exit 0
else
  puts "WARNING: suspended processes - #{as_group.suspended_processes.keys.join(", ")}"
  exit 1
end
