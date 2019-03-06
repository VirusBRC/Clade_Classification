package db::Schema::Load;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;
use util::DbQuery;
use util::PathSpecifics;

use base 'db::Schema';

use fields qw(
  bcp_files
  db
  db_queries
  table_order
  use_tables
  update_cols
);

################################################################################
#
#			     Static Class Constants
#
################################################################################
###
### Ordering function for partial order
###
sub posetTableSort {
  $a->{poset} <=> $b->{poset}
    or $a->{table} cmp $b->{table};
}

################################################################################
#
#				Private Methods
#
################################################################################

sub _setBcpFiles {
  my db::Schema::Load $this = shift;
  foreach my $file ( $this->useTables ) {
    my $bcp_info = {
      obj => undef,
      bcp => join( util::Constants::SLASH,
        $this->{bcp_directory},
        join( util::Constants::DOT, $file, $this->BCP_TYPE )
      ),
    };
    ###
    ### Check existence of bcp file
    ###
    $this->_setStatus( !-e $bcp_info->{bcp} || !-r $bcp_info->{bcp} );
    $this->_dieOnError(
      "Bcp File is inaccessible\n" . "  bcp_file = " . $bcp_info->{bcp} );
    ###
    ### generate bcp file reader
    ###
    my $bcp_type   = $this->getBcpType($file);
    my $ord        = [ $this->getColumnOrder($file) ];
    my @eval_array = (
      'use ' . $bcp_type . ';',
      '$bcp_info->{obj} = ',
      '  new ' . $bcp_type,
      '    (undef,',
      '     $ord,',
      '     $this->{error_mgr});'
    );
    my $eval_str = join( util::Constants::NEWLINE, @eval_array );
    $this->{error_mgr}->unsetHardDie;
    $this->{error_mgr}
      ->printMsg( "Eval code for LoadTable\n" . "  eval_str =\n$eval_str" );
    eval $eval_str;
    my $status = $@;
    $this->_setStatus( ( defined($status) && $status )
        || !defined( $bcp_info->{obj} ) );
    $this->_dieOnError( "Instantiation Status\n"
        . "  class  = bcp_type\n"
        . "  errMsg = $status" );
    $this->{bcp_files}->{$file} = $bcp_info;
  }
}

sub _getPosetEdges {
  my db::Schema::Load $this = shift;
  ###
  ### Must reduce edges to only those that are part of
  ### use table set.
  ###
  my $useTables = {};
  foreach my $table ( $this->useTables ) {
    $useTables->{$table} = util::Constants::EMPTY_STR;
  }
  ###
  ### Run query to return the edges A -> B (A depends on B).
  ### A depends on B if A has a foreign key constraint which
  ### is the primary key constraint for B.
  ###
  my $query = 'getTableDependencies';
  $this->{db_queries}
    ->doQuery( $query, $this->getPosetQuery, 'Get Table Dependencies' );
  my @edges = ();
  while ( my $row_ref = $this->{db_queries}->fetchRowRef($query) ) {
    my ( $table_1, $table_2 ) = @{$row_ref};
    $table_1 = lc($table_1);
    $table_2 = lc($table_2);
    next
      if ( !defined( $useTables->{$table_1} )
      || !defined( $useTables->{$table_2} ) );
    my $edge = [ $table_1, $table_2 ];
    next if ( $edge->[0] eq $edge->[1] );
    push( @edges, $edge );
  }
  $this->{db_queries}->finishQuery($query);

  return @edges;
}

