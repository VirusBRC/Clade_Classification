package parallel::Component::Preprocess;
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

use parallel::File::DataFiles;

use base 'parallel::Component';

use fields qw(
  preprocess_type
  execution_directory
  log_infix
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Data Preprocess Specific Properties
###
sub PREPROCESSCLASS_PROP      { return 'preprocessClass'; }
sub PREPROCESSCONFIG_PROP     { return 'preprocessConfig'; }
sub PREPROCESSOPTIONREPLACEMENTS_PROP {return 'preprocessOptionReplacements'; }
sub PREPROCESSOPTIONS_PROP    { return 'preprocessOptions'; }
sub PREPROCESSOPTIONVALS_PROP {return 'preprocessOptionVals'; }
sub PREPROCESSROOT_PROP       { return 'preprocessRoot'; }
sub PREPROCESSSTATUSFILE_PROP { return 'preprocessStatusFile'; }
sub PREPROCESSTOOL_PROP       { return 'preprocessTool'; }

sub PREPROCESS_PROPERTIES {
  return (
    PREPROCESSCLASS_PROP,      PREPROCESSCONFIG_PROP,
    PREPROCESSOPTIONS_PROP,    PREPROCESSROOT_PROP,
    PREPROCESSSTATUSFILE_PROP, PREPROCESSTOOL_PROP,
    PREPROCESSOPTIONREPLACEMENTS_PROP,
    PREPROCESSOPTIONVALS_PROP
  );
}

################################################################################
#
#				Private Methods
#
################################################################################

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$$$) {
  my ( $that, $properties, $preprocess_type, $controller, $utils, $error_mgr,
    $tools )
    = @_;
  push( @{$properties}, PREPROCESS_PROPERTIES );
  my parallel::Component::Preprocess $this =
    $that->SUPER::new( $utils->PREPROCESS_COMP,
    $properties, $controller, $utils, $error_mgr, $tools );

  $this->{preprocess_type}     = $preprocess_type;
  $this->{execution_directory} = undef;
  $this->{log_infix}           = undef;

  return $this;
}

sub preprocess_data {
  my parallel::Component::Preprocess $this = shift;
  #######################
  ### Abstract Method ###
  #######################
}

sub run {
  my parallel::Component::Preprocess $this = shift;

  $this->{execution_directory} = undef;
  $this->{log_infix}           = undef;
  $this->{status_file}         = undef;
  $this->{workspace_root}      = undef;

  return if ( !$this->getRun );

  my $controller = $this->getController;
  my $properties = $this->getProperties;
  my $tools      = $this->{tools};

  $this->{workspace_root} = join( util::Constants::SLASH,
    $properties->{workspaceRoot},
    join( util::Constants::DOT,
      $properties->{preprocessRoot},
      $controller->getRunVersion
    )
  );
  $tools->cmds->createDirectory( $this->getWorkspaceRoot,
    'creating preprocess directory',
    util::Constants::TRUE );
  $this->{execution_directory} =
    join( util::Constants::SLASH, $this->getWorkspaceRoot, 'log' );
  $this->{status_file} = join( util::Constants::SLASH,
    $this->getWorkspaceRoot, $properties->{preprocessStatusFile} );
  $this->{log_infix} = $properties->{datasetName};

  $this->preprocess_data;
}

################################################################################
#
#                           Getter Methods
#
################################################################################

sub getLocalDataProperties {
  my parallel::Component::Preprocess $this = shift;

  my $properties = {};

  my ( $dataConfig, $loadingType, $loaded ) =
    $this->{tools}->newConfigParams( $this->getProperties->{preprocessConfig} );
  ###
  ### Get the properties specific class
  ###
  foreach my $property ( $this->getLocalProperties ) {
    my $val = $this->getProperties->{$property};
    if ( util::Constants::EMPTY_LINE($val) ) {
      $val = $dataConfig->getProperty($property);
    }
    $properties->{$property} = $val;
  }

  return $properties;

}

sub getPreprocessType {
  my parallel::Component::Preprocess $this = shift;
  return $this->{preprocess_type};
}

sub getExecutionDirectory {
  my parallel::Component::Preprocess $this = shift;
  return $this->{execution_directory};
}

sub getLogInfix {
  my parallel::Component::Preprocess $this = shift;
  return $this->{log_infix};
}

################################################################################

1;

__END__

=head1 NAME

Preprocess.pm

=head1 DESCRIPTION

This class defines the basics capabilities of preprocessing prior
to data acquisition.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::Preprocess(properties, preprocess_type, controller, error_mgr, tools)>

This is the constructor for the class.

=cut
