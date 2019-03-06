package util::Db;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use DBI;
use Pod::Usage;

use util::CachedDBI;
use util::Constants;
use util::DbConfig;
use util::PathSpecifics;

use fields qw(
  commit
  db_config
  die_on_error
  error_mgr
  name
  password
  print_info
  schema_owner
  server
  session
  transaction_id
  update_ts
  user
);
################################################################################
#
#			  Static Class Global Variable
#
################################################################################

my $_RETRY_ATTEMPTS_ = 0;

################################################################################
#
#			Setter and Getter Static Methods
#
################################################################################

sub setRetries {
  my ($attempts) = @_;
  return if $attempts !~ /^\d$/;
  $_RETRY_ATTEMPTS_ = $attempts;
}

sub unsetRetries {
  $_RETRY_ATTEMPTS_ = 0;
}

sub getRetries {
  return $_RETRY_ATTEMPTS_;
}

################################################################################
#
#			       Private Constants
#
################################################################################

sub DEFAULT_TRACE_LEVEL { return 2 }

sub RETRY_INTERVAL { return 5 * 60; }
###
### Standard LOB Length
###
sub LOB_LENGTH { return 2000000000; }
###
### Infinite Time
###
sub INFINITE_TIME { return 99999999999; }
###
### Schema Owner
###
sub SCHEMA_OWNER { return 'SchemaOwner'; }

################################################################################
#
#			     Private Static Methods
#
################################################################################

sub _getDbHandle($) {
  my util::Db $this = shift;
  my $dbh = undef;
  eval {
    $dbh =
      GetDBIHandleByParams( $this->{server}, $this->{name}, $this->{user},
      $this->{password}, util::Constants::TRUE );
  };
  my $status = $@;
  if ( defined($status) && $status ) {
    ###
    ### An error has occurred
    ###
    $dbh = undef;
  }
  elsif ( !defined($dbh) ) {
    ###
    ### An error but not status information
    ###
    $status = 'DB Connection Error (no status)';
  }
  else {
    ###
    ### Status is either undefined or FALSE
    ### and database connection is defined
    ###
    $status = undef;
  }
  $this->{error_mgr}->printError(
    "Connection Failure (retry will occur)\n"
      . "  db_config = "
      . $this->{db_config} . "\n"
      . "  server    = "
      . $this->{server} . "\n"
      . "  name      = "
      . $this->{name} . "\n"
      . "  user      = "
      . $this->{user} . "\n"
      . "  password  = "
      . $this->{password} . "\n"
      . "  date      = " . `date`
      . "  errMsg    = "
      . ( defined($status) ? $status : '' ),
    defined($status)
  );
  return $dbh;
}

sub _openSession($) {
  my util::Db $this = shift;
  ###
  ### Initial connection attempt, return immediately
  ### if successful
  ###
  my $dbh = $this->_getDbHandle;
  return $dbh if ( defined($dbh) );
  ###
  ### Retry Connection
  ###
  my $local_retry_attempts = $_RETRY_ATTEMPTS_;
  while ( $local_retry_attempts > 0 ) {
    sleep(RETRY_INTERVAL);
    $local_retry_attempts--;
    $dbh = $this->_getDbHandle;
    return $dbh if ( defined($dbh) );
  }
  ###
  ### No handle die!
  ###
  $this->{error_mgr}->dieOnError(
    "Cannot Acquire database handle for the sesssion, terminating...\n"
      . "  db_config = "
      . $this->{db_config} . "\n"
      . "  server    = "
      . $this->{server} . "\n"
      . "  name      = "
      . $this->{name} . "\n"
      . "  user      = "
      . $this->{user} . "\n"
      . "  password  = "
      . $this->{password} . "\n"
      . "  date      = " . `date`,
    util::Constants::TRUE
  );
}

sub _closeSession($$) {
  my util::Db $this = shift;
  my ($dbh) = @_;
  eval { RemoveDBIHandle($dbh); };
  my $status = $@;
  return $status;
}

sub _checkSession($) {
  my util::Db $this = shift;
  $this->{error_mgr}
    ->dieOnError( "Database handle no longer exists, terminating...",
    !$this->sessionOpen );
}