sub _determineTableOrder {
  my db::Schema::Load $this = shift;
  ###
  ### The first step is to prepare the tables by making sure all table
  ### names are upper-cased.  The table_index is needed for the partially
  ### ordered set algorithm.  The substitutor is the parameter list for
  ### the tables in the query.
  ###
  my @tables      = $this->useTables;
  my $table_index = {};
  foreach my $index ( 0 .. $#tables ) {
    my $table = $tables[$index];
    $tables[$index] = $table;
    $table_index->{$table} = {
      table => $table,
      poset => 0
    };
  }
  ###
  ### The algorithm here simply iterates over the edges where each edge
  ### connects a source vertex s to a referenced vertex r.  The current
  ### poset number of s is set to the poset number of r plus 1, unless
  ### this number is less than the current poset number of s.  The algorithm
  ### is complete as long as it iterates through the edges d times where
  ### d is the longest directed path, or diameter, of the graph.  Since d
  ### is not known here, we can place an upper limit on d of |E| where in
  ### the worst case the diameter of the graph is equal to |E| (all vertices
  ### are on a single path).  To make the algorithm efficient, though, we
  ### can quit iterating through the edges as soon as one iteration produces
  ### no changes to the poset numbers.  This occurs when the actual diameter
  ### of the graph is less than the current iteration number.
  ###
  my @edges       = $this->_getPosetEdges;
  my $edge_count  = $#edges + 1;
  my $change_flag = util::Constants::FALSE;
  ### One more time on the outer loop
  ### so that the degenerate case (one-edge)
  ### can be handled correctly.
  for ( my $i = 0 ; $i < ( $edge_count + 1 ) ; $i++ ) {
    $change_flag = util::Constants::FALSE;
    for ( my $j = 0 ; $j < $edge_count ; $j++ ) {
      my $new_poset = $table_index->{ $edges[$j][1] }->{poset} + 1;
      if ( $new_poset > $table_index->{ $edges[$j][0] }->{poset} ) {
        $change_flag = util::Constants::TRUE;
        $table_index->{ $edges[$j][0] }->{poset} = $new_poset;
      }
    }
    last if ( !$change_flag );
  }
  ###
  ### A cycle exists in the graph.  This is unlikely for relational tables,
  ### but must be verified.
  ###
  $this->_setStatus($change_flag);
  $this->_dieOnError( "A cycle exists in the grap\n"
      . "  tables =("
      . join( util::Constants::COMMA_SEPARATOR, @tables )
      . ")" );
  ###
  ### Finally, generate a table list in poset order
  ###
  my @poset_tables =
    sort db::Schema::Load::posetTableSort values( %{$table_index} );
  $this->{table_order} = [];
  foreach my $poset_table (@poset_tables) {
    push( @{ $this->{table_order} }, $poset_table->{table} );
  }
}

sub _insertCmd {
  my db::Schema::Load $this = shift;
  my ( $tableName, @colOrd ) = @_;

  my @params = ();
  foreach (@colOrd) { push( @params, '?' ); }
  my $schemaOwner = $this->{db}->getSchemaOwner;
  my $cmd         = "
insert into ${schemaOwner}.${tableName}
       (" . join( util::Constants::COMMA_SEPARATOR, @colOrd ) . ")
values
       (" . join( util::Constants::COMMA_SEPARATOR, @params ) . ")
";
  return $cmd;
}

sub _updateCmd {
  my db::Schema::Load $this = shift;
  my ($tableName)           = @_;
  my @updateCols            = ();
  foreach my $col ( $this->getUpdateCols($tableName) ) {
    push( @updateCols, "$col = ?" );
  }
  my @keyCols = ();
  foreach my $col ( $this->getColumnKeys($tableName) ) {
    push( @keyCols, "$col = ?" );
  }
  my $cmd = "
update $tableName
set    " . join( util::Constants::COMMA_SEPARATOR, @updateCols ) . "
where  " . join( ' and ',                          @keyCols ) . "
";
  return $cmd;
}

sub _queryArray {
  my db::Schema::Load $this = shift;
  my ( $rowEntity, @colOrd ) = @_;
  my @query_array = ();
  foreach my $colName (@colOrd) {
    push( @query_array, $rowEntity->{$colName} );
  }
  return @query_array;
}

