class wp::cli (
	$ensure = 'installed',
	$install_path = '/usr/local/src/wp-cli',
	$version = 'dev-master',
	$phpprefix = $::operatingsystem ? {
		'RedHat'		=> 'php',
		'CentOS'		=> 'php',
		'Debian'  	=> 'php5',
		'Ubuntu'    => $::operatingsystemmajrelease ?  { '18.04' => 'php7.3', '16.04' => 'php7.3', default => php }, 
		default			=> 'php',
	}
) {
	include wp

	if 'installed' == $ensure or 'present' == $ensure {
		# Create the install path
		file { [ "$install_path", "$install_path/bin" ]:
			ensure => directory,
		}

		# Clone the Git repo
		exec{ 'wp-cli download':
			command => "/usr/bin/curl -o $install_path/bin/wp -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar",
			require => [ Package[ 'curl' ], File[ $install_path ] ],
			creates => "$install_path/bin/wp"
		}

		# Ensure we can run wp-cli
		file { "$install_path/bin/wp":
			ensure => "present",
			mode => "a+x",
			require => Exec[ 'wp-cli download' ]
		}

		# Symlink it across
		file { '/usr/bin/wp':
			ensure => link,
			target => "$install_path/bin/wp",
			require => File[ "$install_path/bin/wp" ],
		}
	}
	elsif 'absent' == $ensure {
		file { "/usr/bin/wp":
			ensure => absent,
		}
		file { "/usr/local/src/wp-cli":
			ensure => absent,
		}
	}

	if ! defined(Package["${phpprefix}-cli"]) {
		package { "${phpprefix}-cli":
			ensure => installed,
			tag    => 'php',
		}
	}

	if ! defined(Package['curl']) {
		package { 'curl':
			ensure => installed,
		}
	}

	if ! defined(Package['git']) {
		package { 'git':
			ensure => installed,
		}
	}
}
