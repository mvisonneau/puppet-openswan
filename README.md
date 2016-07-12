# puppet-strongswan

Provides the installation and configuration of an ipsec over xl2tp VPN server with Puppet

## Usage

class { 'strongswan':
  $external_ip = "2.2.2.10",
  $external_iface = eth1,
  $internal_iface = eth0,
  $preshared_key = "f54c6f430f0360d1963c8bb8a30f42225a8af58ed",
  $vpn_ip_range = "10.2.0.30-10.2.0.100",
  $vpn_local_ip = "10.2.0.1",
  $dns_servers = ['8.8.8.8','8.8.4.4']
}

## TODO

- Complete configuration abstraction
- Unit testing
- Implement blacksmith/Publish module on forge
- Improve versioning
- Enhance compatibility with other OSes
