package db::Schema::Load::MySql;
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
  my db::Schema::Load::MySql $this =
    $that->SUPER::new( $table_info, $bcp_directory, $db, $error_mgr,
    @use_tables );

  return $this;
}

sub getPosetQuery {
  my db::Schema::Load::MySql $this = shift;
  ###
  ### Make sure the db connection is for oracle
  ###
  $this->_setStatus( $this->{db}->getServer ne 'mySQL' );
  $this->_dieOnError(
    "Database server is not MySQL\n" . "  server = " . $this->{db}->getServer );

  my @tables      = $this->useTables;
  my $substitutor = util::Constants::EMPTY_STR;
  foreach my $index ( 0 .. $#tables ) {
    if ( $index > 0 ) { $substitutor .= util::Constants::COMMA_SEPARATOR; }
    $substitutor .=
        util::Constants::SINGLE_QUOTE
      . $tables[$index]
      . util::Constants::SINGLE_QUOTE;
  }
  return "
select kcu.table_name,
       kcu.referenced_table_name
from   information_schema.table_constraints tc,
       information_schema.key_column_usage kcu
where  kcu.table_schema     = '" . $this->{db}->getSchemaOwner . "'
and    kcu.table_schema     = kcu.referenced_table_schema
and    kcu.table_schema     = tc.table_schema
and    kcu.table_schema     = tc.constraint_schema
and    kcu.table_name      <> kcu.referenced_table_name
and    kcu.constraint_name  = tc.constraint_name
and    tc.constraint_type   = 'FOREIGN KEY'
and    kcu.table_name      in ($substitutor)
and    tc.table_name       in ($substitutor)
";
}

################################################################################

1;

__END__

=head1 NAME

Oracle.pm

=head1 DESCRIPTION

The class defines the basic mechanism for loading a database schema for an
MySQL data as follows:

B<TBD TBD TBD>base from a set of bcp-files.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new db::Schema::Load::MySql(table_info, bcp_directory, db, error_mgr, @use_tables)>

This is the constructor for the class.  The B<table_info> data-structure
describes the tables.

=head2 B<getPosetQuery>

This concrete method returns the query that will generate
the edges (table pairs) that defines the foreign key relationship as follows.
If the table pair (T1, T2) is returned, then T1 depends on T2 in a foreign
key relationship.

=cut
