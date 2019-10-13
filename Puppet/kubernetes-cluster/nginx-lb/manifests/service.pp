# @summary configure the nginx service
#
# configure the nginx service
#
# @example
#   include nginx::service
class nginx::service (
  $service_name = $nginx::params::service_name,
) inherits nginx::params {
  service { 'nginx_service':
    name 	=> $service_name,
    ensure 	=> $nginx::service_ensure,
    enable 	=> $nginx::service_enable,
    hasrestart 	=> $nginx::service_hasrestart,
  }
}