sub _printQueryError($$) {
  my util::Db $this = shift;
  my ($msg) = @_;
  if ( $this->dieOnError ) {
    $this->{error_mgr}->dieOnError( $msg, util::Constants::TRUE );
  }
  else {
    $this->{error_mgr}->printError( $msg, util::Constants::TRUE );
  }
}

sub _processQueryError($$) {
  my util::Db $this = shift;
  my ($msg) = @_;
  if ( $this->transactionOpen ) {
    $this->{error_mgr}->printError( $msg, util::Constants::TRUE );
    $this->rollbackAndClose;
  }
  $this->_printQueryError($msg);
}

sub _autoCommit($$) {
  my util::Db $this = shift;
  my ($tValue) = @_;
  $this->_checkSession;
  $this->{session}->{AutoCommit} = $tValue;
}

################################################################################
#
#				  Constructors
#
################################################################################

sub new ($$$$$$$) {
  my util::Db $this = shift;
  my (
    $server_type, $database_name, $user_name,
    $password,    $schema_owner,  $error_mgr
  ) = @_;
  $this = fields::new($this) unless ref($this);
  $this->{commit}         = undef;
  $this->{db_config}      = undef;
  $this->{die_on_error}   = util::Constants::FALSE;
  $this->{error_mgr}      = $error_mgr;
  $this->{name}           = $database_name;
  $this->{password}       = $password;
  $this->{print_info}     = util::Constants::TRUE;
  $this->{schema_owner}   = uc($schema_owner);
  $this->{server}         = $server_type;
  $this->{transaction_id} = undef;
  $this->{update_ts}      = undef;
  $this->{user}           = $user_name;

  $this->{error_mgr}->printWarning(
    "Schema Owner not defined...",
    !defined( $this->{schema_owner} )
      || $this->{schema_owner} eq util::Constants::EMPTY_STR
  ) if ( $this->{print_info} );
  ###
  ### Open session and set attributes
  ###
  $this->{session}                = $this->_openSession;
  $this->{session}->{LongTruncOk} = util::Constants::FALSE;
  $this->{session}->{PrintError}  = util::Constants::FALSE;
  $this->{session}->{RaiseError}  = util::Constants::TRUE;
  $this->setAutoCommit;

  return $this;
}

sub newByFile($$$) {
  my util::Db $this = shift;
  my ( $db_config, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);
  $this->{commit}         = undef;
  $this->{db_config}      = getPath($db_config);
  $this->{die_on_error}   = util::Constants::FALSE;
  $this->{error_mgr}      = $error_mgr;
  $this->{print_info}     = util::Constants::TRUE;
  $this->{transaction_id} = undef;
  $this->{update_ts}      = undef;
  ###
  ### Check Db Config
  ###
  $this->{error_mgr}->dieOnError(
    "DB Config Inaccessible, terminating...\n"
      . "  db_config = "
      . $this->{db_config},
    !-e $this->{db_config} || !-f $this->{db_config} || !-r $this->{db_config}
  );
  ###
  ### Get configuration parameters
  ###
  my $database_params = undef;
  (
    $this->{server},   $this->{name}, $this->{user},
    $this->{password}, $database_params
  ) = read_db_config_file( $this->{db_config} );
  ###
  ### Schema Owner
  ### Issue a warning if not available.
  ###
  $this->{schema_owner} = undef;
  if ( defined($database_params)
    && defined( $database_params->{&SCHEMA_OWNER} ) )
  {
    $this->{schema_owner} = uc( $database_params->{&SCHEMA_OWNER} );
  }
  else {
    $this->{error_mgr}->printWarning(
      "Cannot find schema owner tag in DB Config File\n"
        . "  schema owner   = "
        . &SCHEMA_OWNER . "\n"
        . "  db_config_file = "
        . $this->{db_config},
      util::Constants::TRUE
    ) if ( $this->{print_info} );
  }
  ###
  ### Open session and set attributes
  ###
  $this->{session}                = $this->_openSession;
  $this->{session}->{LongTruncOk} = util::Constants::FALSE;
  $this->{session}->{PrintError}  = util::Constants::FALSE;
  $this->{session}->{RaiseError}  = util::Constants::TRUE;
  $this->setAutoCommit;

  return $this;
}

