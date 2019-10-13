# Load balancer configuration
#
# @summary Generate configuration for load balancer
#
# @example
#   include nginx::loadbalancer
class nginx::loadbalancer (
  $lb_dir = $nginx::params::lb_dir,
) inherits nginx::params {
  file { "${nginx::lb_name}.conf":
    content => epp('nginx/lb.conf.epp'),
    ensure  => $nginx::lb_ensure,
    path    => "${lb_dir}/${nginx::lb_name}.conf",
  }
}
