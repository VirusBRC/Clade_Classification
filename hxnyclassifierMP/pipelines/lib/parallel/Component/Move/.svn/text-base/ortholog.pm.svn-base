package parallel::Component::Move::ortholog;
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
### rate4site Specific Properties from the Controller Configuration
###
sub GROUPSSUFFIX_PROP  { return 'groupsSuffix'; }
sub ORTHOLOGFILES_PROP { return 'orthologFiles'; }

sub ORTHOLOG_PROPERTIES {
  return [ GROUPSSUFFIX_PROP, ORTHOLOGFILES_PROP, ];
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::Move::ortholog $this =
    $that->SUPER::new( ORTHOLOG_PROPERTIES, 'ortholog', $controller, $utils,
    $error_mgr, $tools );

  return $this;
}

sub move_data {
  my parallel::Component::Move::ortholog $this = shift;

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
  my $familyNames = {};
  foreach my $sourceDir ( @{ $properties->{sourceDirectories} } ) {
    my $resultFile = join( util::Constants::SLASH,
      $tools->setWorkspaceForProperty($sourceDir),
      $this->makeFile
    );
    $this->{error_mgr}->printHeader( "Determining ortholog files to copy over\n"
        . "Result File = $resultFile" );
    my $familyFiles =
      new parallel::File::OutputFiles( $resultFile, $this->{error_mgr} );
    $familyFiles->readFile;
    return if ( !$familyFiles->getCompleted );
    foreach my $familyName ( $familyFiles->getPrefixes ) {
      my $fileStatus    = $familyFiles->getOutputFileStatus($familyName);
      my $groupsFile    = $familyFiles->getOutputFile($familyName);
      next if ( $fileStatus eq $familyFiles->FILE_NOT_EXISTS );
      $familyNames->{$familyName} = $familyName;
      my $destination = join( util::Constants::SLASH,
        $this->getWorkspaceRoot,
        join( util::Constants::DOT, $familyName, $groupsSuffix ) );
      $this->{error_mgr}->printHeader( "Copying Groups File\n"
          . "  groupsFile  = $groupsFile\n"
          . "  destination = $destination" );
      $msgs->{cmd} = $cmds->COPY_FILE( $groupsFile, $destination );
      $cmds->executeCommand( $msgs, $msgs->{cmd},
        'copying family $groupsSuffix to workspace' );

      foreach my $suffix ( @{$orthologFiles} ) {
        my $source = join( util::Constants::DOT, $groupsFile, $suffix );
        my $destination = join( util::Constants::SLASH,
          $this->getWorkspaceRoot,
          join( util::Constants::DOT, $familyName, $suffix ) );
        $this->{error_mgr}->printMsg( "Copying $suffix File\n"
            . "  source      = $source\n"
            . "  destination = $destination" );
        $msgs->{cmd} = $cmds->COPY_FILE( $source, $destination );
        $cmds->executeCommand( $msgs, $msgs->{cmd},
          'copying family $suffix to workspace' );
      }
    }
  }

  chdir( $this->getWorkspaceRoot );
  $this->createRemoteDirectory;
  foreach my $familyName ( keys %{$familyNames} ) {
    my $pattern = $familyName . '.*';
    $msgs->{cmd} = "scp $pattern $server:$destinationDirectory";
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'moving result files' );
  }
}

################################################################################

1;

__END__

=head1 NAME

ortholog.pm

=head1 DESCRIPTION

This class defines the mechanism for moving ortholog data from run results.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::Move::ortholog(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
