package parallel::Component::Move::fomaSNP;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'chdir';
use File::Basename;
use Pod::Usage;

use util::Constants;

use parallel::File::OutputFiles;

use base 'parallel::Component::Move';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### foma SNP Properties
###
sub FOMASNP_PROPERTIES { return []; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::Move::fomaSNP $this =
    $that->SUPER::new( FOMASNP_PROPERTIES, 'fomaSNP', $controller, $utils,
    $error_mgr, $tools );

  return $this;
}

sub move_data {
  my parallel::Component::Move::fomaSNP $this = shift;

  my $tools      = $this->{tools};
  my $cmds       = $tools->cmds;
  my $properties = $this->getProperties;
  ###
  ### Setup remote information
  ###
  my $server               = $this->getDestinationServer;
  my $destinationDirectory = $this->getDestinationDirectory;
  my $groupsSuffix         = $properties->{groupsSuffix};
  my $orthologFiles        = $properties->{orthologFiles};

  my $msgs = {};
  $this->generateComponents;
  $this->createRemoteDirectory;
  foreach my $sourceDir ( @{ $properties->{sourceDirectories} } ) {
    $sourceDir = $tools->setWorkspaceForProperty($sourceDir);
    chdir($sourceDir);
    my $resultFile = $this->makeFile;
    $this->{error_mgr}->printHeader( "Determining fomaSNP files to copy over\n"
        . "Source Directory = $sourceDir\n"
        . "Result File      = $resultFile" );
    my $files =
      new parallel::File::OutputFiles( $resultFile, $this->{error_mgr} );
    $files->readFile;
    return if ( !$files->getCompleted );
    foreach my $prefix ( $files->getPrefixes ) {
      my $fileStatus = $files->getOutputFileStatus($prefix);
      my $file       = $files->getOutputFile($prefix);
      next if ( $fileStatus eq $files->FILE_NOT_EXISTS );
      $msgs->{cmd} = "scp $file $server:$destinationDirectory";
      $cmds->executeCommand( $msgs, $msgs->{cmd}, "moving result file $file" );
    }
  }
}

################################################################################

1;

__END__

=head1 NAME

fomaSNP.pm

=head1 DESCRIPTION

This class defines the mechanism for moving fomaSNP files to shared file system.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::Move::fomaSNP(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
