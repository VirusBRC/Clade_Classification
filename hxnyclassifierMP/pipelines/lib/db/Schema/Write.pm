package db::Schema::Write;
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

use base 'db::Schema';

################################################################################
#
#				Private Methods
#
################################################################################

sub _selectCmd {
  my db::Schema::Write $this = shift;
  my ( $tableName, $colOrd, $orderOrd ) = @_;
  my @params = ();
  foreach ( @{$colOrd} ) { push( @params, '?' ); }
  my $cmd = "
select   " . join( util::Constants::COMMA_SEPARATOR, @{$colOrd} ) . "
from     $tableName
";
  if ( @{$orderOrd} > 0 ) {
    $cmd .= "
order by " . join( util::Constants::COMMA_SEPARATOR, @{$orderOrd} ) . "
";
  }
  return $cmd;
}

################################################################################
#
#				Public Methods
#
################################################################################

sub new($$$) {
  my ( $that, $table_info, $bcp_directory, $error_mgr ) = @_;
  my db::Schema::Write $this =
    $that->SUPER::new( $table_info, $bcp_directory, $error_mgr );

  return $this;
}

sub generate {
  my db::Schema::Write $this = shift;
  my ($db)                   = @_;
  my $db_queries             = new util::DbQuery($db);
  $this->{error_mgr}->printHeader("Generating Bcp Files");
  foreach my $file ( $this->files ) {
    my $ord       = [ $this->getColumnOrder($file) ];
    my $order_ord = [ $this->getOrderOrd($file) ];
    $this->{error_mgr}->printMsg("Table = $file");
    my $bcp_file = join( util::Constants::SLASH,
      $this->{bcp_directory},
      join( util::Constants::DOT, $file, $this->BCP_TYPE )
    );
    my $fh = new FileHandle;
    $this->_setStatus( !$fh->open( $bcp_file, '>' ) );
    $this->_dieOnError(
      "Cannot open bcp-file for writing\n" . "  bcp_file = $bcp_file" );
    my $query_name = "select_$file";
    $db_queries->doQuery( $query_name,
      $this->_selectCmd( $file, $ord, $order_ord ),
      "Get $file" );
    my $print_rseparator = util::Constants::FALSE;
    my $fseparator       = $this->getFieldSeparator($file);
    my $rseparator       = $this->getRecordSeparator($file);

    while ( my $row_ref = $db_queries->fetchRowRef($query_name) ) {
      if   ($print_rseparator) { $fh->print($rseparator); }
      else                     { $print_rseparator = util::Constants::TRUE; }
      $fh->print( join( $fseparator, @{$row_ref} ) );
    }
    $fh->close;
  }
}

################################################################################

1;

__END__

=head1 NAME

Write.pm

=head1 DESCRIPTION

The class defines the basic mechanism for generating a set of bcp-files
from a database schema.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new db::Schema::Write(table_info, bcp_directory, error_mgr)>

This is the constructor for the class.  The table_type is either B<'data'>
or B<'meta'>.

=head2 B<generate(db)>

This method generates the set of bcp-files from the database B<db> and
writes them to the bcp-directory.

=cut