################################################################################
#
#			       Session Management
#
################################################################################

sub closeSession {
  my util::Db $this = shift;
  $this->_checkSession;
  my $status = $this->_closeSession( $this->{session} );
  $this->{commit}         = undef;
  $this->{session}        = undef;
  $this->{transaction_id} = undef;
  $this->{update_ts}      = undef;
  return if ( !defined($status) || !$status );
  $this->setDieOnError;
  $this->_printQueryError(
    "Error Occurred Disconnecting from the Database\n" . "  errMsg = $status" );
}

sub rollback($) {
  my util::Db $this = shift;
  $this->_checkSession;
  return util::Constants::FALSE if ( $this->{session}->{AutoCommit} );
  eval { $this->{session}->rollback; };
  my $status = $@;
  if ( ( defined($status) && $status )
    || $this->{session}->err )
  {
    $status = util::Constants::TRUE;
    my $errstr =
      ( defined( $this->{session} ) && defined( $this->{session}->errstr ) )
      ? $this->{session}->errstr
      : 'undefined error';
    my $error = ( defined($status) ) ? $status : 'undefined error';
    $this->_printQueryError( "rollBackQuery Error\n"
        . "   errstr = $errstr\n"
        . "   error  = $error" );
  }
  else {
    $status = util::Constants::FALSE;
  }
  return $status;
}

sub rollbackAndClose {
  my util::Db $this = shift;
  $this->{error_mgr}
    ->printHeader('Rolling Back Updates Before Closing Session ...')
    if ( $this->{print_info} );
  return if ( !$this->sessionOpen );
  $this->setDieOnError;
  $this->rollback;
  $this->closeSession;
}

################################################################################
#
#			     Transactional Methods
#
################################################################################

sub startTransaction($;@) {
  my util::Db $this = shift;
  my (@params) = @_;
  $this->_checkSession;
  return if ( $this->transactionOpen );
  $this->resetAutoCommit;
  my $die_on_error = $this->dieOnError;
  if ( !$die_on_error ) { $this->setDieOnError; }
  my $sth = $this->prepareQuery( 'commit', 'Cannot Prepare Commit' );
  if ( !$die_on_error ) { $this->resetDieOnError; }
  $this->{commit} = {
    sth      => $sth,
    count    => 0,
    commited => 0,
  };
  $this->{transaction_id} = 1;
  $this->{update_ts}      = time;
}

sub executeUpdate($$;$@) {
  my util::Db $this = shift;
  my ( $sth, $msg, @query_array ) = @_;
  return util::Constants::TRUE if ( !$this->transactionOpen );
  $this->{commit}->{count}++;
  my $die_on_error = $this->dieOnError;
  if ( !$die_on_error ) { $this->setDieOnError; }
  my $status = $this->executeQuery( $sth, $msg, @query_array );
  if ( !$die_on_error ) { $this->resetDieOnError; }
  return $status;
}

sub doUpdate($$;$@) {
  my util::Db $this = shift;
  my ( $cmd, $msg, @query_array ) = @_;
  my $sth = $this->prepareQuery( $cmd, $msg );
  return $sth if ( !defined($sth) );
  $this->executeUpdate( $sth, $msg, @query_array );
  return $sth;
}

sub commitTransaction($) {
  my util::Db $this = shift;
  $this->_checkSession;
  return util::Constants::FALSE
    if ( !$this->transactionOpen
    || $this->{commit}->{count} <= $this->{commit}->{commited} );
  my $commit_str = undef;
  my $status = $this->executeQuery( $this->{commit}->{sth}, 'Commit Failed' );
  if ($status) {
    $commit_str = 'Commit Error';
  }
  else {
    my $commited = $this->{commit}->{count} - $this->{commit}->{commited};
    $this->{commit}->{commited} = $this->{commit}->{count};
    $commit_str = "Commited $commited";
  }
  my $msg =
      $commit_str . "\n"
    . 'count    = '
    . $this->{commit}->{count} . "\n"
    . 'commited = '
    . $this->{commit}->{commited} . "\n";
  if ($status) {
    $this->{error_mgr}->printError( $msg, util::Constants::TRUE );
  }
  elsif ( $this->{print_info} ) { $this->{error_mgr}->printMsg($msg); }
  return $status;
}

