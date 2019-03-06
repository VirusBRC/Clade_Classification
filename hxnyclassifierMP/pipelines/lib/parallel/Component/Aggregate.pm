package parallel::Component::Aggregate;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::ConfigParams;
use util::Constants;

use base 'parallel::Component';

use fields qw(
  config_params
  aggregate_type
  output_files
  output_files_lock
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Aggregation Standard Properties
###
sub AGGREGATECLASS_PROP              { return 'aggregateClass'; }
sub AGGREGATECONFIG_PROP             { return 'aggregateConfig'; }
sub AGGREGATEDELETESUFFIX_PROP       { return 'aggregateDeleteSuffix'; }
sub AGGREGATEFILE_PROP               { return 'aggregateFile'; }
sub AGGREGATEOPTIONS_PROP            { return 'aggregateOptions'; }
sub AGGREGATEOPTIONREPLACEMENTS_PROP { return 'aggregateOptionReplacements'; }
sub AGGREGATEOPTIONVALS_PROP         { return 'aggregateOptionVals'; }
sub AGGREGATESLEEP_PROP              { return 'aggregateSleep'; }
sub AGGREGATESTATUSFILE_PROP         { return 'aggregateStatusFile'; }
sub AGGREGATESUFFIX_PROP             { return 'aggregateSuffix'; }
sub AGGREGATETOOL_PROP               { return 'aggregateTool'; }
sub OUTPUTFILESLOCK_PROP             { return 'outputFilesLock'; }
sub OUTPUTFILESNAME_PROP             { return 'outputFilesName'; }
sub OUTPUTFILESUFFIX_PROP            { return 'outputFileSuffix'; }
sub OUTPUTFILES_PROP                 { return 'outputFiles'; }
sub TOOLRUNDIRECTORY_PROP            { return 'toolRunDirectory'; }

sub AGGREGATE_PROPERTIES {
  return (
    AGGREGATECLASS_PROP,              AGGREGATECONFIG_PROP,
    AGGREGATEDELETESUFFIX_PROP,       AGGREGATEFILE_PROP,
    AGGREGATEOPTIONS_PROP,            AGGREGATESLEEP_PROP,
    AGGREGATESTATUSFILE_PROP,         AGGREGATESUFFIX_PROP,
    AGGREGATETOOL_PROP,               OUTPUTFILESLOCK_PROP,
    OUTPUTFILESNAME_PROP,             OUTPUTFILES_PROP,
    TOOLRUNDIRECTORY_PROP,            OUTPUTFILESUFFIX_PROP,
    AGGREGATEOPTIONREPLACEMENTS_PROP, AGGREGATEOPTIONVALS_PROP
  );
}

################################################################################
#
#			            Private Methods
#
################################################################################

sub _launchAggregator {
  my parallel::Component::Aggregate $this = shift;
  my ($propertiesFile) = @_;

  my $config     = $this->getConfigParams;
  my $controller = $this->getController;
  my $properties = $this->getProperties;
  ###
  ### Launch the job into background
  ###
  my $cmd = $this->{utils}->getRunToolCmd(
    $properties->{runTool},
    $propertiesFile,
    $this->getWorkspaceRoot,
    join( util::Constants::DOT,
      $this->getComponentType, $this->getAggregateType
    )
  );
  my $pid = $controller->getJobs->forkProcess($cmd);
  $this->{error_mgr}->printHeader("Started Aggregator\n  pid = $pid");
  $this->setErrorStatus( $this->ERR_CAT, 3,
    [ $this->getComponentType, $this->getAggregateType ], !$pid );
  return if ( $this->getErrorStatus );
  $this->setPidInfo(
    $pid,
    cmd             => $cmd,
    component_type  => $this->getComponentType,
    data_file       => $config->getProperty('dataFile'),
    err_file        => $config->getProperty('errFile'),
    output_file     => $config->getProperty('outputFile'),
    properties_file => $propertiesFile,
    status_file     => $config->getProperty('statusFile'),
    std_file        => $config->getProperty('stdFile'),
    workspace_root  => $this->getWorkspaceRoot
  );

  $this->{curr_pids} = [$pid];
  $this->{last_job}  = 0;
  $this->{next_job}  = 1;
  $this->{num_jobs}  = 1;
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$$$) {
  my ( $that, $properties, $aggregate_type, $controller, $utils, $error_mgr,
    $tools )
    = @_;
  push( @{$properties}, AGGREGATE_PROPERTIES );
  my parallel::Component::Aggregate $this =
    $that->SUPER::new( $utils->AGGREGATE_COMP, $properties, $controller, $utils,
    $error_mgr, $tools );

  $this->{aggregate_type}    = $aggregate_type;
  $this->{config_params}     = new util::ConfigParams( $this->{error_mgr} );
  $this->{output_files}      = undef;
  $this->{output_files_lock} = undef;
  $this->{workspace_root}    = $controller->getWorkspaceRoot;

  $this->{status_file} = join( util::Constants::SLASH,
    $controller->getWorkspaceRoot,
    $this->getProperties->{aggregateStatusFile}
  );

  return $this;
}

sub setConfig {
  my parallel::Component::Aggregate $this = shift;

  ###############################
  ### Re-Implementable Method ###
  ###############################
  ###
  ### NO-OP
  ###
}

sub run {
  my parallel::Component::Aggregate $this = shift;

  my $config     = $this->getConfigParams;
  my $controller = $this->getController;
  my $properties = $this->getProperties;
  my $tools      = $this->{tools};
  my $utils      = $this->{utils};
  ###
  ### Initialize Pid Information
  ###
  $this->{completed} = 0;
  $this->{curr_pids} = [];
  $this->{num_jobs}  = 0;
  $this->{pids}      = {};
  ###
  ### Determine Output Files
  ###
  $this->{output_files} = $properties->{outputFiles};
  if ( util::Constants::EMPTY_LINE( $this->{output_files} ) ) {
    $this->{output_files} = join( util::Constants::SLASH,
      $this->getWorkspaceRoot, $properties->{outputFilesName} );
  }
  my $tcmd = $tools->cmds->TOUCH_CMD( $this->{output_files} );
  my $msgs = { cmd => $tcmd, };
  $tools->cmds->executeCommand( $msgs, $tcmd, 'touch output files file' );

  $this->{output_files_lock} = join( util::Constants::SLASH,
    $this->getWorkspaceRoot, $properties->{outputFilesLock} );
  ###
  ### Return if not running aggregation
  ###
  return if ( !$this->getRun );
  ###
  ### Get the configuration parameters
  ###
  $config->configModule( $properties->{aggregateConfig} );
  ###
  ### Set the configuration parameters
  ###
  my @aggregateFileComps = ();
  foreach my $comp ( @{ $properties->{aggregateFile} } ) {
    if ( defined( $properties->{$comp} ) ) {
      push( @aggregateFileComps, $properties->{$comp} );
    }
    else {
      push( @aggregateFileComps, $comp );
    }
  }
  my $outputFile = join( util::Constants::SLASH,
    $this->getWorkspaceRoot,
    join( util::Constants::DOT, @aggregateFileComps ) );

  my $errFile = join( util::Constants::SLASH,
    $this->getWorkspaceRoot,
    join( util::Constants::DOT,
      $this->getComponentType, $this->getAggregateType,
      $utils->ERR_OUTPUT_SUFFIX
    )
  );
  my $stdFile = join( util::Constants::SLASH,
    $this->getWorkspaceRoot,
    join( util::Constants::DOT,
      $this->getComponentType, $this->getAggregateType,
      $utils->STD_OUTPUT_SUFFIX
    )
  );
  my $logInfix = join( util::Constants::DOT,
    $this->getComponentType, $this->getAggregateType );

  $config->setProperty( 'aggregateDeleteSuffix',
    $properties->{aggregateDeleteSuffix} );
  $config->setProperty( 'aggregateSuffix',    $properties->{aggregateSuffix} );
  $config->setProperty( 'dataFile',           $this->getOutputFiles );
  $config->setProperty( 'dataFileLock',       $this->getOutputFilesLock );
  $config->setProperty( 'errFile',            $errFile );
  $config->setProperty( 'executionDirectory', $this->getWorkspaceRoot );
  $config->setProperty( 'logInfix',           $logInfix );
  $config->setProperty( 'outputFile',         $outputFile );
  $config->setProperty( 'sleepInterval',      $properties->{aggregateSleep} );
  $config->setProperty( 'statusFile',         $this->getStatusFile );
  $config->setProperty( 'stdFile',            $stdFile );
  $config->setProperty( 'toolClass',          $properties->{aggregateClass} );
  $config->setProperty( 'toolName',           $properties->{aggregateTool} );
  $config->setProperty( 'toolOptions',        $properties->{aggregateOptions} );
  $config->setProperty( 'toolOptionVals', $properties->{aggregateOptionVals} );
  $config->setProperty( 'toolOptionReplacements',
    $properties->{aggregateOptionReplacements} );
  $config->setProperty( 'toolRunDirectory', $properties->{toolRunDirectory} );
  $config->setProperty( 'workspaceRoot',    $this->getWorkspaceRoot );
  $config->setProperty( 'outputFileSuffix', $properties->{outputFileSuffix} );
  ###
  ### Specific configuration requirements
  ###
  $this->setConfig;
  ###
  ### Start the aggregator
  ###
  my $propertiesFile = join( util::Constants::SLASH,
    $this->getWorkspaceRoot,
    join( util::Constants::DOT,
      $properties->{aggregateConfig},
      $tools->PROPERTIES
    )
  );
  $config->storeFile($propertiesFile);
  $this->_launchAggregator($propertiesFile);
}

sub completeJob {
  my parallel::Component::Aggregate $this = shift;
  my ($pid) = @_;
  ###
  ### Also report any errors in the tool err file!
  ### Load the error file into the log
  ###
  my $status = $this->getPidInfo($pid)->printJobInfo;
  $this->writeErrorFile($pid) if ($status);
}

################################################################################
#
#                           Getter Methods
#
################################################################################

sub getConfigParams {
  my parallel::Component::Aggregate $this = shift;
  return $this->{config_params};
}

sub getOutputFiles {
  my parallel::Component::Aggregate $this = shift;
  return $this->{output_files};
}

sub getOutputFilesLock {
  my parallel::Component::Aggregate $this = shift;
  return $this->{output_files_lock};
}

sub getAggregateType {
  my parallel::Component::Aggregate $this = shift;
  return $this->{aggregate_type};
}

################################################################################

1;

__END__

=head1 NAME

Aggregate.pm

=head1 DESCRIPTION

This class defines the basics capabilities of the aggregation
component.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::Aggregate(properties, aggregate_type,  controller, error_mgr, tools)>

This is the constructor for the class.

=cut
