package parallel::Controller;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;
use util::Db;

use parallel::Jobs;

use POSIX ":sys_wait_h";

use fields qw(
  components
  error_mgr
  existing_version
  jobs
  properties
  run_version
  status_file
  tools
  utils
  workspace_root
);

################################################################################
#
#				Private Methods
#
################################################################################

sub _setRunVersion {
  my parallel::Controller $this = shift;
  my ($run_version) = @_;

  my $tools = $this->{tools};

  $this->{existing_version} = util::Constants::FALSE;
  if ( util::Constants::EMPTY_LINE($run_version) ) {
    $run_version = $tools->cmds->TMP_FILE('controller');
  }
  else {
    $this->{existing_version} = util::Constants::TRUE;
  }
  $this->{run_version} = $run_version;
  ###
  ### Must implement using Oracle sequence...
  ###
}

sub _checkErrorStatus {
  my parallel::Controller $this = shift;
  my ( $component, @components ) = @_;

  return if ( !$component->getErrorStatus );

  my @pids = ();
  foreach my $comp (@components) { push( @pids, $comp->getPids ); }
  $this->{jobs}->terminateRun( $component->getComponentType, @pids );
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my parallel::Controller $this = shift;
  my ( $run_version, $utils, $error_mgr, $tools ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{components} = {};
  $this->{properties} = $utils->setProperties( 'controller', [] );
  $this->{error_mgr}  = $error_mgr;
  $this->{tools}      = $tools;
  $this->{utils}      = $utils;

  $this->_setRunVersion($run_version);
  $this->{workspace_root} = join( util::Constants::SLASH,
    $tools->getProperty('workspaceRoot'),
    $this->{run_version}
  );
  $tools->cmds->createDirectory(
    $this->{workspace_root},
    'creating controller workspace',
    $this->{existing_version} ? util::Constants::FALSE: util::Constants::TRUE
  );

  $this->{status_file} = join( util::Constants::SLASH,
    $this->{workspace_root},
    $tools->getProperty('statusFile')
  );

  $this->{jobs} = new parallel::Jobs(
    $this->{properties}->{retryLimit}, $this->{properties}->{retrySleep},
    $this->{properties}->{datasetName}, $this->{status_file},
    $this->{workspace_root},            $utils,
    $error_mgr,                         $tools
  );

  return $this;
}

sub runComponents {
  my parallel::Controller $this = shift;
  my (@components) = @_;

  my $jobs  = $this->{jobs};
  my $tools = $this->{tools};
  my $utils = $this->{utils};
  ###
  ### Set each component
  ###
  $this->{components} = {};
  foreach my $component (@components) {
    my $componentType = $component->getComponentType;
    $this->{error_mgr}->printMsg("Set Component Type = $componentType");
    $this->{components}->{$componentType} = {
      obj       => $component,
      completed => undef,
    };
  }
  ###
  ### Run each component
  ###
  foreach my $component (@components) {
    my $componentType = $component->getComponentType;
    $this->{error_mgr}->printHeader("Run Component Type = $componentType");
    $component->run;
    ###
    ### Check if component and terminate run, if necessary
    ###
    $this->_checkErrorStatus( $component, @components );

    my @cpids = $component->getCurrPids;
    $this->{error_mgr}->printMsg( "Start Processes = ("
        . join( util::Constants::COMMA_SEPARATOR, @cpids )
        . ")" )
      if ( scalar @cpids > 0 );
    $this->{components}->{$componentType}->{completed} =
      ( scalar @cpids == 0 ) ? util::Constants::TRUE: util::Constants::FALSE;
  }
  ###
  ### Now manage the jobs
  ###
  my $doneWork = util::Constants::TRUE;
  while ($doneWork) {
    $doneWork = util::Constants::FALSE;
    foreach my $componentType ( sort keys %{ $this->{components} } ) {
      next if ( $this->{components}->{$componentType}->{completed} );
      my $component = $this->{components}->{$componentType}->{obj};
      my $cpids     = [ $component->getCurrPids ];
      if ( scalar @{$cpids} == 0 ) {
        $this->{components}->{$componentType}->{completed} =
          util::Constants::TRUE;
        next;
      }
      $doneWork = util::Constants::TRUE;
      sleep( $this->{properties}->{processSleep} );
      my @curr_pids = ();
      foreach my $child ( $jobs->getPidInfo($cpids) ) {
        $this->{error_mgr}->printMsg( $child->{line} );
        my $pid = $child->{pid};
        if ( $child->{completed} ) {
          my $creturn = waitpid( $pid, WNOHANG );
          $this->{error_mgr}->printMsg("  child return status = $creturn");
          my $pidInfo   = $component->getPidInfo($pid);
          my $jobStatus = $utils->getStatus( $pidInfo->getStatusFile );
          $this->{error_mgr}->printMsg("$pid completes with = $jobStatus");
          $tools->setStatus( $tools->FAILED )
            if ( $jobStatus eq $tools->FAILED );
          ###
          ### Update results output file
          ###
          $component->incrementCompleted;
          $component->completeJob($pid);
          $this->_checkErrorStatus( $component, @components );
          ###
          ### Determine another job to run
          ###
          $pid = $component->launchNextJob;
          $this->_checkErrorStatus( $component, @components );
        }
        push( @curr_pids, $pid ) if ($pid);
      }
      $component->setCurrPids(@curr_pids);
    }
  }
}

################################################################################
#
#                           Getter Methods
#
################################################################################

sub getRunVersion {
  my parallel::Controller $this = shift;
  return $this->{run_version};
}

sub existingVersion {
  my parallel::Controller $this = shift;
  return $this->{existing_version};
}

sub getComponent {
  my parallel::Controller $this = shift;
  my ($component_type) = @_;
  return $this->{components}->{$component_type}->{obj};
}

sub getJobs {
  my parallel::Controller $this = shift;
  return $this->{jobs};
}

sub getWorkspaceRoot {
  my parallel::Controller $this = shift;
  return $this->{workspace_root};
}

sub getStatusFile {
  my parallel::Controller $this = shift;
  return $this->{status_file};
}

################################################################################

1;

__END__

=head1 NAME

Controller.pm

=head1 DESCRIPTION

This class defines the basics capabilities of the controller for
running a set of components.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Controller(error_mgr, tools)>

This is the constructor for the class.

=cut