sub exitProgram($$$) {
  my util::Db $this = shift;
  my ( $msg, $error ) = @_;
  return if ( !defined($error) || !$error );
  if ( $this->sessionOpen && $this->transactionOpen ) {
    $this->{error_mgr}->printError(
      "Rollback Updates In Terminating Process\n"
        . "  transaction_id = "
        . $this->getTransactionId,
      util::Constants::TRUE
    );
    $this->{error_mgr}->printError(
      "Rollback Database Transaction Failed to Occur\n"
        . "  transaction_id = "
        . $this->getTransactionId,
      $this->rollbackAndClose
    );
  }
  $this->{error_mgr}->dieOnError( $msg, $error );
}

sub finalizeTransaction($$) {
  my util::Db $this = shift;
  my ($header)      = @_;
  my $msg           = "$header(" . $this->getCommitCount . '):  ';
  if ( $this->{error_mgr}->isDebugging ) {
    $this->rollback;
    $msg .= 'Debugging Mode Rollback Updates';
  }
  else {
    $this->commitTransaction;
    $msg .= 'Updates Commited to Database(' . $this->getCommitedCount . ')';
  }
  $this->{error_mgr}->printHeader($msg) if ( $this->{print_info} );
  $this->closeSession;
}

################################################################################
#
#				 Setter Methods
#
################################################################################

sub setAutoCommit {
  my util::Db $this = shift;
  $this->_autoCommit(util::Constants::TRUE);
}

sub resetAutoCommit {
  my util::Db $this = shift;
  $this->_autoCommit(util::Constants::FALSE);
}

sub setDebugTrace($;$$) {
  my util::Db $this = shift;
  my ( $trace_level, $trace_file ) = @_;
  if ( !defined($trace_level) ) { $trace_level = DEFAULT_TRACE_LEVEL; }
  if ( !defined($trace_file) ) {
    DBI->trace($trace_level);
  }
  else {
    $trace_file = getPath($trace_file);
    unlink($trace_file);
    DBI->trace( $trace_level, $trace_file );
  }
}

sub unsetDebugTrace($) {
  my util::Db $this = shift;
  DBI->trace(0);
}

sub setDieOnError {
  my util::Db $this = shift;
  $this->{die_on_error} = util::Constants::TRUE;
}

sub resetDieOnError {
  my util::Db $this = shift;
  $this->{die_on_error} = util::Constants::FALSE;
}

sub setLongReadLen($$) {
  my util::Db $this = shift;
  my ($length) = @_;
  $this->_checkSession;
  return if ( !defined($length) || int($length) <= 0 );
  $this->{session}->{LongReadLen} = int($length);
}

sub setPrintInfo {
  my util::Db $this = shift;
  $this->{print_info} = util::Constants::TRUE;
}

sub unsetPrintInfo {
  my util::Db $this = shift;
  $this->{print_info} = util::Constants::FALSE;
}

################################################################################
#
#				 Getter Methods
#
################################################################################

sub getDbConfig {
  my util::Db $this = shift;
  return $this->{db_config};
}

sub getName {
  my util::Db $this = shift;
  return $this->{name};
}

sub getSchemaOwner {
  my util::Db $this = shift;
  return $this->{schema_owner};
}

sub getServer {
  my util::Db $this = shift;
  return $this->{server};
}

sub getSession {
  my util::Db $this = shift;
  $this->_checkSession;
  return $this->{session};
}

sub dieOnError {
  my util::Db $this = shift;
  return $this->{die_on_error};
}

sub sessionOpen {
  my util::Db $this = shift;
  return (
    defined( $this->{session} )
    ? util::Constants::TRUE
    : util::Constants::FALSE
  );
}

sub getUser {
  my util::Db $this = shift;
  return $this->{user};
}

sub transactionOpen {
  my util::Db $this = shift;
  return (
    defined( $this->{transaction_id} )
    ? util::Constants::TRUE
    : util::Constants::FALSE
  );
}

sub getTransactionId {
  my util::Db $this = shift;
  return $this->{transaction_id};
}

sub getUpdateTs {
  my util::Db $this = shift;
  return $this->{update_ts};
}

