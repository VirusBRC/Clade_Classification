package util::DbQuery;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;

use fields qw(
  db
  queries
);

################################################################################
#
#				 Private Method
#
################################################################################

sub _fetchSth($$) {
  my util::DbQuery $this = shift;
  my ($query) = @_;

  my $sth = $this->sthHandle($query);
  return undef if ( !defined($sth) || $this->queryStatus($query) );
  return $sth;
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new($$) {
  my util::DbQuery $this = shift;
  my ($db) = @_;
  $this = fields::new($this) unless ref($this);
  $this->{db}      = $db;
  $this->{queries} = {};

  return $this;
}

sub prepareQuery($$) {
  my util::DbQuery $this = shift;
  my ($query) = @_;
  $this->{queries}->{$query}->{sth} =
    $this->{db}
    ->prepareQuery( $this->queryCmd($query), $this->queryMsg($query) );
  $this->{queries}->{$query}->{status} =
    !defined( $this->sthHandle($query) )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

sub executeQuery($$;@) {
  my util::DbQuery $this = shift;
  my ( $query, @query_array ) = @_;
  my $sth = $this->_fetchSth($query);
  return if ( !defined($sth) );
  $this->{queries}->{$query}->{status} =
    $this->{db}->executeQuery( $this->sthHandle($query),
    $this->queryMsg($query), @query_array );
}

sub executeUpdate($$;@) {
  my util::DbQuery $this = shift;
  my ( $query, @query_array ) = @_;
  my $sth = $this->_fetchSth($query);
  return if ( !defined($sth) );
  $this->{queries}->{$query}->{status} =
    $this->{db}->executeUpdate( $this->sthHandle($query),
    $this->queryMsg($query), @query_array );
}

sub finishQuery($$) {
  my util::DbQuery $this = shift;
  my ($query) = @_;
  return if ( !defined( $this->sthHandle($query) ) );
  $this->sthHandle($query)->finish;
}

sub finishQueries($) {
  my util::DbQuery $this = shift;
  my ($queries) = @_;
  foreach my $query ( keys %{ $this->{queries} } ) {
    $this->finishQuery($query);
  }
}

################################################################################
#
#				 Setter Methods
#
################################################################################

sub createQuery($$$$) {
  my util::DbQuery $this = shift;
  my ( $query, $cmd, $msg ) = @_;
  return if ( $this->queryDefined($query) );
  $this->{queries}->{$query} = {
    sth    => undef,
    cmd    => $cmd,
    msg    => $msg,
    status => util::Constants::FALSE,
  };
}

sub doQuery($$$$;@) {
  my util::DbQuery $this = shift;
  my ( $query, $cmd, $msg, @query_array ) = @_;
  $this->createQuery( $query, $cmd, $msg );
  $this->{queries}->{$query}->{sth} =
    $this->{db}
    ->doQuery( $this->queryCmd($query), $this->queryMsg($query), @query_array );
  $this->{queries}->{$query}->{status} =
    !defined( $this->sthHandle($query) )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

sub deleteQuery($$) {
  my util::DbQuery $this = shift;
  my ($query) = @_;

  my $queries = $this->{queries};
  return if ( !$this->queryDefined($query) );
  delete( $queries->{$query} );
}

sub createAndPrepareQueries($$) {
  my util::DbQuery $this = shift;
  my ($queries) = @_;
  while ( my ( $query, $query_struct ) = each %{$queries} ) {
    $this->createQuery( $query, $query_struct->{cmd}, $query_struct->{msg} );
    $this->prepareQuery($query);
  }
}

sub prepareQueries($) {
  my util::DbQuery $this = shift;
  foreach my $query ( keys %{ $this->{queries} } ) {
    $this->prepareQuery($query);
  }
}

################################################################################
#
#				 Getter Methods
#
################################################################################

sub queryDefined($$) {
  my util::DbQuery $this = shift;
  my ($query) = @_;
  return defined( $this->{queries}->{$query} );
}

sub queries($) {
  my util::DbQuery $this = shift;
  return keys %{ $this->{queries} };
}

sub queryCmd($$) {
  my util::DbQuery $this = shift;
  my ($query) = @_;
  return undef if ( !$this->queryDefined($query) );
  return $this->{queries}->{$query}->{cmd};
}

sub queryMsg($$) {
  my util::DbQuery $this = shift;
  my ($query) = @_;
  return undef if ( !$this->queryDefined($query) );
  return $this->{queries}->{$query}->{msg};
}

sub queryStatus($$) {
  my util::DbQuery $this = shift;
  my ($query) = @_;
  return undef if ( !$this->queryDefined($query) );
  return $this->{queries}->{$query}->{status};
}

sub sthHandle($$) {
  my util::DbQuery $this = shift;
  my ($query) = @_;
  return undef if ( !$this->queryDefined($query) );
  return $this->{queries}->{$query}->{sth};
}

sub fetchRow($$) {
  my util::DbQuery $this = shift;
  my ($query)            = @_;
  my $sth                = $this->_fetchSth($query);
  return undef if ( !defined($sth) );
  return $sth->fetchrow_array;
}

sub fetchRowRef($$) {
  my util::DbQuery $this = shift;
  my ($query)            = @_;
  my $sth                = $this->_fetchSth($query);
  return undef if ( !defined($sth) );
  return $sth->fetchrow_arrayref;
}

sub fetchRowHashRef($$) {
  my util::DbQuery $this = shift;
  my ($query)            = @_;
  my $sth                = $this->_fetchSth($query);
  return undef if ( !defined($sth) );
  return $sth->fetchrow_hashref;
}

sub fetchSingleRow($$) {
  my util::DbQuery $this = shift;
  my ($query)            = @_;
  my $sth                = $this->_fetchSth($query);
  return undef if ( !defined($sth) );
  my @row = $sth->fetchrow_array;
  $this->finishQuery($query);
  return @row;
}

################################################################################

1;

__END__

=head1 NAME

DbQuery.pm

=head1 SYNOPSIS

   use util::DbQuery;

   $queries = new util::DbQuery($db);

=head1 DESCRIPTION

This class defines a container for a set of database queries.  This
class uses an object whose base class is L<util::Db>, and incapsulates
the standard database operations using the methods below.

=head1 METHODS

The methods define how to create an object of this class and how to
populate this object with database queries that are used by the code.
A query in the container is identified by a name.  The query container
contains an error message, the sql command string, and the statement
handle (after sql command is prepared).

=head2 B<new util::DbQuery(db)>

This method is the constructor for the class.  An object for this
class is initialized as an empty query container using the database
sessions, B<db>.

=head2 B<prepareQuery(query)>

This method prepares the query B<query> for execution.  This method
sets the query status.  The status is FALSE (0) if the query statement
handle exists after preparing the query, otherwise it is TRUE (1).

=head2 B<prepareQueries>

This method prepares the current set of queries that have been created into
the container.

=head2 B<executeQuery(query[, @query_array])>

This method executes the query B<query> using the query array
B<query_array> which can be empty.  This method is only used for
select queries and not for updates.  This method sets the query
status.  The status is FALSE (0) if the query statement handle exists
after preparing the query, otherwise it is TRUE (1).

=head2 B<executeUpdate(query[, @query_array])>

This method executes the query B<query> as an update using the query
array B<query_array> which can be empty.  This method is only used for
updates (inserts, updates, and deletes) to the database.  This method
automatically increments the commit count for the transaction.  This
method sets the query status.  The status is FALSE (0) if the query
statement handle exists after preparing the query, otherwise it is
TRUE (1).

=head2 B<finishQuery(query)>

This method terminates the query B<query>.

=head2 B<finishQueries>

This method terminates all the queries in the container.

=head1 Setter Methods

The following setter methods are exported.

=head2 B<createQuery(query, cmd, msg)>

This method creates a query container with the name B<query> and
having the sql command B<cmd> and the error message B<msg>.  At this
point, the query is not yet prepared for execution.  If the container
already exists for the B<query>, then no action is taken.

=head2 B<doQuery(query, cmd, msg[, @query_array])>

This method creates a query if it does not already exist.  Then it
prepares and executes the query B<query> using the query array
B<query_array> which can be empty.  This method is only used for
select queries and not for updates.  This method sets the query
status.  The status is FALSE (0) if the query statement handle exists
after preparing the query, otherwise it is TRUE (1).

=head2 B<deleteQuery(query)>

This method delete the query losing all the information and handle.

=head2 B<createAndPrepareQueries(queries)>

This method creates and prepares a set of queries provided by the
(referenced) hash, B<queries>.  Each key in queries will define a
query.  The value of a key in queries is a (referenced) hash that must
contain at a minimum two keys:  B<msg> and B<cmd> which are the message
and SQL command string, respectively.

=head1 Getter Methods

The following getter methods are exported.

=head2 B<queryDefined(query)>

This method return TRUE if the query is defined in the container,
othewise it returns FALSE.

=head2 B<@queries = queries>

This method returns the list of queries (query names) currently
defined in the container.

=head2 B<queryCmd(query)>

This method returns query command string if defined, otherwise it
returns undef.

=head2 B<queryMsg(query)>

This method returns query message string if defined, otherwise it
returns undef.

=head2 B<queryStatus(query)>

This method returns the query status after execution of
L<"prepareQuery(query)">,
L<"executeQuery(query[, @query_array])">,
or 
L<"executeUpdate(query[, @query_array])">.
A status of FALSE (0) is a successful execution, otherwise a status of
TRUE (1) is a failure.

=head2 B<sthHandle(query)>

This method returns the statement handle for the query B<query>.  This
is needed for queries that return results (see B<executeQuery>).

=head2 B<fetchRow(query)>

This method returns a row list on fetch for the given query.  If the
query is not defined, or not executed, or there are no more rows
available, then it returns B<undef>.  This provides the following
functionality:

   $sth->fetchrow_array

=head2 B<fetchRowRef(query)>

This method returns row array reference on fetch for the given query.
If the query is not defined, or not executed, or there are no more
rows available, then it returns B<undef>.  This provides the following
functionality:

   $sth->fetchrow_arrayref

=head2 B<fetchRowHashRef(query)>

This method returns row hash reference on fetch for the given query.
If the query is not defined, or not executed, or there are no more
rows available, then it returns B<undef>.  This provides the following
functionality:

   $sth->fetchrow_hashref

=head2 B<fetchSingleRow(query)>

This method returns a row list on fetch for the given query.  If the
query is not defined, or not executed, or there are no more rows
available, then it returns B<undef>.  This provides the following
functionality:

   $sth->fetchrow_array

Moreover, before the row is returned the statement handle is finished.

=cut


