package tool::Aggregate::rate4site;
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

use parallel::File::Rate4Site;

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
  my tool::Aggregate::rate4site $this =
    $that->SUPER::new( 'rate4site', LOCAL_PROPERTIES, $utils, $error_mgr,
    $tools );

  return $this;
}

sub aggregateFile {
  my tool::Aggregate::rate4site $this = shift;
  my ($dataFile) = @_;

  $this->{error_mgr}->printMsg("Processing File");

  my $r4sFile = new parallel::File::Rate4Site( $dataFile, $this->{error_mgr} );
  my $status = $r4sFile->readFile;
  return if ($status);

  my $fh = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $this->getOutputFile, '>>' ) );

  foreach my $pdb ( $r4sFile->getPdbs ) {
    my ( $file, $file_status ) = $r4sFile->getRate4SiteFile($pdb);
    my ( $full, $full_status ) = $r4sFile->getRate4SiteFullFile($pdb);
    ###
    ### Only those with both non-zero rate4site files
    ###
    next
      if ( $file_status eq $r4sFile->FILE_NOT_EXISTS
      || $full_status eq $r4sFile->FILE_NOT_EXISTS );
    $fh->print(
      join( util::Constants::TAB,
        $pdb, $file, $file_status, $full, $full_status )
        . util::Constants::NEWLINE
    );
  }
  $fh->close;
  return util::Constants::FALSE;
}

################################################################################

1;

__END__

=head1 NAME

rate4site.pm

=head1 DESCRIPTION

This concrete class class defines the aggregator for rate4site

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::Aggregate::rate4site(utils, error_mgr, tools)>

This is the constructor for the class.

=cut