sub getCommitCount {
  my util::Db $this = shift;
  return undef if ( !$this->transactionOpen );
  return $this->{commit}->{count};
}

sub getCommitedCount {
  my util::Db $this = shift;
  return undef if ( !$this->transactionOpen );
  return $this->{commit}->{commited};
}

################################################################################
#
#				 Query Methods
#
################################################################################

sub quote ($) {
  my util::Db $this = shift;
  my ($string)      = @_;
  my $quoted_string = $this->{session}->quote($string);
  return $quoted_string;
}

sub prepareQuery($$;$) {
  my util::Db $this = shift;
  my ( $cmd, $msg ) = @_;
  my $sth = undef;
  $this->{error_mgr}->printDebug("Preparing command cmd =\n$cmd\n")
    if ( $this->{print_info} );
  eval { $sth = $this->{session}->prepare($cmd); };
  my $status = $@;
  if ( ( defined($status) && $status )
    || $this->{session}->errstr )
  {
    $sth = undef;
    $msg =
      ( !defined($msg) || $msg eq util::Constants::EMPTY_STR )
      ? 'prepare query'
      : $msg;
    my $errstr =
      ( defined( $this->{session} ) && defined( $this->{session}->errstr ) )
      ? $this->{session}->errstr
      : 'undefined error';
    my $error = ( defined($status) ) ? $status : 'undefined error';
    $this->_processQueryError( "prepareQuery Error\n"
        . "  msg    = $msg\n"
        . "  errstr = $errstr\n"
        . "  error  = $error\n"
        . "  cmd    = $cmd" );
  }
  return $sth;
}

sub executeQuery($$;$@) {
  my util::Db $this = shift;
  my ( $sth, $msg, @query_array ) = @_;
  $this->{error_mgr}->printDebug( '      query_array = ('
      . join( util::Constants::COMMA_SEPARATOR, @query_array )
      . ')' )
    if ( $this->{print_info} );
  eval { $sth->execute(@query_array); };
  my $status = $@;
  if ( ( defined($status) && $status )
    || $sth->err )
  {
    $status = util::Constants::TRUE;
    $msg =
      ( !defined($msg) || $msg eq util::Constants::EMPTY_STR )
      ? 'execute query'
      : $msg;
    my $errstr =
      ( defined($sth) && defined( $sth->errstr ) )
      ? $sth->errstr
      : 'undefined error';
    my $error = ( defined($status) ) ? $status : 'undefined error';
    $this->_processQueryError( "executeQuery Error\n"
        . "   msg    = $msg\n"
        . "   errstr = $errstr\n"
        . "   error  = $error" );
  }
  else {
    $status = util::Constants::FALSE;
  }
  return $status;
}

sub doQuery($$;$@) {
  my util::Db $this = shift;
  my ( $cmd, $msg, @query_array ) = @_;
  my $sth = $this->prepareQuery( $cmd, $msg );
  return $sth if ( !defined($sth) );
  my $status = $this->executeQuery( $sth, $msg, @query_array );
  return undef if ($status);
  return $sth;
}

################################################################################

1;

__END__

=head1 NAME

Db.pm

=head1 SYNOPSIS

use util::Db;

=head1 DESCRIPTION

This class provides the basic Oracle database API creating and managing a
database session, including preparing and executing queries and managing
database transactions.  This class uses the static class L<util::CachedDBI> to
manage connection services for its database sessions.

=head1 CONSTANTS

The following LOB constant is exported:

   util::Db::LOB_LENGTH -- 2000000000

The following Infinite time constant is exported:

   util::Db::INFINITE_TIME -- 99999999999

=head1 CONSTRUCTOR

The following constructors are exported.

=head2 B<new util::Db(server_type, database_name, user_name, password, schema_owner, msg)>

This method is a constructor for the class and requires the database
parameters.  The following session attributes are set:

   LongTruncOK -- TRUE (1)
   PrintError  -- TRUE (1)
   RaiseError  -- TRUE (1)
   AutoCommit  -- TRUE (1)


=head2 B<newByFile util::Db(db_config, msg)>

