# == Class: openswan
#
# Provides the installation and configuration of an ipsec over xl2tp VPN server with Puppet
#
# === Examples
#
#  class { 'openswan':
#   $external_ip = "2.2.2.10",
#	$external_iface = eth1,
#	$internal_iface = eth0,
#	$preshared_key = "f54c6f430f0360d1963c8bb8a30f42225a8af58ed",
#	$vpn_ip_range = "10.2.0.30-10.2.0.100",
#	$vpn_local_ip = "10.2.0.1",
#	$dns = ['8.8.8.8','8.8.4.4']
#  }
#
# === Authors
#
# Maxime VISONNEAU <maxime.visonneau@comivi.fr>
#

class openswan (
	$external_ip 		= undef,
	$external_iface 	= undef,
	$internal_iface 	= undef,
	$preshared_key		= undef,
	$vpn_ip_range		= undef,
	$vpn_local_ip		= undef,
	$dns				= []
) {
	$packages = ['openswan','xl2tpd','ppp', 'lsof']
	$redirect_iface_files = ["/proc/sys/net/ipv4/conf/${external_iface}/accept_redirects","/proc/sys/net/ipv4/conf/${internal_iface}/accept_redirects"]

	package { $packages:
		ensure => latest,
	}

	firewall { '200 ipsec snat rules':
		ensure 		=> present,
		chain 		=> 'POSTROUTING',
		jump		=> 'SNAT',
		table		=> 'nat',
		tosource 	=> $external_ip,
		outiface	=> $external_iface,
	}

	exec { "int accept_redirect setup":
		command => "echo 0 > /proc/sys/net/ipv4/conf/${internal_iface}/accept_redirects",
		onlyif => "test `cat /proc/sys/net/ipv4/conf/${internal_iface}/accept_redirects` != 0",
	}

	exec { "ext accept_redirect setup":
		command => "echo 0 > /proc/sys/net/ipv4/conf/${external_iface}/accept_redirects",
		onlyif => "test `cat /proc/sys/net/ipv4/conf/${external_iface}/accept_redirects` != 0",
	}

	file { '/etc/ipsec.conf':
		ensure 	=> present,
		content => template("${module_name}/ipsec.conf.erb"),
		notify	=> Service['ipsec'],
	}

	file { '/etc/ipsec.secrets':
		ensure 	=> present,
		content => template("${module_name}/ipsec.secrets.erb"),
		notify	=> Service['ipsec'],
	}

	file { '/etc/pam.d/ppp':
		ensure 	=> present,
		source  => "puppet:///modules/${module_name}/ppp",
		notify	=> Service['ipsec'],
	}

	file_line { 'l2tpd pap-secrets':
		ensure 	=> present,
		line   	=> "*       l2tpd           \"\"              *",
		path    => '/etc/ppp/pap-secrets',
		notify	=> Service['ipsec'],
	}

	file { '/etc/xl2tpd/xl2tpd.conf':
		ensure 	=> present,
		content => template("${module_name}/xl2tpd.conf.erb"),
		notify	=> Service['ipsec'],
	}

	file { '/etc/ppp/options.xl2tpd':
		ensure 	=> present,
		content => template("${module_name}/options.xl2tpd.erb"),
		notify	=> Service['ipsec'],
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
