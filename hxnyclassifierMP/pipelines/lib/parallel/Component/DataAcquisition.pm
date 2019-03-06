package parallel::Component::DataAcquisition;
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
  acquisition_type
  data_content
  data_dups_file
  data_files
  execution_directory
  family_names_file
  log_infix
  num_len
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Data Acquisition Specific Properties
###
sub DATACLASS_PROP       { return 'dataClass'; }
sub DATACONFIG_PROP      { return 'dataConfig'; }
sub DATADUPSFILE_PROP    { return 'dataDupsFile'; }
sub DATAFILEPREFIX_PROP  { return 'dataFilePrefix'; }
sub DATAFILES_PROP       { return 'dataFiles'; }
sub DATAOPTIONS_PROP     { return 'dataOptions'; }
sub DATAROOT_PROP        { return 'dataRoot'; }
sub DATASTATUSFILE_PROP  { return 'dataStatusFile'; }
sub DATATOOL_PROP        { return 'dataTool'; }
sub FAMILYNAMESFILE_PROP { return 'familyNamesFile'; }

sub DATA_ACQUISITION_PROPERTIES {
  return (
    DATACLASS_PROP,      DATACONFIG_PROP,     DATADUPSFILE_PROP,
    DATAFILEPREFIX_PROP, DATAFILES_PROP,      DATAOPTIONS_PROP,
    DATAROOT_PROP,       DATASTATUSFILE_PROP, DATATOOL_PROP,
    FAMILYNAMESFILE_PROP,
  );
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$$$) {
  my ( $that, $properties, $acquisition_type, $controller, $utils, $error_mgr,
    $tools )
    = @_;
  push( @{$properties}, DATA_ACQUISITION_PROPERTIES );
  my parallel::Component::DataAcquisition $this =
    $that->SUPER::new( $utils->DATAACQUISITION_COMP,
    $properties, $controller, $utils, $error_mgr, $tools );

  $this->{acquisition_type}    = $acquisition_type;
  $this->{data_content}        = undef;
  $this->{data_dups_file}      = undef;
  $this->{data_files}          = undef;
  $this->{execution_directory} = undef;
  $this->{family_names_file}   = undef;
  $this->{log_infix}           = undef;
  $this->{num_len}             = 4;

  return $this;
}

sub filterData {
  my parallel::Component::DataAcquisition $this = shift;
  my (@data) = @_;
  ###############################
  ### Re-implementable Method ###
  ###############################
  ###
  ### Default action is a pass-through
  ###
  return @data;
}

sub acquire_data {
  my parallel::Component::DataAcquisition $this = shift;
  #######################
  ### Abstract Method ###
  #######################
}

sub run {
  my parallel::Component::DataAcquisition $this = shift;

  my $controller = $this->getController;
  my $properties = $this->getProperties;
  my $tools      = $this->{tools};

  $this->{data_content}        = undef;
  $this->{data_dups_file}      = undef;
  $this->{data_files}          = undef;
  $this->{execution_directory} = undef;
  $this->{family_names_file}   = undef;
  $this->{log_infix}           = undef;
  $this->{status_file}         = undef;
  $this->{workspace_root}      = undef;

  $this->{data_files} = $properties->{dataFiles};
  if ( !$this->getRun ) {
    $this->setErrorStatus(
      $this->ERR_CAT,
      2,
      [ 'dataFiles', $this->{data_files} ],
      !-e $this->{data_files}
        || -z $this->{data_files}
        || !-r $this->{data_files}
    );
    return if ( $this->getErrorStatus );
    $this->{data_dups_file}    = $properties->{dataDupsFile};
    $this->{family_names_file} = $properties->{familyNamesFile};
  }
  else {
    $this->{workspace_root} = join( util::Constants::SLASH,
      getPath( $properties->{dataRoot} ),
      join( util::Constants::DOT,
        $properties->{datasetName},
        $controller->getRunVersion
      )
    );
    $tools->cmds->createDirectory( $this->getWorkspaceRoot,
      'creating data directory',
      util::Constants::TRUE );
    $this->{data_files} =
      join( util::Constants::SLASH, $this->getWorkspaceRoot, 'data.files' );
    $this->{data_dups_file} =
      join( util::Constants::SLASH, $this->getWorkspaceRoot, 'data.dups' );
    $this->{family_names_file} = join( util::Constants::SLASH,
      $this->getWorkspaceRoot, 'family.names.dat' );
    $this->{execution_directory} =
      join( util::Constants::SLASH, $this->getWorkspaceRoot, 'log' );
    $this->{status_file} = join( util::Constants::SLASH,
      $this->getWorkspaceRoot, $properties->{dataStatusFile} );
    $this->{log_infix} = $properties->{datasetName};

    $this->acquire_data;
    return if ( $this->getErrorStatus );
  }
  $this->{data_content} = new parallel::File::DataFiles( $this->getDataFiles );
  $this->setErrorStatus(
    $this->ERR_CAT, 2,
    [ 'dataFiles', $this->getDataFiles ],
    $this->{data_content}->readFile
  );
}

################################################################################
#
#                           Getter Methods
#
################################################################################

sub getLocalDataProperties {
  my parallel::Component::DataAcquisition $this = shift;
  my ($query_properties) = @_;

  my $properties = {};

  my ( $dataConfig, $loadingType, $loaded ) =
    $this->{tools}->newConfigParams( $this->getProperties->{dataConfig} );
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
  ###
  ### Get the properties specific to the query properties
  ###
  foreach my $property ( @{$query_properties} ) {
    $properties->{$property} = $dataConfig->getProperty($property);
  }

  return $properties;

}

sub generateFilePrefix {
  my parallel::Component::DataAcquisition $this = shift;
  my ($fileNum) = @_;

  my $flen       = length($fileNum);
  my $numInfix   = '0' x ( $this->{num_len} - $flen ) . $fileNum;
  my $properties = $this->getProperties;

  my @comps = ();
  foreach my $comp ( @{ $properties->{&DATAFILEPREFIX_PROP} } ) {
    my $val = $properties->{$comp};
    push( @comps, $val )  if ( !util::Constants::EMPTY_LINE($val) );
    push( @comps, $comp ) if ( util::Constants::EMPTY_LINE($val) );
  }
  push( @comps, $numInfix );
  return join( util::Constants::DOT, @comps );
}

sub getAcquisitionType {
  my parallel::Component::DataAcquisition $this = shift;
  return $this->{acquisition_type};
}

sub getDataFiles {
  my parallel::Component::DataAcquisition $this = shift;
  return $this->{data_files};
}

sub getDataContent {
  my parallel::Component::DataAcquisition $this = shift;
  return $this->{data_content};
}

sub getDataDupsFile {
  my parallel::Component::DataAcquisition $this = shift;
  return $this->{data_dups_file};
}

sub getFamilyNamesFile {
  my parallel::Component::DataAcquisition $this = shift;
  return $this->{family_names_file};
}

sub getExecutionDirectory {
  my parallel::Component::DataAcquisition $this = shift;
  return $this->{execution_directory};
}

sub getLogInfix {
  my parallel::Component::DataAcquisition $this = shift;
  return $this->{log_infix};
}

################################################################################

1;

__END__

=head1 NAME

DataAcquisition.pm

=head1 DESCRIPTION

This class defines the basics capabilities for the
data acquisition component.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::DataAcquisition(properties, acquisition_type, controller, error_mgr, tools)>

This is the constructor for the class.

=cut
