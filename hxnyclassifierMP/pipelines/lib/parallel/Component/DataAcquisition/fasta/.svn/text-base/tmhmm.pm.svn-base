package parallel::Component::DataAcquisition::fasta::tmhmm;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use base 'parallel::Component::DataAcquisition::fasta';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Amino Acids NOT Allowed by tmhmm
###
sub GOOD_AMINO_ACIDS_PATTERN {
  return '^[ACDEFGHIKLMNPQRSTVWYBXZacdefghiklmnpqrstvwybxz]+$';
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::DataAcquisition::fasta::tmhmm $this =
    $that->SUPER::new( $controller, $utils, $error_mgr, $tools );

  return $this;
}

sub filterData {
  my parallel::Component::DataAcquisition::fasta::tmhmm $this = shift;
  my (@data) = @_;

  my @new_data = ();

  my $properties = $this->getLocalDataProperties( $this->QUERY_PROPERTIES );
  my $queryId    = $properties->{ $this->QUERYID_PROP };
  my $querySeq   = $properties->{ $this->QUERYSEQ_PROP };

  my $good_amino_acids_pattern = GOOD_AMINO_ACIDS_PATTERN;
  foreach my $struct (@data) {
    my $id  = $struct->{$queryId};
    my $seq = $struct->{$querySeq};

    if ( $seq !~ /$good_amino_acids_pattern/ ) {
      $this->{error_mgr}->printMsg(
        "seq = $id has bad amino acid(s) in it(not $good_amino_acids_pattern)");
      next;
    }
    push( @new_data, $struct );
  }

  return @new_data;
}

################################################################################

1;

__END__

=head1 NAME

tmhmm.pm

=head1 DESCRIPTION

This class defines the fasta data acquisition component for tmhmm tool

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::DataAcquisition::fasta::tmhmm(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
