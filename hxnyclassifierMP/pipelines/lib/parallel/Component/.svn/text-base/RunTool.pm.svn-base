package parallel::Component::RunTool;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'chdir';
use Pod::Usage;

use util::ConfigParams;
use util::Constants;

use parallel::File::DataFiles;
use parallel::File::OutputFiles;
use parallel::Lock;

use base 'parallel::Component';

use fields qw(
  data_files
  output_files
  output_files_lock
  run_type
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Run Tool Properties
###
sub TOOLCLASS_PROP              { return 'toolClass'; }
sub TOOLCONFIG_PROP             { return 'toolConfig'; }
sub TOOLNAME_PROP               { return 'toolName'; }
sub TOOLOPTIONS_PROP            { return 'toolOptions'; }
sub TOOLOPTIONREPLACEMENTS_PROP { return 'toolOptionReplacements'; }
sub TOOLOPTIONVALS_PROP         { return 'toolOptionVals'; }
sub TOOLRUNDIRECTORY_PROP       { return 'toolRunDirectory'; }
sub OUTPUTFILESUFFIX_PROP       { return 'outputFileSuffix'; }

sub RUN_TOOL_PROPERTIES {
  return (
    TOOLCLASS_PROP,              TOOLCONFIG_PROP,
    TOOLNAME_PROP,               TOOLOPTIONS_PROP,
    TOOLOPTIONREPLACEMENTS_PROP, TOOLOPTIONVALS_PROP,
    TOOLRUNDIRECTORY_PROP,       OUTPUTFILESUFFIX_PROP,
  );
}

################################################################################
#
#                           Private Methods
#
################################################################################

sub _getRunnableJobs {
  my parallel::Component::RunTool $this = shift;

  my $controller = $this->getController;
  my $properties = $this->getProperties;

  $this->{data_files} = undef;
  my $daq_comp =
    $controller->getComponent( $this->{utils}->DATAACQUISITION_COMP );
  my $dataFiles = $daq_comp->getDataContent;

  my $agg_comp = $controller->getComponent( $this->{utils}->AGGREGATE_COMP );
  $this->{output_files} =
    new parallel::File::OutputFiles( $agg_comp->getOutputFiles,
    $this->{error_mgr} );
  $this->{output_files_lock} =
    new parallel::Lock( $agg_comp->getOutputFilesLock,
    $this->{error_mgr}, $this->{tools} );
  ###
  ### Return immediatly if there are no jobs that have been run
  ###
  my $outputFiles     = $this->{output_files};
  my $outputFilesLock = $this->{output_files_lock};
  if (!-e $outputFiles->getOutputFilesFile
    || -z $outputFiles->getOutputFilesFile )
  {
    $this->{data_files} = $dataFiles;
    return;
  }
  ###
  ### Determine jobs that have been run
  ###
  $this->{data_files} =
    new parallel::File::DataFiles( undef, $this->{error_mgr} );
  while (util::Constants::TRUE) {
    if ( $outputFilesLock->setLock ) {
      $this->setErrorStatus( $this->ERR_CAT, 7,
        [ $this->getComponentType, $outputFiles->getOutputFilesFile, ],
        $outputFiles->readFile );
      return if ( $this->getErrorStatus );
      $outputFilesLock->removeLock;
      $this->setErrorStatus(
        $this->ERR_CAT,
        6,
        [
          $this->getComponentType, $outputFiles->getOutputFilesFile,
          undef,                   $outputFilesLock->getLockFile
        ],
        $outputFilesLock->errorAsserted
      );
      last;
    }
    else {
      $this->setErrorStatus(
        $this->ERR_CAT,
        5,
        [
          $this->getComponentType, $outputFiles->getOutputFilesFile,
          undef,                   $outputFilesLock->getLockFile
        ],
        $outputFilesLock->errorAsserted
      );
      return if ( $this->getErrorStatus );
      sleep( $properties->{processSleep} );
    }
  }
  ###
  ### Determine runnable jobs
  ###
  my $jobsCompleted = {};
  foreach my $jobPrefix ( $outputFiles->getPrefixes ) {
    my $jobStatus = $outputFiles->getOutputFileStatus($jobPrefix);
    $jobsCompleted->{$jobPrefix} = util::Constants::EMPTY_STR;
  }
  foreach my $jobPrefix ( $dataFiles->getPrefixes ) {
    next if ( defined( $jobsCompleted->{$jobPrefix} ) );
    $this->{data_files}
      ->addDataFile( $jobPrefix, $dataFiles->getDataFile($jobPrefix) );
  }
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$$$) {
  my ( $that, $properties, $run_type, $controller, $utils, $error_mgr, $tools )
    = @_;
  push( @{$properties}, RUN_TOOL_PROPERTIES );
  my parallel::Component::RunTool $this =
    $that->SUPER::new( $utils->RUNTOOL_COMP, $properties, $controller, $utils,
    $error_mgr, $tools );

  $this->{run_type} = $run_type;

  return $this;
}

sub run {
  my parallel::Component::RunTool $this = shift;

  return if ( !$this->getRun );
  ###
  ### Initialize workspace
  ###
  $this->{workspace_root} = $this->getController->getWorkspaceRoot;
  ###
  ### Must determine which jobs have completed (that
  ### is, in output_files and the output exists).  The
  ### completed jobs must not be re-rerun and removed
  ### from the runnable jobs.
  ###
  $this->_getRunnableJobs;
  return if ( $this->getErrorStatus );

  $this->{pids}      = {};
  $this->{completed} = 0;
  $this->{curr_pids} = [];
  $this->{last_job}  = $this->{data_files}->getLastPrefixIndex;
  $this->{next_job}  = 0;
  $this->{num_jobs}  = $this->{data_files}->getNumPrefixes;
  ###
  ### Initially, Start the Maximumn Number Of Processes
  ###
  foreach my $procNum ( 1 .. $this->getProperties->{maxProcesses} ) {
    my $pid = $this->launchNextJob;
    return if ( $this->getErrorStatus );
    last   if ( !$pid );
  }
  $this->{curr_pids} = [ keys %{ $this->{pids} } ];
}

sub completeJob {
  my parallel::Component::RunTool $this = shift;
  my ($pid) = @_;

  my $properties      = $this->getProperties;
  my $outputFiles     = $this->{output_files};
  my $outputFilesLock = $this->{output_files_lock};
  my $pidInfo         = $this->getPidInfo($pid);
  ###
  ### Report any errors in the tool err file!
  ### Load the error file into the log
  ###
  my $status = $pidInfo->printJobInfo;
  $this->writeErrorFile($pid) if ($status);
  ###
  ### Write job information to outputs file
  ###
  while (util::Constants::TRUE) {
    if ( $outputFilesLock->setLock ) {
      $this->setErrorStatus(
        $this->ERR_CAT,
        4,
        [
          $this->getComponentType, $outputFiles->getOutputFilesFile,
          $pidInfo->getOutputFile,
        ],
        $outputFiles->writeOutputFile(
          $pidInfo, $this->{completed} == $this->{num_jobs}
        )
      );
      return if ( $this->getErrorStatus );
      $outputFilesLock->removeLock;
      $this->setErrorStatus(
        $this->ERR_CAT,
        6,
        [
          $this->getComponentType, $outputFiles->getOutputFilesFile,
          $pidInfo->getOutputFile, $outputFilesLock->getLockFile
        ],
        $outputFilesLock->errorAsserted
      );
      return;
    }
    else {
      $this->setErrorStatus(
        $this->ERR_CAT,
        5,
        [
          $this->getComponentType, $outputFiles->getOutputFilesFile,
          $pidInfo->getOutputFile, $outputFilesLock->getLockFile
        ],
        $outputFilesLock->errorAsserted
      );
      return if ( $this->getErrorStatus );
      sleep( $properties->{processSleep} );
    }
  }
}

sub launchNextJob {
  my parallel::Component::RunTool $this = shift;

  return 0 if ( !$this->getRun );

  my $controller = $this->getController;
  my $dataFiles  = $this->{data_files};
  my $properties = $this->getProperties;
  my $tools      = $this->{tools};
  my $utils      = $this->{utils};

  my $nextFileIndex = $this->{next_job};
  return 0 if ( $nextFileIndex > $this->{last_job} );

  my $filePrefix = $dataFiles->getNthPrefix($nextFileIndex);
  my $dataFile   = $dataFiles->getDataFile($filePrefix);
  $this->{error_mgr}->printMsg("Creating process $filePrefix");

  my $config = new util::ConfigParams( $this->{error_mgr} );
  $config->configModule( $properties->{toolConfig} );
  my $workspaceRoot =
    join( util::Constants::SLASH, $this->getWorkspaceRoot, $filePrefix );
  $tools->cmds->createDirectory(
    $workspaceRoot,
    "creating $workspaceRoot",
    !$controller->existingVersion
  );
  my $executionDirectory = $workspaceRoot;
  my $propertiesFile     = join( util::Constants::SLASH,
    $workspaceRoot,
    join( util::Constants::DOT, $properties->{datasetName}, $tools->PROPERTIES
    )
  );
  my $statusFile = join( util::Constants::SLASH,
    $workspaceRoot,
    join( util::Constants::DOT, '.status', $properties->{datasetName} ) );
  my $outputFile = join( util::Constants::SLASH,
    $workspaceRoot,
    join( util::Constants::DOT,
      $properties->{datasetName},
      $properties->{outputFileSuffix}
    )
  );
  my $stdFile = join( util::Constants::SLASH,
    $workspaceRoot,
    join( util::Constants::DOT,
      $properties->{datasetName},
      $utils->STD_OUTPUT_SUFFIX
    )
  );
  my $errFile = join( util::Constants::SLASH,
    $workspaceRoot,
    join( util::Constants::DOT,
      $properties->{datasetName},
      $utils->ERR_OUTPUT_SUFFIX
    )
  );
  my $logInfix = $properties->{datasetName};

  $config->setProperty( 'dataFile',           $dataFile );
  $config->setProperty( 'errFile',            $errFile );
  $config->setProperty( 'executionDirectory', $executionDirectory );
  $config->setProperty( 'logInfix',           $logInfix );
  $config->setProperty( 'outputFile',         $outputFile );
  $config->setProperty( 'statusFile',         $statusFile );
  $config->setProperty( 'stdFile',            $stdFile );
  $config->setProperty( 'workspaceRoot',      $workspaceRoot );
  foreach my $property ( $this->getLocalProperties ) {
    $config->setProperty( $property, $properties->{$property} );
  }

  $config->storeFile($propertiesFile);
  my $cmd = $utils->getRunToolCmd( $properties->{runTool},
    $propertiesFile, $workspaceRoot, $this->getComponentType );
  my $pid = $controller->getJobs->forkProcess($cmd);
  $this->setErrorStatus( $this->ERR_CAT, 3,
    [ $this->getComponentType, $properties->{runTool}, ], !$pid );
  return 0 if ( $this->getErrorStatus );
  $this->setPidInfo(
    $pid,
    cmd             => $cmd,
    component_type  => $this->getComponentType,
    data_file       => $dataFile,
    err_file        => $errFile,
    file_prefix     => $filePrefix,
    output_file     => $outputFile,
    properties_file => $propertiesFile,
    status_file     => $statusFile,
    std_file        => $stdFile,
    workspace_root  => $workspaceRoot
  );
  $this->{next_job}++;
  return $pid;
}

sub getRunType {
  my parallel::Component::RunTool $this = shift;
  return $this->{run_type};
}

################################################################################

1;

__END__

=head1 NAME

RunTool.pm

=head1 DESCRIPTION

This class defines the basics capabilities running tools in data
parallelism.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::RunTool(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
