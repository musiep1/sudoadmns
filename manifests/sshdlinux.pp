class sshdmn::sshdlinux {
## apply config changes to proc_file (copy of original with ext .puptmp) using augeas provider,
## validate configuration before refreshing sshd service (using validate_cmd file resource param)

  $proc_file = "${sshdmn::params::sshd_config}.puptmp"
  file {  $proc_file:
    ensure => file,
    source => $sshdmn::params::sshd_config,
  }

## PermitRootLogin will serve as a position point relative to which all other lines inserted
## to avoid end of file parameters placement (which may interfere with Match sections of the sshd_config)
## below 2 PermitRootLogin sections (insert and set) must go first
  augeas { "sshd_config_PermitRootLogin_ins":
           incl => "${proc_file}",
           lens => "Sshd.lns",
           context => "/files${proc_file}",
           changes => [
                  "ins PermitRootLogin after *[1]", # insert after 1st line in the file
                  "set PermitRootLogin without-password", # password auth prohibited
           ],
           onlyif => "match PermitRootLogin size == 0";

      "sshd_config_PermitRootLogin_set":
           incl => "${proc_file}",
           lens => "Sshd.lns",
           context => "/files${proc_file}",
           changes => [
                  "set PermitRootLogin without-password", # password auth prohibited
           ];

      "sshd_config_Protocol_ins":
           incl => "${proc_file}",
           lens => "Sshd.lns",
           context => "/files${proc_file}",
           changes => [
                  "ins Protocol after PermitRootLogin",
                  "set Protocol 2", # enforce Protocol
           ],
           onlyif => "match Protocol size == 0";

      "sshd_config_Protocol_set":
           incl => "${proc_file}",
           lens => "Sshd.lns",
           context => "/files${proc_file}",
           changes => [
                  "set Protocol 2", # enforce Protocol
           ];
  }

### MACs parameters - different for Red Hat 5 and 6 versus 7
### (Message Authentication Code for data integrity protection)
  if versioncmp($::operatingsystemmajrelease, '7') < 0 {

      augeas { "sshd_config_MACs_ins":
           incl => "${proc_file}",
           lens => "Sshd.lns",
           context => "/files${proc_file}",
           changes => [
                     "ins MACs after PermitRootLogin",
                     "set MACs/1 hmac-sha1",
                     "set MACs/2 hmac-ripemd160",
           ],
           onlyif => "match MACs size == 0";

      "sshd_config_MACs_set":
           incl => "${proc_file}",
           lens => "Sshd.lns",
           context => "/files${proc_file}",
           changes => [
                     "rm MACs/*",
                     "set MACs/1 hmac-sha1",
                     "set MACs/2 hmac-ripemd160",
           ];
      }

  } else {
      augeas { "sshd_config_MACs_ins":
           incl => "${proc_file}",
           lens => "Sshd.lns",
           context => "/files${proc_file}",
           changes => [
                     "ins MACs after PermitRootLogin",
                     "set MACs/1 hmac-sha1",
                     "set MACs/2 hmac-sha2-256",
                     "set MACs/3 hmac-sha2-512",
                     "set MACs/4 hmac-ripemd160",
                     "set MACs/5 hmac-sha1-etm@openssh.com",
                     "set MACs/6 hmac-sha2-256-etm@openssh.com",
                     "set MACs/7 hmac-sha2-512-etm@openssh.com",
           ],
           onlyif => "match MACs size == 0";

      "sshd_config_MACs_set":
           incl => "${proc_file}",
           lens => "Sshd.lns",
           context => "/files${proc_file}",
           changes => [
                     "rm MACs/*",
                     "set MACs/1 hmac-sha1",
                     "set MACs/2 hmac-sha2-256",
                     "set MACs/3 hmac-sha2-512",
                     "set MACs/4 hmac-ripemd160",
                     "set MACs/5 hmac-sha1-etm@openssh.com",
                     "set MACs/6 hmac-sha2-256-etm@openssh.com",
                     "set MACs/7 hmac-sha2-512-etm@openssh.com",
           ];
      }
  }

#### Ciphers parameter enforcemnt - for all Linux flavors
  augeas { "sshd_config_Ciphers_ins":
        incl => "${proc_file}",
        lens => "Sshd.lns",
        context => "/files${proc_file}",
        changes => [
                   "ins Ciphers after PermitRootLogin",
                   "set Ciphers/1 aes128-ctr",
                   "set Ciphers/2 aes192-ctr",
                   "set Ciphers/3 aes256-ctr",
        ],
        onlyif => "match Ciphers size == 0";

  "sshd_config_Ciphers_set":
        incl => "${proc_file}",
        lens => "Sshd.lns",
        context => "/files${proc_file}",
        changes => [
                   "rm Ciphers/*",
                   "set Ciphers/1 aes128-ctr",
                   "set Ciphers/2 aes192-ctr",
                   "set Ciphers/3 aes256-ctr",
        ];
  }

  ### exec FYI only as an alternative ###
  ## exec { 'validate_ssh':
  ##  path => ['/usr/sbin', '/usr/bin', '/sbin'],
  ##  command      => "sshd -tf ${proc_file}",
  ##  require     => File[$proc_file],
  ##  refreshonly => true,
  ## }

### Validate configuration before replacing sshd_config file
  file { $sshdmn::params::sshd_config:
    ensure  => file,
    source  => $proc_file,
    mode => '600',
    owner => 'root',
    validate_cmd => "${sshdmn::params::sshd_exe} -tf %", # failure will report to the GUI console
    ##require => Exec['validate_ssh'], # FYI: alternative
    notify  => Service[$sshdmn::params::service_name],
  }

### sshd service running
  service { $sshdmn::params::service_name:
    ensure => running,
    enable => true,
    hasstatus => true,
    hasrestart => true,
    subscribe =>  File[$sshdmn::params::sshd_config],
  }

### software package installed
  package { $sshdmn::params::server_package_name:
    ensure => present,
    before => File[$sshdmn::params::sshd_config],
  }

} # end class sshdmn::sshdlinux
