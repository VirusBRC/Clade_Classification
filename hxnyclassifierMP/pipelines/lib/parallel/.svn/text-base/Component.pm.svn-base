package parallel::Component;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;

use parallel::ErrMsgs;
use parallel::PidInfo;

use fields qw(
  completed
  component_type
  controller
  curr_pids
  error_files
  error_status
  error_mgr
  last_job
  local_properties
  next_job
  num_jobs
  pids
  properties
  run
  status_file
  tools
  utils
  workspace_root
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return parallel::ErrMsgs::COMPONENT_CAT; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$$$) {
  my parallel::Component $this = shift;
  my ( $component_type, $properties, $controller, $utils, $error_mgr, $tools ) =
    @_;
  $this = fields::new($this) unless ref($this);

  $this->{component_type}   = $component_type;
  $this->{controller}       = $controller;
  $this->{error_mgr}        = $error_mgr;
  $this->{local_properties} = [ @{$properties} ];
  $this->{error_status}     = util::Constants::FALSE;
  $this->{properties}  = $utils->setProperties( $component_type, $properties );
  $this->{run}         = util::Constants::FALSE;
  $this->{status_file} = undef;
  $this->{tools}       = $tools;
  $this->{utils}       = $utils;
  $this->{workspace_root} = undef;

  $this->{error_files} = join( util::Constants::SLASH,
    $controller->getWorkspaceRoot,
    $this->getProperties->{errorFiles}
  );
  ###
  ### Process Specific
  ###
  $this->{pids}      = {};
  $this->{completed} = 0;
  $this->{curr_pids} = [];
  $this->{num_jobs}  = 0;
  $this->{last_job}  = 0;
  $this->{next_job}  = 0;

  return $this;
}

sub setRun {
  my parallel::Component $this = shift;
  $this->{run} = util::Constants::TRUE;
}

sub unsetRun {
  my parallel::Component $this = shift;
  $this->{run} = util::Constants::FALSE;
}

sub run {
  my parallel::Component $this = shift;
  #######################
  ### Abstract Method ###
  #######################
}

sub completeJob {
  my parallel::Component $this = shift;
  my ($pid) = @_;
  ########################
  ### Re-Implementable ###
  ########################
  ###
  ### NO-OP
  ###
}

sub launchNextJob {
  my parallel::Component $this = shift;
  ########################
  ### Re-Implementable ###
  ########################
  return 0;
}

sub writeErrorFile {
  my parallel::Component $this = shift;
  my ($pid) = @_;

  my $pidInfo       = $this->getPidInfo($pid);
  my $dataFile      = $pidInfo->getDataFile;
  my $componentType = $this->getComponentType;

  my $fh = new FileHandle;
  $fh->open( $this->getErrorFiles, '>>' );
  $fh->autoflush(util::Constants::TRUE);
  $fh->print(
    join( util::Constants::TAB, $componentType, $dataFile )
      . util::Constants::NEWLINE );
  $fh->close;
}

sub incrementCompleted {
  my parallel::Component $this = shift;
  $this->{completed}++;
}

sub setCurrPids {
  my parallel::Component $this = shift;
  my (@curr_pids) = @_;
  $this->{curr_pids} = [@curr_pids];
}

sub setErrorStatus {
  my parallel::Component $this = shift;
  my ( $err_cat, $err_num, $msgs, $test ) = @_;

  return if ( !$test );
  $this->{error_mgr}->registerError( $err_cat, $err_num, $msgs, $test );
  $this->{error_status} = util::Constants::TRUE;
}

sub unsetErrorStatus {
  my parallel::Component $this = shift;

  $this->{error_status} = util::Constants::FALSE;
}

sub setPidInfo {
  my parallel::Component $this = shift;
  my ( $pid, %pidInfo ) = @_;
  $this->{pids}->{$pid} =
    new parallel::PidInfo( $pid, $this->{error_mgr}, $this->{utils}, %pidInfo );
}

sub setProperty {
  my parallel::Component $this = shift;
  my ( $property, $val ) = @_;
  $this->{properties}->{$property} = $val;
}

################################################################################
#
#                           Getter Methods
#
################################################################################

sub getController {
  my parallel::Component $this = shift;
  return $this->{controller};
}

sub getComponentType {
  my parallel::Component $this = shift;
  return $this->{component_type};
}

sub getErrorFiles {
  my parallel::Component $this = shift;
  return $this->{error_files};
}

sub getRun {
  my parallel::Component $this = shift;
  return $this->{run};
}

sub _numSort { $a <=> $b; }

sub getPids {
  my parallel::Component $this = shift;
  return sort parallel::Component::_numSort keys %{ $this->{pids} };
}

sub getCurrPids {
  my parallel::Component $this = shift;
  return sort parallel::Component::_numSort @{ $this->{curr_pids} };
}

sub getPidInfo {
  my parallel::Component $this = shift;
  my ($pid) = @_;
  return $this->{pids}->{$pid};
}

sub getErrorStatus {
  my parallel::Component $this = shift;
  return $this->{error_status};
}

sub getProperties {
  my parallel::Component $this = shift;
  return $this->{properties};
}

sub getLocalProperties {
  my parallel::Component $this = shift;
  return sort @{ $this->{local_properties} };
}

sub getStatusFile {
  my parallel::Component $this = shift;
  return $this->{status_file};
}

sub getWorkspaceRoot {
  my parallel::Component $this = shift;
  return $this->{workspace_root};
}

################################################################################

1;

__END__

=head1 NAME

Component.pm

=head1 DESCRIPTION

This class defines the basics capabilities of a component in the
pipeline.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component(component_type, properties, controller, error_mgr, tools)>

This is the constructor for the class.

=cut
