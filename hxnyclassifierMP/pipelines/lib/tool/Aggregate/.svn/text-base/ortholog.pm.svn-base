package tool::Aggregate::ortholog;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;
use FileHandle;

use util::Constants;
use util::Table;

use parallel::File::OutputFiles;

use base 'tool::Aggregate';

################################################################################
#
#                           Static Constants
#
################################################################################
###
### Local Properties
###
sub LOCAL_PROPERTIES { return []; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $utils, $error_mgr, $tools ) = @_;
  my tool::Aggregate::ortholog $this =
    $that->SUPER::new( 'ortholog', LOCAL_PROPERTIES, $utils, $error_mgr,
    $tools );

  return $this;
}

sub aggregateFile {
  my tool::Aggregate::ortholog $this = shift;
  my ($dataFile) = @_;

  $this->{error_mgr}->printMsg("Processing File");

  my $orthologFile =
    new parallel::File::OutputFiles( $dataFile, $this->{error_mgr} );
  my $status = $orthologFile->readFile;
  return $status if ($status);

  my $outputFile =
    new parallel::File::OutputFiles( $this->getOutputFile, $this->{error_mgr} );
  if ( -e $this->getOutputFile && !-z $this->getOutputFile ) {
    $status = $outputFile->readFile;
    return $status if ($status);
  }

  foreach my $familyName ( $orthologFile->getPrefixes ) {
    my $groupFile  = $orthologFile->getOutputFile($familyName);
    my $fileStatus = $orthologFile->getOutputFileStatus($familyName);
    ###
    ### Only those files that exist
    ###
    next if ( $fileStatus eq $orthologFile->FILE_NOT_EXISTS );
    $outputFile->addOutputFile( $familyName, $groupFile );
  }
  $status = $outputFile->writeFile( $this->getCompleted );
  return $status;
}

################################################################################

1;

__END__

=head1 NAME

ortholog.pm

=head1 DESCRIPTION

This concrete class class defines the aggregator for ortholog

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::Aggregate::ortholog(utils, error_mgr, tools)>

This is the constructor for the class.

=cut
