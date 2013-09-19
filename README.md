# Autoscaling Nagios checks

These plugins are used at Forward3D for monitoring autoscaling with spots.

## check_aws_spot_price.rb

This plugin will, given an autoscaling group name, check to see if the current spot price
for the AS group's instance type, region, and AZ(s) is lower than the bid price in the group's
configuration. It's designed to look for the situation where the price of the instance(s) you're
using suddenly rises and your spots terminate. It can handle EC2 and VPC regions/AZs.

## check_autoscaling_desired_capacity.rb

This plugin checks to see if the given autoscaling group has as many running instances
as the desired capacity.

## check_autoscaling_process.rb

This plugin checks to see if the given autoscaling group has all autoscaling processes
enabled, and returns WARNING and a list of the disabled processes if any are disabled.

## Usage

All the plugins take the same arguments. Using `check_aws_spot_price.rb` as an example:

    Usage: check_aws_spot_price.rb [options]
        -a, --access_key access_key      AWS access key
        -s, --secret_key secret_key      AWS secret key
        -g autoscaling_group,            Autoscaling group to inspect
            --autoscaling_group
        -r, --region region              Region to look at

The arguments are self-explanatory.

## Required IAM permissions

If you want to create a restricted IAM user to run this plugin (which is a good idea), then
you need the following IAM permissions:

- ec2:DescribeSpotPriceHistory
- autoscaling:DescribeAutoScalingGroups
- autoscaling:DescribeAutoScalingInstances
- autoscaling:DescribeLaunchConfigurations
- autoscaling:DescribeScheduledActions

The following two policy statements should do this. This one allows the user to
look at the autoscaling configuration:

    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeAutoScalingInstances",
            "autoscaling:DescribeLaunchConfigurations",
            "autoscaling:DescribeScheduledActions"
          ],
          "Sid": "Stmt1379497414000",
          "Resource": [
            "*"
          ],
          "Effect": "Allow"
        }
      ]
    }

And this one allows it to view the spot price history:

    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "ec2:DescribeSpotPriceHistory"
          ],
          "Sid": "Stmt1379439419000",
          "Resource": [
            "*"
          ],
          "Effect": "Allow"
        }
      ]
    }

## Contributing

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request
