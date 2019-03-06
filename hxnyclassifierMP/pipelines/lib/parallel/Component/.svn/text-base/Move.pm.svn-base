package parallel::Component::Move;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use base 'parallel::Component';

use fields qw(
  move_type
  execution_directory
  file_comps
  log_infix
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Data Move Specific Properties
###
sub AGGREGATEDELETESUFFIX_PROP  { return 'aggregateDeleteSuffix'; }
sub AGGREGATEFILE_PROP          { return 'aggregateFile'; }
sub AGGREGATESUFFIX_PROP        { return 'aggregateSuffix'; }
sub DESTINATION_PROP            { return 'destination'; }
sub MOVESTATUSFILE_PROP         { return 'moveStatusFile'; }
sub SOURCEDIRECTORIES_PROP      { return 'sourceDirectories'; }
sub TOOLNAME_PROP               { return 'toolName'; }
sub TOOLOPTIONREPLACEMENTS_PROP { return 'toolOptionReplacements'; }
sub TOOLOPTIONS_PROP            { return 'toolOptions'; }
sub TOOLOPTIONVALS_PROP         { return 'toolOptionVals'; }

sub MOVE_PROPERTIES {
  return (
    AGGREGATEDELETESUFFIX_PROP, AGGREGATEFILE_PROP,
    AGGREGATESUFFIX_PROP,       DESTINATION_PROP,
    MOVESTATUSFILE_PROP,        SOURCEDIRECTORIES_PROP,
    TOOLNAME_PROP,              TOOLOPTIONREPLACEMENTS_PROP,
    TOOLOPTIONS_PROP,           TOOLOPTIONVALS_PROP
  );
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$$$) {
  my ( $that, $properties, $move_type, $controller, $utils, $error_mgr, $tools )
    = @_;
  push( @{$properties}, MOVE_PROPERTIES );
  my parallel::Component::Move $this =
    $that->SUPER::new( $utils->MOVE_COMP, $properties, $controller, $utils,
    $error_mgr, $tools );

  $this->{execution_directory} = undef;
  $this->{file_comps}          = [];
  $this->{log_infix}           = undef;
  $this->{move_type}           = $move_type;

  return $this;
}

sub move_data {
  my parallel::Component::Move $this = shift;
  #######################
  ### Abstract Method ###
  #######################
}

sub run {
  my parallel::Component::Move $this = shift;

  $this->{execution_directory} = undef;
  $this->{log_infix}           = undef;
  $this->{status_file}         = undef;
  $this->{workspace_root}      = undef;

  return if ( !$this->getRun );

  my $controller = $this->getController;
  my $properties = $this->getProperties;
  my $tools      = $this->{tools};

  $this->{workspace_root}      = $controller->getWorkspaceRoot;
  $this->{execution_directory} = $properties->{executionDirectory};
  $this->{status_file}         = join( util::Constants::SLASH,
    $controller->getWorkspaceRoot, $properties->{moveStatusFile} );
  $this->{log_infix} = $properties->{datasetName};

  $this->move_data;
}

sub generateComponents {
  my parallel::Component::Move $this = shift;

  my $properties = $this->getProperties;

  $this->{file_comps} = [];
  foreach my $comp ( @{ $properties->{aggregateFile} } ) {
    my $val = $properties->{$comp};
    if ( util::Constants::EMPTY_LINE($val) ) { $val = $comp; }
    push( @{ $this->{file_comps} }, $val );
  }
}

sub createRemoteDirectory {
  my parallel::Component::Move $this = shift;

  my $cmds        = $this->{tools}->cmds;
  my $destination = $this->getProperties->{destination};

  my $server         = $this->getDestinationServer;
  my $destinationDir = $this->getDestinationDirectory;

  my $msgs = {};
  $msgs->{cmd} = "ssh $server '/bin/mkdir -m 777 -p $destinationDir'";
  $cmds->executeCommand( $msgs, $msgs->{cmd},
    'create destination directory, as necessary' );
}

################################################################################
#
#                           Getter Methods
#
################################################################################

sub getMoveType {
  my parallel::Component::Move $this = shift;
  return $this->{move_type};
}

sub getExecutionDirectory {
  my parallel::Component::Move $this = shift;
  return $this->{execution_directory};
}

sub getLogInfix {
  my parallel::Component::Move $this = shift;
  return $this->{log_infix};
}

sub getDestinationServer {
  my parallel::Component::Move $this = shift;
  my $destination = $this->getProperties->{destination};
  return $destination->{userName} . '@' . $destination->{server};
}

sub getDestinationDirectory {
  my parallel::Component::Move $this = shift;
  my $destination = $this->getProperties->{destination};
  return join( util::Constants::SLASH,
    $destination->{rootDirectory},
    $destination->{releaseName},
    $destination->{directoryName}
  );
}

sub makeFile {
  my parallel::Component::Move $this = shift;
  return join( util::Constants::DOT, @{ $this->{file_comps} } );
}

sub makeFilePattern {
  my parallel::Component::Move $this = shift;
  return join( '\.', @{ $this->{file_comps} } );
}

sub makeSshPattern {
  my parallel::Component::Move $this = shift;
  my $pattern = join( util::Constants::DOT, @{ $this->{file_comps} } );
  $pattern =~ s/\.\+/\*/g;
  $pattern =~ s/\.\*/\*/g;
  return $pattern;
}

################################################################################

1;

__END__

=head1 NAME

Move.pm

=head1 DESCRIPTION

This class defines the basics capabilities of moving run results.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::Move(properties, preprocess_type, controller, error_mgr, tools)>

This is the constructor for the class.

=cut
