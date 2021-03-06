#
# There are a number of order-dependant blocs:
#
# - [authgroup:name] must be defined before blocks [mapping], [arex/ws/jobs] and [gridftp/jobs]
# - rules indide the [mapping] block are order dependant
# - same for legacy [userlist:name] blocks
# - arex/ws/jobs block contains allow/deny rules that are order dependant
#
class arc6::config(
  $blah_ceid_default = $arc6::lrms
) {

  #define the "blah" ceid prefix, if used : this is important for apel accounting, to find queue specints
  # No idea what this should be for other batch systems than condor.
  # No idea what should be set when gridftp AND/OR webservice can be used
  $ce_id = $arc6::lrms ? {
    'condor' => "${::fqdn}:2811/nordugrid-Condor",
    default => $blah_ceid_default
  }

  if $arc6::firewall_manage {
    include ::arc6::firewall
  }

  #create directories
  # make sure that args are not undef
  [ $arc6::arc_basepath, $arc6::controldir, $arc6::sessiondir , $arc6::apel_accounting_dir ].filter | $d | {
    $d and $d != []
  }.each | $dir | {
     file { $dir : ensure => directory }
  }


  concat { '/etc/arc.conf':
    notify => Class['arc6::services'],
  }


  concat::fragment { 'arc.conf_common':
    target  => '/etc/arc.conf',
    content => template("${module_name}/common.erb"),
    order   => '001',
  }

  concat::fragment { 'arc.conf_queues':
    target  => '/etc/arc.conf',
    content => template("${module_name}/queues.erb"),
    order   => '010',
  }

  file { '/etc/lcmaps/lcmaps.db':
    ensure  => 'present',
    content => template("${module_name}/lcmaps.db.erb"),
    require => Package['lcmaps'],
  }

  file { '/etc/lcas/ban_users.db':
    ensure => 'present',
  }

  file { '/etc/lcas/lcas.db':
    ensure => 'present',
    content => @(EOF)
      pluginname=/usr/lib64/lcas/lcas_userban.mod,pluginargs=/etc/lcas/ban_users.db
      pluginname=/usr/lib64/lcas/lcas_voms.mod,pluginargs="-vomsdir /etc/grid-security/vomsdir -certdir /etc/grid-security/certificates -authfile /etc/grid-security/grid-mapfile -authformat simple -use_user_dn"
      | EOF
    ,
    require => Package['lcas'],
  }

  if($arc6::apel_accounting) {
    include ::arc6::apel
  }

}