sub _setUseTables {
  my db::Schema::Load $this = shift;
  my (@use_tables) = @_;
  ###
  ### If there are no use tables, then it is all tables in the schema
  ###
  if ( @use_tables == 0 ) {
    push( @{ $this->{use_tables} }, $this->files );
    return;
  }
  ###
  ### If there are use_tables then use them after
  ### verifying that they belong to the schema
  ###
  foreach my $table (@use_tables) {
    $table = lc($table);
    $this->_setStatus( !$this->fileInSchema($table) );
    $this->_dieOnError( "Table is not in schema\n" . "  table = $table" );
    push( @{ $this->{use_tables} }, $table );
  }
}

################################################################################
#
#				Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $table_info, $bcp_directory, $db, $error_mgr, @use_tables ) = @_;
  my db::Schema::Load $this =
    $that->SUPER::new( $table_info, $bcp_directory, $error_mgr );

  $this->{bcp_files}   = {};
  $this->{db_queries}  = new util::DbQuery($db);
  $this->{db}          = $db;
  $this->{table_order} = [];
  $this->{use_tables}  = [];
  $this->{update_cols} = {};
  ###
  ### Set the use tables
  ### and
  ### then set the bcp files
  ###
  $this->_setUseTables(@use_tables);
  $this->_setBcpFiles;
  ###
  ### Finally, determine table order for the use tables
  ###
  $this->_determineTableOrder;

  return $this;
}

sub useTables {
  my db::Schema::Load $this = shift;
  return @{ $this->{use_tables} };
}

sub getPosetQuery {
  my db::Schema::Load $this = shift;
  #######################
  ###                 ###
  ### Abstract Method ###
  ###                 ###
  #######################
  ###
  ### Returns the specific query to get the poset edges
  ###
  $this->{error_mgr}
    ->printDebug("Abstract Method fof db::Schema::Load::getPosetQuery");
  return undef;
}

sub delete {
  my db::Schema::Load $this = shift;
  my (@other_tables_to_delete) = @_;
  $this->{error_mgr}->printHeader("Deleting Tables");
  my @delete_tables = ();
  foreach my $table (@other_tables_to_delete) {
    $table = lc($table);
    $this->_setStatus( !$this->fileInSchema($table) );
    $this->_dieOnError(
      "Delete table is not part of schema\n" . "  table = $table" );
    push( @delete_tables, $table );
  }
  push( @delete_tables, reverse @{ $this->{table_order} } );
  my $schemaOwner = $this->{db}->getSchemaOwner;
  foreach my $table_name (@delete_tables) {
    $this->{error_mgr}->printMsg("Table = $table_name");
    $this->{db_queries}->doQuery(
      "delete_${table_name}",
      "delete from ${schemaOwner}.${table_name}",
      "Delete command for $table_name"
    );
  }
}

sub truncate {
  my db::Schema::Load $this = shift;
  my (@other_tables_to_truncate) = @_;
  $this->{error_mgr}->printHeader("Truncating Tables");
  my @truncate_tables = ();
  foreach my $table (@other_tables_to_truncate) {
    $table = lc($table);
    $this->_setStatus( !$this->fileInSchema($table) );
    $this->_dieOnError(
      "Truncate table is not part of schema\n" . "  table = $table" );
    push( @truncate_tables, $table );
  }
  push( @truncate_tables, reverse @{ $this->{table_order} } );
  my $schemaOwner = $this->{db}->getSchemaOwner;
  foreach my $table_name (@truncate_tables) {
    $this->{error_mgr}->printMsg("Table = $table_name");
    $this->{db_queries}->doQuery(
      "truncate_${table_name}",
      "truncate table ${schemaOwner}.${table_name}",
      "Truncate command for $table_name"
    );
  }
}

