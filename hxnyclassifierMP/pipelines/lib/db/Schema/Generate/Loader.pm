package db::Schema::Generate::Loader;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;
use util::FileTime;

use base 'db::Schema::Generate';

use fields qw (
  load_time
  loader
  tables
  tools
  update_cols
);

################################################################################
#
#				Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $tools, $error_mgr ) = @_;
  my db::Schema::Generate::Loader $this =
    $that->SUPER::new( $tools->getTableInfo, $tools->getBcpDir, $error_mgr );

  $this->{loader}      = undef;
  $this->{tables}      = [];
  $this->{tools}       = $tools;
  $this->{update_cols} = {};

  $this->{load_time} = &get_oracle_str( get_unix_time( $tools->getStartTime ),
    util::Constants::TRUE );

  return $this;
}

sub addTable {
  my db::Schema::Generate::Loader $this = shift;
  my ($table) = @_;
  push( @{ $this->{tables} }, lc($table) );
}

sub addUpdateCols {
  my db::Schema::Generate::Loader $this = shift;
  my ( $table, @update_cols ) = @_;
  $table = lc($table);
  my $update_cols = $this->{update_cols};
  $update_cols->{$table} = [@update_cols];
}

sub getUpdateCols {
  my db::Schema::Generate::Loader $this = shift;
  my ($table) = @_;
  $table = lc($table);
  my @update_cols = ();
  my $update_cols = $this->{update_cols}->{$table};
  return @update_cols if ( !defined($update_cols) );
  return @{$update_cols};
}

sub getLoadTime {
  my db::Schema::Generate::Loader $this = shift;
  return $this->{load_time};
}

sub generate {
  my db::Schema::Generate::Loader $this = shift;
  #######################
  ### Abstract Method ###
  #######################
  $this->{error_mgr}
    ->printDebug("Abstract method db::Schema::Generate::Loader::generate");
}

sub delete {
  my db::Schema::Generate::Loader $this = shift;
  ###############################
  ### Re-Implementable Method ###
  ###############################
  $this->{loader}->delete;
}

sub load {
  my db::Schema::Generate::Loader $this = shift;

  $this->closeBcpHandles;
  $this->{loader} = $this->{tools}->openLoader( $this->filesLoaded );
  $this->delete;
  $this->{loader}->load;
}

sub update {
  my db::Schema::Generate::Loader $this = shift;

  $this->closeBcpHandles;
  $this->{loader} = $this->{tools}->openLoader( $this->filesLoaded );
  foreach my $file ( $this->filesLoaded ) {
    $this->{loader}->setUpdateCols( $file, $this->getUpdateCols($file) );
  }
  $this->{loader}->update;
}

################################################################################

1;

__END__

=head1 NAME

Loader.pm

=head1 DESCRIPTION

This abstract class defines the loader for loading specific set of
tables.   Also a subclass must set the set of tables that it is to
load using L<"addTable(table)">.

=head1 METHODS

The following method are exported by this class.

=head2 B<new db::Schema::Generate::Loader(tools, error_mgr)>

This is the constructor for the class.  The constructor assumes that the bcp
directory in the tools has been set and created and the table_info has been
set in the tools.

=head2 B<addTable(table)>

This method adds a table to the list of tables that will be loaded.  A
subclass needs to specify the set of tables it is loading.

=head2 B<addUpdateCols(table, @update_cols)>

This method adds the update columns for a table.  These update columns
will be used if the update method is executed.

=head2 B<@update_cols = getUpdateCol(table, col)>

This method returns the list of update columns for the table.  If none
have been defined by B<addUpdateCol>, then an empty list is returned.

=head2 B<generate>

This abstract method must be implemented by a subclass so that the
tables are added by L<"addTable(table)"> have been generated prior
to executing the L<"load"> method.

=head2 B<delete>

This re-implementable method deletes the database table contents prior
to loading the table.  The default action is to detele all database
table contents for all tables that will be loaded by this generator.

=head2 B<load>

This method loads the bcp-files for the table.

=head2 B<update>

This method updates the tables with the bcp-files.  If explicit update
columns have been specified, then these will be the columns used to
update the table, otherwise all value columns will be update.

=cut
