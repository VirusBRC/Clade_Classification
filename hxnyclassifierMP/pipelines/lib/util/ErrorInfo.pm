package util::ErrorInfo;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;

use base "util::TableData";

use fields qw (
  err_cat
);

################################################################################
#
#				Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $infix, $err_cat, $tools, $error_mgr ) = @_;
  my util::ErrorInfo $this = $that->SUPER::new( $infix, $tools, $error_mgr );

  $this->{err_cat} = $err_cat;

  return $this;
}

sub addErrorInfo {
  my util::ErrorInfo $this = shift;
  my ( $error_type, $error, $err_num, $datum ) = @_;

  return if ( !$error );
  $this->{error_mgr}
    ->registerError( $this->{err_cat}, $err_num, $datum, $error );
  $this->addTableRow( $error_type, $datum );
}

sub writeErrorInfo {
  my util::ErrorInfo $this = shift;

  foreach my $error_type ( $this->tableTypes ) {
    my $data = $this->getTableInfo($error_type);
    next if ( scalar @{$data} == 0 );
    my $file_comps = [ $this->infix, 'error', $error_type, ];
    $this->generateTableFile(
      $this->getOrd($error_type),
      $this->getSortOrd($error_type),
      $file_comps, $data
    );
  }
}

################################################################################

1;

__END__

=head1 NAME

ErrorInfo.pm

=head1 DESCRIPTION

This concrete manages the error information reported and accumulated
by a class for later writing to a file and/or reading from a
file. This class is a sub-class of L<util::TableData>.

=head1 CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new util::ErrorInfo(infix, err_cat, tools, error_mgr)>

This is the constructor for the class. B<infix> is provided to the
parent class defining the set of tab-separated files managed by this
object, while B<err_cat> is used by this class for registering errors
to the B<error_mgr>.

=head2 B<addErrorInfo(error_type, $error, $err_num, $datum)>

This method registers and error to B<error_mgr> if B<error> is TRUE
(1), using the B<err_num> and the B<datum> (referenced Perl array of
information for the error table).  Also, if B<error> is TRUE (1), then
a row is added to the table B<error_type> using the B<datum>.

=head2 B<writeErrorInfo>

This method writes all the error tables for the object using the
following file name for the error file of B<error_type>:

   <execution_dir>/<tool_prefix>.<log_infix>.<infix>.<error>.<error_type>.xls

=cut
