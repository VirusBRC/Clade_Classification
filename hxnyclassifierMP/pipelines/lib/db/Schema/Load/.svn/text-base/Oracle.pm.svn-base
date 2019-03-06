package db::Schema::Load::Oracle;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;

use base 'db::Schema::Load';

################################################################################
#
#				Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $table_info, $bcp_directory, $db, $error_mgr, @use_tables ) = @_;
  my db::Schema::Load::Oracle $this =
    $that->SUPER::new( $table_info, $bcp_directory, $db, $error_mgr,
    @use_tables );

  return $this;
}

sub getPosetQuery {
  my db::Schema::Load::Oracle $this = shift;
  ###
  ### Make sure the db connection is for oracle
  ###
  $this->_setStatus( $this->{db}->getServer ne 'OracleDB' );
  $this->_dieOnError( "Database server is not Oracle\n"
      . "  server = "
      . $this->{db}->getServer );
  my @tables      = $this->useTables;
  my $substitutor = util::Constants::EMPTY_STR;
  foreach my $index ( 0 .. $#tables ) {
    if ( $index > 0 ) { $substitutor .= util::Constants::COMMA_SEPARATOR; }
    $substitutor .=
        util::Constants::SINGLE_QUOTE
      . uc( $tables[$index] )
      . util::Constants::SINGLE_QUOTE;
  }
  return "
select c1.table_name,
       c2.table_name
from   all_constraints c1,
       all_constraints c2
where  c1.constraint_type = 'R'
and    c2.constraint_type = 'P'
and    c1.owner           = '" . $this->{db}->getSchemaOwner . "'
and    c2.owner           = c1.owner
and    c1.table_name     in ($substitutor)
and    c2.constraint_name = c1.r_constraint_name
and    c2.table_name     in ($substitutor)
";
}

################################################################################

1;

__END__

=head1 NAME

Oracle.pm

=head1 DESCRIPTION

The class defines the basic mechanism for loading a database schema for an
Oracle database from a set of bcp-files.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new db::Schema::Load::Oracle(table_info, bcp_directory, db, error_mgr, @use_tables)>

This is the constructor for the class.  The B<table_info> data-structure
describes the tables.

=head2 B<getPosetQuery>

This concrete method returns the query that will generate
the edges (table pairs) that defines the foreign key relationship as follows.
If the table pair (T1, T2) is returned, then T1 depends on T2 in a foreign
key relationship.

=cut
