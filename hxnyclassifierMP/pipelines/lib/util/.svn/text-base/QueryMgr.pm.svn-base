package util::QueryMgr;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;

use base 'util::DbQuery';

use fields qw(
  error_mgr
);

################################################################################
#
#				 Private Method
#
################################################################################

sub _getResult($$) {
  my util::QueryMgr $this = shift;
  my ($query) = @_;

  my $dbStruct = $this->{queries}->{$query};
  my $result   = $dbStruct->{result};
  while ( my $row_ref = $this->fetchRowRef($query) ) {
    my $struct = {};
    foreach my $index ( 0 .. $#{ $dbStruct->{ord} } ) {
      $struct->{ $dbStruct->{ord}->[$index] } = $row_ref->[$index];
    }
    next if ( defined( $result->{ $struct->{ $dbStruct->{key} } } ) );
    $result->{ $struct->{ $dbStruct->{key} } } = $struct;
  }
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new($$$) {
  my ( $that, $db, $error_mgr ) = @_;
  my util::QueryMgr $this = $that->SUPER::new($db);

  $this->{error_mgr} = $error_mgr;

  return $this;
}

sub create($$$$$) {
  my util::QueryMgr $this = shift;
  my ( $query, $cmd, $ord, $key ) = @_;
  return if ( $this->queryDefined($query) );
  $this->createQuery( $query, $cmd, $query );
  my $dbStruct = $this->{queries}->{$query};
  $dbStruct->{ord}    = $ord;
  $dbStruct->{key}    = $key;
  $dbStruct->{result} = {};
}

sub createAll($$) {
  my util::QueryMgr $this = shift;
  my ($queries) = @_;
  foreach my $query ( keys %{$queries} ) {
    my $struct = $queries->{$query};
    $this->create( $query, $struct->{cmd}, $struct->{ord}, $struct->{key} );
  }
}

sub updateOrd($$@) {
  my util::QueryMgr $this = shift;
  my ( $query, @ord ) = @_;
  return if ( !$this->queryDefined($query) );
  my $dbStruct = $this->{queries}->{$query};
  push( @{ $dbStruct->{ord} }, @ord );
}

sub updateCmd($$@) {
  my util::QueryMgr $this = shift;
  my ( $query, @subs ) = @_;
  return if ( !$this->queryDefined($query) );
  my $dbStruct = $this->{queries}->{$query};
  foreach my $sub (@subs) {
    my $name = $sub->{name};
    my $val  = $sub->{val};
    $dbStruct->{cmd} =~ s/$name/$val/g;
  }
}

sub do($$$$$;@) {
  my util::QueryMgr $this = shift;
  my ( $query, $key, $ord, $cmd, @params ) = @_;
  $this->doQuery( $query, $cmd, $query, @params );
  my $dbStruct = $this->{queries}->{$query};
  $dbStruct->{ord}    = $ord;
  $dbStruct->{key}    = $key;
  $dbStruct->{result} = {};
  $this->_getResult($query);
}

sub execute($$;@) {
  my util::QueryMgr $this = shift;
  my ( $query, @params ) = @_;
  return if ( !$this->queryDefined($query) );
  $this->executeQuery( $query, @params );
  $this->_getResult($query);
}

sub queryKey($$) {
  my util::QueryMgr $this = shift;
  my ($query) = @_;
  return undef if ( !$this->queryDefined($query) );
  my $dbStruct = $this->{queries}->{$query};
  return $dbStruct->{key};
}

sub queryOrd($$) {
  my util::QueryMgr $this = shift;
  my ($query) = @_;
  return () if ( !$this->queryDefined($query) );
  my $dbStruct = $this->{queries}->{$query};
  return @{ $dbStruct->{ord} };
}

sub getDataKeys ($$) {
  my util::QueryMgr $this = shift;
  my ($query) = @_;
  return () if ( !$this->queryDefined($query) );
  my $dbStruct = $this->{queries}->{$query};
  return sort keys %{ $dbStruct->{result} };
}

sub getData($$$) {
  my util::QueryMgr $this = shift;
  my ( $query, $key ) = @_;
  return undef if ( !$this->queryDefined($query) );
  my $dbStruct = $this->{queries}->{$query};
  return $dbStruct->{result}->{$key};
}

sub resetResult {
  my util::QueryMgr $this = shift;
  my ($query) = @_;
  return if ( !$this->queryDefined($query) );
  my $dbStruct = $this->{queries}->{$query};
  $dbStruct->{result} = {};
}

sub checkData($$$) {
  my util::QueryMgr $this = shift;
  my ( $query, $key ) = @_;
  return util::Constants::FALSE if ( !$this->queryDefined($query) );
  my $dbStruct = $this->{queries}->{$query};
  my $result   = $dbStruct->{result};
  return util::Constants::TRUE if ( defined( $result->{$key} ) );
  $this->{error_mgr}
    ->printWarning( "Missing data\n" . "  query = $query\n" . "  key   = $key",
    util::Constants::TRUE );
  return util::Constants::FALSE;
}

################################################################################

1;

__END__

=head1 NAME

QueryMgr.pm

=head1 SYNOPSIS

   use util::QueryMgr;

   $query_mgr = new util::QueryMgr($db, $error_mgr);

=head1 DESCRIPTION

This class defines a query manager that includes a container for a set
of database queries.  This class is a subclass of L<util::DbQuery> and
uses an object whose base class is L<util::Db>.

=head1 CONSTRUCTOR METHOD

The methods define how to create a manager how to manage several
queries and results.

=head2 B<new util::QueryMgr(db, error_mgr)>

This method is the constructor for the class.  An object for this
class is initialized as an empty query container using the database
session B<db>.  The query manage initially has no queries associated
with it.

=head1 QUERY MANAGEMENT METHODS

The following methods must be used to create and update queries that
are managed by this class.

=head2 B<create(query, cmd, ord, key)>

This method creates a query B<query> using the command B<cmd>, the
ordered columns B<ord> (referenced Perl Hash containing the column
order for a row result), and the key column B<key>.  The key column
must be contained in ord and is a unique key for each row results of
the executed query.

=head2 B<createAll(queries)>

This method takes a referenced Perl Hash B<queries> and creates all
the queries identified by the keys of this Hash.  Each value to this
hash must be a referenced Perl Hash containing at least the keys:

   cmd -- query command
   ord -- referenced Perl Hash containing the column order
          for a row result
   key -- key column contained in ord and identifies unique
          result rows

=head2 B<updateOrd(query, @ord)>

If the B<query> exists, then this method takes the columns in B<@ord>
and adds them in order to the end of the ordered columns for the
query.

=head2 B<updateCmd(query, @subs)>

If the B<query> exists, then this method updates the command for the
query uing the substitutions contained in the list B<@sub>.  Each
element of @sub is a referenced Perl Hash containing the keys: B<name>
and B<val>.  Each substitution (name, val) is applied in order and
replaces all B<name> occurrences with B<val>.  The B<name> is a
regular Perl expression.

=head1 QUERY EXECUTION METHODS

The following methods provide for executing a query.

=head2 B<execute(query[, @params])>

This method executes a B<query> using the optional parameters
B<@params>.  The query needs to already added to the query manager
using one of the methods
L<"create(query, cmd, ord, key)">,
L<"createAll(queries)">,
or
L<"do(query, key, ord, cmd[, @params])">.
The results of the query can be accessed by the methods
L<"@data_keys = getDataKeys(query)"> and
L<"$data = getData(query, key)">,
or removed by method
L<"resetResult(query)">.

=head2 B<do(query, key, ord, cmd[, @params])>

This method executes a B<query> that has the key B<key> and columns
B<ord> (reference Perl array containing the ordered column names for
the result) using the command B<cmd> and the optional parameters
B<@params>.  This method also has the effect of adding this query to
the current queries managed by the query manager object if it has not
already been added.
The results of the query can be accessed by the methods
L<"@data_keys = getDataKeys(query)"> and
L<"$data = getData(query, key)">,
or removed by the method
L<"resetResult(query)">.

=head1 QUERY RESULT METHODS

The following methods allow access to query results.

=head2 B<$key = queryKey(query)>

This method returns the name of the key column for the query.

=head2 B<@ord = queryOrd(query)>

This method returns the ordered list of columns returned for each row
of the query.

=head2 B<@data_keys = getDataKeys(query)>

This method returns the list of key values for the data returned from
executing the query.

=head2 B<$data = getData(query, key)>

This method returns a referenced Perl Hash containing the row of data
for the key value.  The keys in the hash are the columns identified in
the method L<"@ord = queryOrd(query)">

=head2 B<resetResult(query)>

This method removes the current data result for the given query.  This
method should be executed before executing the query again using
either method
L<"do(query, key, ord, cmd[, @params])">
or
L<"execute(query[, @params])">.

=head2 B<checkData(query, key)>

This method returns TRUE (1) if the key value has a defined result for
the query data, otherwise it returns FALSE (0).

=cut