sub partialDelete {
  my db::Schema::Load $this = shift;
  my ( $tables_ord, $predicates, $col_vals ) = @_;
  $this->{error_mgr}->printHeader("Partial Deletion of Tables");
  my @ord_col_vals  = ();
  my $col_vals_pred = undef;
  if ( defined($col_vals) ) {
    my @col_predicates = ();
    while ( my ( $col, $val ) = each %{$col_vals} ) {
      push( @col_predicates, "$col = ?" );
      push( @ord_col_vals,   $val );
    }
    $col_vals_pred = 'where ' . join( " and ", @col_predicates );
  }
  my $schemaOwner = $this->{db}->getSchemaOwner;
  foreach my $table_name ( @{$tables_ord} ) {
    $this->{error_mgr}->printMsg("Table = $table_name");
    my $predicate   = util::Constants::EMPTY_STR;
    my @query_array = ();
    if ( defined($predicates) && defined( $predicates->{$table_name} ) ) {
      $predicate   = 'where ' . $predicates->{$table_name}->{pred};
      @query_array = @{ $predicates->{$table_name}->{qarray} };
    }
    else {
      $predicate   = $col_vals_pred;
      @query_array = @ord_col_vals;
    }
    my $cmd = "
delete from ${schemaOwner}.${table_name}
$predicate";
    $this->{db_queries}->doQuery( "delete_${table_name}", $cmd,
      "Partial Delete command for $table_name", @query_array );
  }
}

sub load {
  my db::Schema::Load $this = shift;

  $this->{error_mgr}->printHeader("Loading Tables");
  foreach my $file ( @{ $this->{table_order} } ) {
    my $bcp_info = $this->{bcp_files}->{$file};
    my @ord      = $this->getColumnOrder($file);
    $this->{error_mgr}->printMsg("Table     = $file");
    $this->{error_mgr}->printMsg(
      'Col Order = (' . join( util::Constants::COMMA_SEPARATOR, @ord ) . ')' );
    ###
    ### Prepare insert query
    ###
    my $insertQuery = "insert_$file";
    $this->{db_queries}->createQuery(
      $insertQuery,
      $this->_insertCmd( $file, @ord ),
      "Insert command for $file"
    );
    $this->{db_queries}->prepareQuery($insertQuery);
    $bcp_info->{obj}->setSourceFile( $bcp_info->{bcp} );
    $bcp_info->{obj}->readBcpFile;
    foreach my $entity ( @{ $bcp_info->{obj}->getEntities } ) {
      my @query_array = $this->_queryArray( $entity, @ord );
      $this->{error_mgr}->printMsg( '            ('
          . join( util::Constants::COMMA_SEPARATOR, @query_array )
          . ')' );
      $this->{db_queries}->executeUpdate( $insertQuery, @query_array );
    }
  }
}

sub setUpdateCols {
  my db::Schema::Load $this = shift;
  my ( $table, @update_cols ) = @_;
  ###
  ### Make sure that the table is part of schema
  ###
  $table = lc($table);
  $this->_setStatus( !$this->fileInSchema($table) );
  $this->_dieOnError(
    "Update table is not part of schema\n" . "  table = $table" );
  my $update_cols = $this->{update_cols};
  ###
  ### If the list of columns is empty, then remove
  ### the update columns (if necesssary) and return
  ###
  if ( @update_cols == 0 ) {
    if ( defined( $update_cols->{$table} ) ) {
      delete( $update_cols->{$table} );
    }
    return;
  }
  ###
  ### Now create the set of unique update columns.  They
  ### must be part of the table and not part of the key.
  ###
  $update_cols->{$table} = {};
  foreach my $col (@update_cols) {
    $col = lc($col);
    $this->_setStatus( !$this->colInFile( $table, $col ) );
    $this->_dieOnError( "Update table column is not part of schema\n"
        . "  table = $table\n"
        . "  col   = $col" );
    $this->_setStatus( $this->colInFileKey( $table, $col ) );
    $this->_dieOnError(
          "Update table column is part of the table key in the schema\n"
        . "  table = $table\n"
        . "  col   = $col" );
    $update_cols->{$table}->{$col} = util::Constants::EMPTY_STR;
  }
}