This method is a constructor for the class and requires a database
configuration file, B<db_config>, and a messaging object, B<msg>.  The
database configuration file conforms to the specification required by
the static method B<read_db_config_file> in L<util::DbConfig> (see
below).  The message object must have the following base class
L<util::Msg>.  The constructor reads the database configuration file
for the tags and opens a (unique) database session.  If any errors
occur in opening a session, the constructor terminates the program.
The session is opened in a non-transactional mode.

The database configuration file must have the following format:

  Server        OracleDB  (or mySQL)
  Database      FOO_FOO
  Username      tsmith
  Password      <<mypassword>>
  SchemaOwner   MY_SCHEMA
  DBTEXTSIZE    2000000
  ...

The Server, Database, Username, and Password are required tags and
must be the above order in the db_config file.  Optional tags can
follow the required ones (e.g., SchemaOwner, DBTEXTSIZE, etc.)  and
be in any order.  The SchemaOwner represents the schema owner name
and will cause a warning message to be written if not present in the
db_config file.  Any amount of whitespace can be between the tag name
and its value.

The following session attributes are set:

   LongTruncOK -- TRUE (1)
   PrintError  -- TRUE (1)
   RaiseError  -- TRUE (1)
   AutoCommit  -- TRUE (1)

=head1 SESSION MANAGEMENT METHODS

The following session management methods are exported.

=head2 B<closeSession>

This method closes an open session.

=head2 B<$status = rollback>

This method rolls back any pending updates that have not been
commited.  Rollback is only effective if B<AutoCommit> is off (see
L<"resetAutoCommit">).  If B<AutoCommit> is on (L<"setAutoCommit">),
then all updates are automatically commited and cannot be rolled back.
This method returns FALSE (0) if no error occurred in rollback or
AutoCommit is on, otherwise it returns TRUE (1) if errors occurred.

=head2 B<rollbackAndClose>

This method rolls back any pending updates that have not been commited
using L<"$status = rollback"> and then closes the database session.
If any error occur during the operation, the method terminates the
program.  This method does nothing if the session is not open.

=head1 TRANSACTIONAL METHODS

=head2 B<startTransaction([@params])>

This method opens a transaction on the database session if one has not
already been opened.  This method can take several class specific
parameters.  However, in this base class, they are not necessary and
are ignored.  As part of the transaction B<AutoCommit> is turned off
(FALSE--0).  Updates to the database must be executed using
L<"executeUpdate(sth[, msg[, @query_array]])"> and commited using
L<"$status = commitTransaction">, otherwise the final state of the database can
be indeterminate.  Uncommited updated can be rolled by using
L<"$status = rollback"> or L<"rollbackAndClose">.  Queries should be prepared
after the transaction is started.  Finally, if this method fails to
create a transaction, it will terminate the program in an error
message.

=head2 B<executeUpdate(sth[, msg[, @query_array]])>

This method executes an update to the database (insert, delete, or
update) if the transaction is open.  It increments the commit count by
one (1) and executes B<executesQuery> with die_on_error set to TRUE
(1).

=head2 B<$sth = doUpdate(cmd[, msg[, @query_array]])>

