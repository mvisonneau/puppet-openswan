# class: strongswan
#
# Provides the installation and configuration of an ipsec over xl2tp VPN server with Puppet
#

class strongswan (
  $external_ip    = undef,
  $external_iface = undef,
  $internal_iface = undef,
  $preshared_key  = undef,
  $vpn_ip_range   = undef,
  $vpn_local_ip   = undef,
  $dns_servers    = [],
) {
  if $::osfamily == 'Debian' {
    case $::os['codename'] {
      /xenial|trusty/: {
        $packages = ['strongswan','xl2tpd','ppp', 'lsof']
      }
      default: {
        fail( 'Unsupported version of Debian/Ubuntu' )
      }
    }

    package { $packages:
      ensure => latest,
    }

    firewall { '200 ipsec snat rules':
      ensure   => present,
      chain    => 'POSTROUTING',
      jump     => 'SNAT',
      table    => 'nat',
      tosource => $external_ip,
      outiface => $external_iface,
    }

    exec { "int accept_redirect setup":
      command => "echo 0 > /proc/sys/net/ipv4/conf/${internal_iface}/accept_redirects",
      onlyif  => "test `cat /proc/sys/net/ipv4/conf/${internal_iface}/accept_redirects` != 0",
    }

    exec { "ext accept_redirect setup":
      command => "echo 0 > /proc/sys/net/ipv4/conf/${external_iface}/accept_redirects",
      onlyif  => "test `cat /proc/sys/net/ipv4/conf/${external_iface}/accept_redirects` != 0",
    }

    file { '/etc/ipsec.conf':
      ensure  => present,
      content => template("${module_name}/ipsec.conf.erb"),
      notify  => Service['ipsec'],
    }

    file { '/etc/ipsec.secrets':
      ensure  => present,
      content => template("${module_name}/ipsec.secrets.erb"),
      notify  => Service['ipsec'],
    }

    file { '/etc/pam.d/ppp':
      ensure  => present,
      source  => "puppet:///modules/${module_name}/ppp",
      notify  => Service['ipsec'],
    }

    file_line { 'l2tpd pap-secrets':
      ensure  => present,
      line    => "*       l2tpd           \"\"              *",
      path    => '/etc/ppp/pap-secrets',
      notify  => Service['ipsec'],
    }

    file { '/etc/xl2tpd/xl2tpd.conf':
      ensure  => present,
      content => template("${module_name}/xl2tpd.conf.erb"),
      notify  => Service['ipsec'],
    }

    file { '/etc/ppp/options.xl2tpd':
      ensure  => present,
      content => template("${module_name}/options.xl2tpd.erb"),
      notify  => Service['ipsec'],
    }

    service { 'ipsec':
      ensure => running,
      enable => true,
    } ->

    service { 'xl2tpd':
      ensure => running,
      enable => true,
      hasrestart => true,
      hasstatus  => false,
    }
  }
  else {
    fail( "Unsupported operating system" )
  }
}
