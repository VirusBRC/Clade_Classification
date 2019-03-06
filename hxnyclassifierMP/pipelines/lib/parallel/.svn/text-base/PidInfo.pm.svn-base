package parallel::PidInfo;
################################################################################
#
#				Required Modules
#
################################################################################

use File::Basename;
use FileHandle;
use strict;

use Pod::Usage;

use util::Constants;

use fields qw(
  cmd
  component_type
  data_file
  error_mgr
  err_file
  file_prefix
  output_file
  properties_file
  pid
  status_file
  std_file
  workspace_root
  utils
);

################################################################################
#
#			            Constants
#
################################################################################

sub CMD_COMP             { return 'cmd'; }
sub COMPONENT_TYPE_COMP  { return 'component_type'; }
sub DATA_FILE_COMP       { return 'data_file'; }
sub ERR_FILE_COMP        { return 'err_file'; }
sub FILE_PREFIX_COMP     { return 'file_prefix'; }
sub OUTPUT_FILE_COMP     { return 'output_file'; }
sub PROPERTIES_FILE_COMP { return 'properties_file'; }
sub STATUS_FILE_COMP     { return 'status_file'; }
sub STD_FILE_COMP        { return 'std_file'; }
sub WORKSPACEROOT_COMP   { return 'workspace_root'; }

sub COMPONENTS {
  return (
    CMD_COMP,             COMPONENT_TYPE_COMP, FILE_PREFIX_COMP,
    PROPERTIES_FILE_COMP, OUTPUT_FILE_COMP,    STATUS_FILE_COMP,
    DATA_FILE_COMP,       ERR_FILE_COMP,       STD_FILE_COMP,
    WORKSPACEROOT_COMP
  );
}

################################################################################
#
#			            Private Methods
#
################################################################################

sub _getComp {
  my parallel::PidInfo $this = shift;
  my ($comp) = @_;
  return $this->{$comp};
}

################################################################################
#
#			            Public Methods
#
################################################################################

sub new {
  my parallel::PidInfo $this = shift;
  my ( $pid, $error_mgr, $utils, %params ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr} = $error_mgr;
  $this->{pid}       = $pid;
  $this->{utils}     = $utils;
  foreach my $comp (COMPONENTS) {
    if ( util::Constants::EMPTY_LINE( $params{$comp} ) ) {
      $this->{$comp} = undef;
    }
    else {
      $this->{$comp} = $params{$comp};
    }
  }

  return $this;
}

sub printJobInfo {
  my parallel::PidInfo $this = shift;

  my $utils = $this->{utils};
  my $file  = $this->getErrFile;

  my $found_errors = util::Constants::FALSE;
  return $found_errors if ( !-e $file
    || !-f $file
    || -z $file
    || !-r $file );

  my $fh = new FileHandle;
  $fh->open( $file, '<' );
  my $header      = 'Information for Job';
  my $report_file = undef;
  my @lines       = ();
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    push( @lines, $line );
    if (
      !defined($report_file)
      && $utils->foundPattern(
        $line, $utils->getJobInfo( $utils->REPORT_FILE_EXPRS_COMP )
      )
      )
    {
      $report_file = $line;
    }
    if (
      !$found_errors
      && $utils->foundPattern(
        $line, $utils->getJobInfo( $utils->ERR_EXPRS_COMP )
      )
      )
    {
      $found_errors = util::Constants::TRUE;
      $header       = 'ERROR Information for Job';
    }
  }
  $fh->close;
  if ( defined($report_file)
    && -e $report_file
    && !-z $report_file
    && -r $report_file )
  {
    push( @lines, "REPORT FILE:" );
    $fh->open( $report_file, '<' );
    while ( !$fh->eof ) {
      my $line = $fh->getline;
      chomp($line);
      push( @lines, $line );
    }
    $fh->close;
  }
  $this->{error_mgr}->printHeader( "$header\n"
      . "  workspace_root  =\n    "
      . $this->getWorkspaceRoot . "\n"
      . "  component type  = "
      . $this->getComponentType . "\n"
      . "  properties file = "
      . basename( $this->getPropertiesFile ) . "\n"
      . "  status file     = "
      . basename( $this->getStatusFile ) );
  $this->{error_mgr}->printMsgOrError( join( util::Constants::NEWLINE, @lines ),
    $found_errors );
  return $found_errors;
}

sub getPid {
  my parallel::PidInfo $this = shift;
  return $this->{pid};
}

sub getCmd {
  my parallel::PidInfo $this = shift;
  return $this->_getComp(CMD_COMP);
}

sub getComponentType {
  my parallel::PidInfo $this = shift;
  return $this->_getComp(COMPONENT_TYPE_COMP);
}

sub getPropertiesFile {
  my parallel::PidInfo $this = shift;
  return $this->_getComp(PROPERTIES_FILE_COMP);
}

sub getWorkspaceRoot {
  my parallel::PidInfo $this = shift;
  return $this->_getComp(WORKSPACEROOT_COMP);
}

sub getDataFile {
  my parallel::PidInfo $this = shift;
  return $this->_getComp(DATA_FILE_COMP);
}

sub getFilePrefix {
  my parallel::PidInfo $this = shift;
  return $this->_getComp(FILE_PREFIX_COMP);
}

sub getOutputFile {
  my parallel::PidInfo $this = shift;
  return $this->_getComp(OUTPUT_FILE_COMP);
}

sub getStatusFile {
  my parallel::PidInfo $this = shift;
  return $this->_getComp(STATUS_FILE_COMP);
}

sub getStdFile {
  my parallel::PidInfo $this = shift;
  return $this->_getComp(STD_FILE_COMP);
}

sub getErrFile {
  my parallel::PidInfo $this = shift;
  return $this->_getComp(ERR_FILE_COMP);
}

################################################################################

1;

__END__

=head1 NAME

PidInfo.pm

=head1 DESCRIPTION

This class defines the pid information container

=head1 METHODS


=cut