This method prepares and executes an update (sql command with the
optional query_array and error message.  The method serially executes
B<prepareQuery> and B<executeUpdate> and returns the statement handle
if susccessful, otherwise it returns B<undef>.

=head2 B<$status = commitTransaction>

If the object has an open transaction, then this method will commit
any updates that have been executed since the last commit.  Updates
need to be executed using L<"executeUpdate(sth[, msg[, @query_array]])">.
If the commit is successful, it returns FALSE (0), otherwise it
returns TRUE (1).

=head2 B<exitProgram(msg, error)>

This method will terminate a program with the message B<msg> if error
is TRUE using B<dieOnError> in the messaging object. Further, if a
database transaction is currently open, then it generates an error
message and rolls back the transaction to the last commit point and
closes the database session before terminating the program.

=head2 B<finalizeTransaction(header)>

This method either commits a transaction or rolls it back based on
whether debugging is on or not.  Then the method either prints a
header message describing the number of commits and whether the
transaction was commit or rolled back.  Finally, the method closes the
database session.  The header beginning header to the header message.

=head1 SETTER METHODS

The following setter methods are exported

=head2 B<setAutoCommit>

This method sets the database session AutoCommit to on (TRUE--1).

=head2 B<resetAutoCommit>

This method sets the database session AutoCommot to off (FALSE--0).

=head2 B<setDebugTrace([trace_level[, trace_file]])>

This method sets the DBI debug tracing_level and trace_file.  If the
trace_level is undefined, then it is set at level two (2), otherwise
the trace level is set to specified level.  If the trace_file is
undefined, then trace information is written to STDOUT, otherwise the
trace_file is removed and opened for trace output.

=head2 B<unsetDebugTrace>

This method sets the DBI trace level to zero (0).

=head2 B<setDieOnError>

This method sets die on error to TRUE (1).  That is, if an error
occurs in a database operation, the transaction is rolled
back (if any), database session is closed and the program is
terminated.  Initially, die on error is FALSE (0).

=head2 B<resetDieOnError>

This method sets die on error to FALSE (0).  That is, if an error
occurs in a databases operation, then an only error message is
written.

=head2 B<setLongReadLen(length)>

This method sets the database session B<LongReadLen> to length
assuming it is a positive integer.

=head2 B<setRetries>

This method sets the number of retries for obtaining a database connection to
an integer value.  The method returns without taking action if the parameter
is not all digits.

=head2 B<unsetRetries>

This method sets the number of retries for obtaining a database connection to zero.

=head1 GETTER METHODS

=head2 B<getDbConfig>

The method returns the database configuration file filename.

=head2 B<getName>

This method returns the B<Database> tag from the database
configuration file.

=head2 B<getRetries>

This method returns the number of retries performed when attempting to make
a database connection

=head2 B<getSchemaOwner>

This method returns the B<SchemaOwner> tag from the database
configuration file.

=head2 B<getServer>

This method returns the B<Server> tag from the database
configuration file.

=head2 B<getSession>

This method returns the DBI database session handle.

=head2 B<sessionOpen>

This method return TRUE (1) if the database session is open, otherwise
it returns FALSE (0).

=head2 B<getUser>

This method returns the B<Username> tag from the database
configuration file.

=head2 B<dieOnError>

This method returns TRUE (1) if die_on_error is set, otherwise it
returns FALSE (0)--die_on_error is not set.

=head2 B<transactionOpen>

This method returns TRUE (1) if a transaction is currently open,
otherwise it returns FALSE (0).

=head2 B<getTransactionId>

This method returns the transaction_id.  If a transaction is open,
then the value is defined, otherwise it is B<undef>.

=head2 B<getUpdateTs>

This method returns the update UNIX timestamp for the transaction if
it is open, otherwise it returns B<undef>.  In the base class, this
timestamp is the current time.

=head2 B<getCommitCount>

This method returns the number of update executed during a
transaction.

=head2 B<getCommitedCount>

This method returns the number of updates commited during the
transaction.

=head1 QUERY METHODS

For the following query methods the B<@query_array> parameter contains
values for the queries bind parameters (i.e., '?').  If the query has
no bind parameters, or the parameters have been bound to program
variables, then the B<@query_array> parameters should not be passed or
if passed it must be empty.

=head2 B<$sth = prepareQuery(cmd[, msg])>

The method prepares a query defined by sql command, B<cmd>, using the
optional message for debugging and error messages.  If die_on_error is
set, then the program will terminate with an error message if the
query fails to prepare.  Further, if a error occurs during query
preparation and transaction is open, then the transaction is rolled
back and the database session if closed.  This method returns the
statement handle, if the prepare is successful, otherwise it returns
B<undef>.

=head2 B<$status = executeQuery(sth[, msg[, @query_array]])>

The method executes the statement handle using the optional
query_array and message.  If die_on_error is set, then the program
will terminate with an error message if the query fails to execute.
Further, if a error occurs during query execution and transaction is
open, then the transaction is rolled back and the database session if
closed.  This method returns FALSE (0), if the execution is
succesfull, other it returns TRUE (1).

=head2 B<$sth = doQuery(cmd[, msg[, @query_array]])>

This method prepares and executes an sql command with the optional
query_array and error message.  The method serially executes
B<prepareQuery> and B<executeQuery> and returns the statement handle
if susccessful, otherwise it returns B<undef>.

=cut
