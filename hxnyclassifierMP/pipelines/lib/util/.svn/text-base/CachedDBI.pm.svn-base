package util::CachedDBI;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Carp qw(confess cluck);
use DBI;
use POSIX;

use util::DbConfig;
use util::Constants;

use vars qw(
  @ISA
  @EXPORT
);

################################################################################
#
#				Initializations
#
################################################################################

BEGIN {
  use Exporter();
  @ISA = qw(Exporter);

  @EXPORT = ( '&GetDBIHandle', '&GetDBIHandleByParams', '&RemoveDBIHandle' );
}

################################################################################
#
#		     Static Class Private Global Variables
#
################################################################################
###
### Database connection hash
###
### All connection handles are maintained in this hash
### where the key is the catenation of the Database
### and Username fields from the database configuration file.
###
my %_CACHED_CONNECTIONS_;
my %_UNCACHED_CONNECTIONS_;
###
### This variable defines the hosts on which the MySQL host value is
### 'localhost'.  If the hostname of the host is not one of these
### values, then it is set to the Linux host.
###
my $_MYSQL_HOST = {
  linux1  => 'tsmith.immport.net',
  linux2  => 'tomdv8',
  windows => '',
};

################################################################################
#
#				 Static Methods
#
################################################################################

sub GetDBIHandleByParams($$$$;$) {
  my ( $server, $database, $username, $password, $new_instance ) = @_;
  ###
  ### Build the catenated string for the hash key
  ###
  my $hash_key = join( util::Constants::COLON, $database, $username );
  ###
  ### Find the database handle object if one exists already.
  ### Otherwise, create a new database handle object and
  ### enter it into the hash.
  ###
  my $dbh = $_CACHED_CONNECTIONS_{$hash_key};
  ###
  ### Return chached connection immediately if there is a connection and a new
  ### instance has not been requested
  ###
  $new_instance =
    ( defined($new_instance) && $new_instance )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  return $dbh if ( $dbh && !$new_instance );
  ###
  ### Really die if server not OraceleDB or mySQL
  ###
  if ( $server ne 'OracleDB'
    && $server ne 'mySQL' )
  {
    cluck "ERROR:  Server ($server) is neither OracleDB or mySQL\n";
    POSIX::_exit(2);
  }
  ###
  ### Now Attempt Connection - If Connection Fails immediately propagate the exception
  ###
  $dbh = undef;
  if ( $server eq 'OracleDB' ) {

    $dbh = DBI->connect(
      "dbi:Oracle:$database",
      $username,
      $password,
      {
        RaiseError => util::Constants::TRUE,
        AutoCommit => util::Constants::TRUE,
      }
    );
  }
  elsif ( $server eq 'mySQL' ) {
    ###
    ### First set the host for mysql
    ###
    my $hostname = `hostname`;
    chomp($hostname);
    my $host = undef;
    if ( $hostname eq $_MYSQL_HOST->{linux1}
      || $hostname eq $_MYSQL_HOST->{linux2}
      || $hostname eq $_MYSQL_HOST->{windows} )
    {
      $host = 'localhost';
    }
    else {
      $host = $_MYSQL_HOST->{linux};
    }
    $dbh = DBI->connect(
      "dbi:mysql:database=$database;host=$host",
      $username,
      $password,
      {
        RaiseError => util::Constants::TRUE,
        AutoCommit => util::Constants::TRUE,
      }
    );
  }
  ###
  ### Set newly created connection and return
  ###
  if ($new_instance) {
    if ( !defined( $_UNCACHED_CONNECTIONS_{$hash_key} ) ) {
      $_UNCACHED_CONNECTIONS_{$hash_key} = [];
    }
    push( @{ $_UNCACHED_CONNECTIONS_{$hash_key} }, $dbh );
  }
  else {
    if ( !defined( $_CACHED_CONNECTIONS_{$hash_key} ) ) {
      $_CACHED_CONNECTIONS_{$hash_key} = $dbh;
    }
  }
  return $dbh;
}
sub GetDBIHandle($;$) {
  my ( $db_config_file, $new_instance ) = @_;
  ###
  ### Read the configuration file to extract the parameters
  ###
  my ( $server, $database, $username, $password ) =
    read_db_config_file($db_config_file);
  ###
  ### Now call params static method
  ###
  return GetDBIHandleByParams( $server, $database, $username, $password,
    $new_instance );
}

sub RemoveDBIHandle($) {
  my ($dbh) = @_;
  ###
  ### Locate the handle object in the values of the hash
  ###
  my $deleted_handle = util::Constants::FALSE;
  while ( my ( $hash_key, $dbh_array ) = each %_UNCACHED_CONNECTIONS_ ) {
    my $tmp_dbh_array = [];
    foreach my $obj ( @{$dbh_array} ) {
      if ( !$deleted_handle && $dbh == $obj ) {
        ###
        ### By default, with autocommit on (1),
        ### all mods will be commited.
        ### Otherwise, with autocommit off (0),
        ### all mods will be rolled back that have
        ### not already been commited.
        ###
        if ( !$dbh->{AutoCommit} ) { $dbh->rollback; }
        $dbh->disconnect;
        $deleted_handle = util::Constants::TRUE;
      }
      else {
        push( @{$tmp_dbh_array}, $obj );
      }
    }
    if ( @{$tmp_dbh_array} == 0 ) {
      delete( $_UNCACHED_CONNECTIONS_{$hash_key} );
    }
    else {
      $_UNCACHED_CONNECTIONS_{$hash_key} = $tmp_dbh_array;
    }
  }
  ###
  ### If we get here and the handle was not found, then
  ### raise a warning by cluck (do not die in error)!
  ###
  cluck "WARNING:  Database handle is no longer\n"
    . "WARNING:  in CachedDBI collection\n"
    . "WARNING:    method = RemoveDBIHandle\n"
    . "WARNING:    dbh    = $dbh\n"
    if ( !$deleted_handle );
}

################################################################################
#
#				 Finalizations
#
################################################################################
###
### This is called when this module is unloaded at the end of execution.
### Disconnects all open connections remaining.
###
END {
  while ( my ( $hash_key, $dbh ) = each %_CACHED_CONNECTIONS_ ) {
    $dbh->disconnect;
  }
  while ( my ( $hash_key, $dbh_array ) = each %_UNCACHED_CONNECTIONS_ ) {
    foreach my $dbh ( @{$dbh_array} ) {
      $dbh->disconnect;
    }
  }
}

################################################################################

1;

__END__

=head1 NAME

CachedDBI.pm

=head1 SYNOPSIS

   use util::CachedDBI;

   $dbh = GetDBIHandle($db_config_file);
   . . .
   $dbh2 = GetDBIHandle($db_config_file);

   $dbh3 = GetDBIHandleByParams($server, $database, $username, $password);

   RemoveDBIHandle($dbh);

=head1 DESCRIPTION

The B<util::CachedDBI> module follows a factory design pattern with
object caching.  The class has two modes for creating a new DBI handle
object: cached and uncached.  In the uncached mode the class creates a new handle,
returns it, and stores it for disconnection processing.  In the cached mode, a cache is
checked for any existing DBI handle object to the same database using
the same account (database and username).  If a handle exists in the cache it is returned,
otherwise a new handle for the account is created, cached, and returned. The cache can
be left as is upon program termination, at which time the B<util::CachedDBI> module
will disconnect both cached and uncached database connections.  Thus, it is not
necessary for a program to ensure that all DBI handles are
disconnected.