sub getUpdateCols {
  my db::Schema::Load $this = shift;
  my ($table) = @_;
  ###
  ### Make sure that the table is part of schema
  ###
  $table = lc($table);
  my $update_cols = $this->{update_cols}->{$table};
  return $this->getColumnVals($table) if ( !defined($update_cols) );
  return sort keys %{$update_cols};
}

sub update {
  my db::Schema::Load $this = shift;

  $this->{error_mgr}->printHeader("Loading Tables");
  foreach my $file ( @{ $this->{table_order} } ) {
    my $bcp_info = $this->{bcp_files}->{$file};
    my @ord = ( $this->getUpdateCols($file), $this->getColumnKeys($file) );
    $this->{error_mgr}->printMsg("Table     = $file");
    $this->{error_mgr}->printMsg(
      'Col Order = (' . join( util::Constants::COMMA_SEPARATOR, @ord ) . ')' );
    ###
    ### Prepare update query
    ###
    my $updateQuery = "update_$file";
    $this->{db_queries}->createQuery(
      $updateQuery,
      $this->_updateCmd($file),
      "Update command for $file"
    );
    $this->{db_queries}->prepareQuery($updateQuery);
    $bcp_info->{obj}->setSourceFile( $bcp_info->{bcp} );
    $bcp_info->{obj}->readBcpFile;
    foreach my $entity ( @{ $bcp_info->{obj}->getEntities } ) {
      my @query_array = $this->_queryArray( $entity, @ord );
      $this->{error_mgr}->printMsg( '            ('
          . join( util::Constants::COMMA_SEPARATOR, @query_array )
          . ')' );
      $this->{db_queries}->executeUpdate( $updateQuery, @query_array );
    }
  }
}

################################################################################

1;

__END__

=head1 NAME

Load.pm

=head1 DESCRIPTION

The abstract class defines the basic mechanism for loading a database
schema for given type of database from a set of bcp-files.  It requires the
abstract method B<getPosetQuery> to be implemented by a subclass for a given
type of database.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new db::Schema::Load(bcp_directory, table_info, error_mgr)>

This is the constructor for the class.  The B<table_info> data-structure
describes the tables as follows:

B<TBD TBD TBD>

=head2 B<getPosetQuery>

This abstract method returns the query that will generate
the edges (table pairs) that defines the foreign key relationship as follows.
If the table pair (T1, T2) is returned, then T1 depends on T2 in a foreign
key relationship.

=head2 B<delete(@other_tables_to_delete)>

This method deletes the tables that are to be used plus any other tables
to delete (in the order given).  The use tables are deleted in order not
to violated foreign key relations.

=head2 B<partialDelete(tables_ord, predicates, col_vals)>

This method performs a set of partial deletion on a list of tables (in the
order given--referenced array B<tables_ord>) using the B<predicates> and/or
B<col_vals>.  If a table occurs in predicates referenced hash, then that is
used to determine the predicate and query array (each table key has a
referenced hash value containing the B<pred> and B<qarray> keys), 
otherwise the set of column, values in the col_vals referenced hash is used
in the table.  If the B<col_vals> is undefined and there is no reference
in the B<predicates>, then the full table is deleted.  
Either or both B<predicates> and B<col_vals> can be undefined.

=head2 B<load>

This method loads the database schema using the bcp_directory content.

=head2 B<my @use_tables = useTables>

This method returns the list of the current set of use tables.

=head2 B<setUpdateCols(table, @update_cols)>

This method sets the set of update columns for a given table in the
schema.  Each update column must be a value column for the table.

=head2 B<@update_cols = getUpdateCols(table)>

This method returns the list of update columns for the table.  If
update columns have not been explicitly set by the method
B<setUpdateCols>, then the set of value columns for the table is
returned.

=head2 update

This method updates all the tables that have been specified by this
object.  All rows specified by the files must exist in the each of the
tables.  Columns for each table are updated using B<getUpdateCols>
using the table key and the set of file generated.

=cut
