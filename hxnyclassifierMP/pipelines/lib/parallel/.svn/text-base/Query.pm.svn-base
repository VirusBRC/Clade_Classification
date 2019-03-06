package parallel::Query;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;
use util::DbQuery;

use parallel::ErrMsgs;

use fields qw(
  database_config
  error_mgr
  error_status
  tools
  user
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Query Specific Properties from its Configuration
###
sub MAXELEMENTS_PROP     { return 'maxElements'; }
sub QUERYPARAMSUBS_PROP  { return 'queryParamSubs'; }
sub QUERYPARAMS_PROP     { return 'queryParams'; }
sub QUERYPREDICATES_PROP { return 'queryPredicates'; }
sub QUERYRESULTSORD_PROP { return 'queryResultsOrd'; }
sub QUERY_PROP           { return 'query'; }
###
### Query Handle Name
###
sub DATA_ACQUISITION_QUERY { return 'data_acquisition'; }
###
### Data Types
###
sub NUMERIC_TYPE { return 'numeric'; }
sub VARCHAR_TYPE { return 'varchar'; }
###
### Error Category
###
sub ERR_CAT { return parallel::ErrMsgs::QUERY_CAT; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _setDatabaseConfig {
  my parallel::Query $this = shift;
  my ($properties) = @_;

  $this->{database_config} = undef;

  my $tools        = $this->{tools};
  my $serverType   = $properties->{ $tools->SERVER_TYPE_PROP };
  my $databaseName = $properties->{ $tools->DATABASE_NAME_PROP };
  my $userName     = $properties->{ $tools->USER_NAME_PROP };
  my $password     = $properties->{ $tools->PASSWORD_PROP };
  my $schemaOwner  = $properties->{ $tools->SCHEMA_OWNER_PROP };

  return
    if ( util::Constants::EMPTY_LINE($serverType)
    || util::Constants::EMPTY_LINE($databaseName)
    || util::Constants::EMPTY_LINE($userName)
    || util::Constants::EMPTY_LINE($password)
    || util::Constants::EMPTY_LINE($schemaOwner) );

  $this->{database_config} = {
    serverType   => $serverType,
    databaseName => $databaseName,
    userName     => $userName,
    password     => $password,
    schemaOwner  => $schemaOwner,
  };
}

sub _openSession {
  my parallel::Query $this = shift;

  my $databaseConfig = $this->{database_config};
  my $tools          = $this->{tools};

  $tools->openSession if ( !defined($databaseConfig) );
  $tools->openSessionExplicit(
    $databaseConfig->{serverType}, $databaseConfig->{databaseName},
    $databaseConfig->{userName},   $databaseConfig->{password},
    $databaseConfig->{schemaOwner}
  ) if ( defined($databaseConfig) );
}

sub _setErrorStatus {
  my parallel::Query $this = shift;
  my ( $err_cat, $err_num, $msgs, $test ) = @_;

  return if ( !$test );
  if ( defined( $this->{user} ) ) {
    $this->{user}->setErrorStatus( $err_cat, $err_num, $msgs, $test );
    return;
  }
  $this->{error_mgr}->registerError( $err_cat, $err_num, $msgs, $test );
  $this->{error_status} = util::Constants::TRUE;
}

sub _isDataType {
  my parallel::Query $this = shift;
  my ($dataType) = @_;

  return util::Constants::TRUE if ( lc($dataType) eq NUMERIC_TYPE );
  return util::Constants::TRUE if ( lc($dataType) eq VARCHAR_TYPE );
  return util::Constants::FALSE;
}

sub _getStruct {
  my parallel::Query $this = shift;
  my ( $row, $ord ) = @_;
  my $struct = {};
  foreach my $index ( 0 .. $#{$ord} ) {
    $struct->{ $ord->[$index] } = $row->[$index];
  }
  return $struct;
}

sub _querySub {
  my parallel::Query $this = shift;
  my ( $query, $param, $type, $vals ) = @_;

  $this->_setErrorStatus(
    ERR_CAT, 5,
    [ $param, $type, ],
    !$this->_isDataType($type)
  );
  return $query if ( !$this->_isDataType($type) );

  my $qval = util::Constants::EMPTY_STR;
  foreach my $val ( @{$vals} ) {
    if ( !util::Constants::EMPTY_LINE($qval) ) {
      $qval .= util::Constants::COMMA;
    }
    if ( $type eq VARCHAR_TYPE ) {
      $qval .=
        util::Constants::SINGLE_QUOTE . $val . util::Constants::SINGLE_QUOTE;
    }
    else { $qval .= $val; }
  }
  $query =~ s/$param/$qval/g;
  return $query;
}

sub _getVals {
  my parallel::Query $this = shift;
  my ( $param, $valsFile ) = @_;

  my $vals = [];

  my $fh = new FileHandle;
  $this->_setErrorStatus(
    ERR_CAT, 1,
    [ $valsFile, ],
    !$fh->open( $valsFile, '<' )
  );
  return $vals if ( $this->getErrorStatus );

  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    my @comps = split( /\t/, $line );
    foreach my $comp (@comps) {
      push( @{$vals}, $comp );
    }
  }
  $this->_setErrorStatus(
    ERR_CAT, 2,
    [ $param, $valsFile, ],
    scalar @{$vals} == 0
  );

  return $vals;
}

sub _setQueryPredicate {
  my parallel::Query $this = shift;
  my ($properties) = @_;

  my $query           = $properties->{&QUERY_PROP};
  my $queryParams     = $properties->{&QUERYPARAMS_PROP};
  my $queryParamSubs  = $properties->{&QUERYPARAMSUBS_PROP};
  my $queryPredicates = $properties->{&QUERYPREDICATES_PROP};

  return
    if ( util::Constants::EMPTY_LINE($queryPredicates)
    || ref($queryPredicates) ne $this->{tools}->serializer->HASH_TYPE );

  foreach my $param ( sort keys %{$queryPredicates} ) {
    next if ( util::Constants::EMPTY_LINE( $properties->{$param} ) );
    my $qdata     = $queryPredicates->{$param};
    my $params    = $qdata->{params};
    my $predicate = $qdata->{predicate};
    $query .= "\n$predicate";
    push( @{$queryParams}, @{$params} )
      if ( defined($queryParamSubs)
      && !defined( $queryParamSubs->{$param} ) );
  }
  $properties->{&QUERY_PROP} = $query;
}

sub _getParamSubs {
  my parallel::Query $this = shift;
  my ($properties) = @_;

  my $exceedsParam    = undef;
  my $exceedsVals     = undef;
  my $maxElements     = $properties->{&MAXELEMENTS_PROP};
  my $otherSubs       = {};
  my $queries         = [];
  my $query           = $properties->{&QUERY_PROP};
  my $queryParamSubs  = $properties->{&QUERYPARAMSUBS_PROP};
  my $queryPredicates = $properties->{&QUERYPREDICATES_PROP};
  ###
  ### Determine the values for the substitution and
  ### find which one exceeds maxElements.  Only allow
  ### one to exceed maxElements
  ###
  foreach my $param ( sort keys %{$queryParamSubs} ) {
    my $vals = $properties->{$param};
    next
      if ( util::Constants::EMPTY_LINE($vals)
      && defined($queryPredicates)
      && defined( $queryPredicates->{$param} ) );
    if (
      util::Constants::EMPTY_LINE($vals)
      || ( ref($vals) eq $this->{tools}->serializer->ARRAY_TYPE
        && scalar @{$vals} == 0 )
      )
    {
      $this->_setErrorStatus( ERR_CAT, 3, [$param], util::Constants::TRUE );
      next;
    }
    ###
    ### This is a values file
    ###
    if ( ref($vals) ne $this->{tools}->serializer->ARRAY_TYPE ) {
      $vals = $this->_getVals( $param, $vals );
      next if ( $this->getErrorStatus );
    }
    $this->_setErrorStatus(
      ERR_CAT, 4,
      [ $maxElements, $exceedsParam, $param ],
      defined($exceedsParam) && scalar @{$vals} > $maxElements
    );
    if ( !defined($exceedsParam) && scalar @{$vals} > $maxElements ) {
      $exceedsParam = $param;
      $exceedsVals  = $vals;
    }
    elsif ( scalar @{$vals} <= $maxElements ) {
      $otherSubs->{$param} = $vals;
    }
  }
  return $queries if ( $this->getErrorStatus );
  ###
  ### Now generate query with all other substitutions
  ###
  foreach my $param ( sort keys %{$otherSubs} ) {
    $query = $this->_querySub( $query, $param, $queryParamSubs->{$param},
      $otherSubs->{$param} );
  }
  return $queries if ( $this->getErrorStatus );
  ###
  ### If no parameter exceeds maxElements, return immediately
  ###
  if ( !defined($exceedsParam) ) {
    push( @{$queries}, $query );
    return $queries;
  }
  ###
  ### Generate queries for the parameter exceeding $maxElements
  ###
  my $subvals = [];
  foreach my $val ( @{$exceedsVals} ) {
    if ( scalar @{$subvals} == $maxElements ) {
      my $squery =
        $this->_querySub( $query, $exceedsParam,
        $queryParamSubs->{$exceedsParam}, $subvals );
      push( @{$queries}, $squery );
      $subvals = [];
    }
    push( @{$subvals}, $val );
  }
  if ( scalar @{$subvals} > 0 ) {
    my $squery =
      $this->_querySub( $query, $exceedsParam, $queryParamSubs->{$exceedsParam},
      $subvals );
    push( @{$queries}, $squery );
  }

  return $queries;
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my parallel::Query $this = shift;
  my ( $user, $error_mgr, $tools ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{database_config} = undef;
  $this->{error_mgr}       = $error_mgr;
  $this->{error_status}    = util::Constants::FALSE;
  $this->{tools}           = $tools;
  $this->{user}            = $user;

  return $this;
}

sub getData {
  my parallel::Query $this = shift;
  my ($properties) = @_;

  $this->_setDatabaseConfig($properties);

  my @data = ();

  my $queryParams     = $properties->{&QUERYPARAMS_PROP};
  my $queryResultsOrd = $properties->{&QUERYRESULTSORD_PROP};

  $this->_setQueryPredicate($properties);
  my $queries = $this->_getParamSubs($properties);
  return @data if ( $this->getErrorStatus );

  my @paramsData = ();
  foreach my $param ( @{$queryParams} ) {
    my $val = $properties->{$param};
    $this->_setErrorStatus( ERR_CAT, 6, [$val],
      util::Constants::EMPTY_LINE($val) );
    push( @paramsData, $val );
  }

  $this->{error_mgr}->printHeader("Executing Queries");
  $this->_openSession;
  my $db_queries = new util::DbQuery( $this->{tools}->getSession );
  my $count      = 0;
  my $countStr   = util::Constants::EMPTY_STR;
  foreach my $query ( @{$queries} ) {
    $this->{error_mgr}->printMsg( "Executing Query\n" . "  query =\n $query" );
    $db_queries->deleteQuery(DATA_ACQUISITION_QUERY);
    $db_queries->createQuery( DATA_ACQUISITION_QUERY, $query,
      DATA_ACQUISITION_QUERY );
    $db_queries->prepareQuery(DATA_ACQUISITION_QUERY);
    $db_queries->executeQuery( DATA_ACQUISITION_QUERY, @paramsData );
    while ( my $row_ref = $db_queries->fetchRowRef(DATA_ACQUISITION_QUERY) ) {
      $count++;
      if ( $count % 1000 == 0 ) { $countStr .= util::Constants::DOT; }
      if ( length($countStr) == 50 ) {
        $this->{error_mgr}->printMsg($countStr);
        $countStr = util::Constants::EMPTY_STR;
      }
      my $struct = $this->_getStruct( $row_ref, $queryResultsOrd );
      push( @data, $struct );
    }
    $db_queries->finishQuery(DATA_ACQUISITION_QUERY);
  }
  $this->{tools}->closeSession;
  $this->{error_mgr}->printMsg($countStr);
  $this->{error_mgr}->printHeader("Completed Queries");

  return @data;
}

sub getErrorStatus {
  my parallel::Query $this = shift;

  return $this->{user}->getErrorStatus if ( defined( $this->{user} ) );
  return $this->{error_status};
}

################################################################################

1;

__END__

=head1 NAME

Query.pm

=head1 DESCRIPTION

This class defines how to manage a query using the standard properties.
The user object if defined must have the methods
B<setErrorStatus(err_num, msgs, tests)> and B<getErrorStatus()>.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Query(user, error_mgr, tools)>

This is the constructor for the class.

=cut
