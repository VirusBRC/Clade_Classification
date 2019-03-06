package parallel::Jobs;
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

use fields qw(
  dataset_name
  error_mgr
  pid_info
  retry_limit
  retry_sleep
  sleep_rate
  status_file
  tools
  utils
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Process Line
###
sub HEADER_ROW  { return 'PID'; }
sub DEFUNCT_ROW { return '<defunct>'; }
###
### Error Category
###
sub ERR_CAT { return parallel::ErrMsgs::JOBS_CAT; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _retryJob {
  my parallel::Jobs $this = shift;
  my ($cmd) = @_;

  sleep( $this->{retry_sleep} );
  my $pid = fork();
  if ( !defined($pid) ) {
    ###
    ### Unsuccessful start of child process
    ###
    $this->{error_mgr}
      ->registerError( ERR_CAT, 3, [$cmd], util::Constants::TRUE );
    return 0;
  }
  elsif ($pid) {
    ###
    ### Successful start of child process
    ###
    $this->{error_mgr}->printMsg("(retry) parent = $$ (child = $pid)");
    return $pid;
  }
  else {
    ###
    ### Start the child process
    ###
    exec($cmd);
  }
}

sub _handleUnsuccessfulFork {
  my parallel::Jobs $this = shift;
  my ($cmd) = @_;

  my $tools = $this->{tools};
  ###
  ### Unsuccessful start of child process
  ###
  $this->{error_mgr}
    ->registerError( ERR_CAT, 4, [$cmd], util::Constants::TRUE );
  ###
  ### Retry
  ###
  foreach my $retry ( 1 .. $this->{retry_limit} ) {
    my $pid = $this->_retryJob($cmd);
    return $pid if ($pid);
  }
  return 0;
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my parallel::Jobs $this = shift;
  my ( $retry_limit, $retry_sleep, $dataset_name, $status_file, $workspace_root,
    $utils, $error_mgr, $tools )
    = @_;
  $this = fields::new($this) unless ref($this);

  $this->{dataset_name} = $dataset_name;
  $this->{error_mgr}    = $error_mgr;
  $this->{retry_limit}  = $retry_limit;
  $this->{retry_sleep}  = $retry_sleep;
  $this->{sleep_rate}   = 2;
  $this->{status_file}  = $status_file;
  $this->{tools}        = $tools;
  $this->{utils}        = $utils;

  $this->{pid_info} = join( util::Constants::SLASH,
    $workspace_root, $tools->cmds->TMP_FILE( '.pid', 'info' ) );

  return $this;
}

sub setSleepRate {
  my parallel::Jobs $this = shift;
  my ($rate) = @_;

  return if ( util::Constants::EMPTY_LINE($rate) );
  $rate = int($rate);
  if   ( $rate <= 0 ) { $this->{sleep_rate} = 0; }
  else                { $this->{sleep_rate} = $rate; }
}

sub forkProcess {
  my parallel::Jobs $this = shift;
  my ($cmd) = @_;

  sleep( $this->{sleep_rate} ) if ( $this->{sleep_rate} > 0 );
  my $pid = fork();
  if ( !defined($pid) ) {
    return $this->_handleUnsuccessfulFork($cmd);
  }
  elsif ($pid) {
    ###
    ### Successful start of child process
    ###
    $this->{error_mgr}->printMsg("parent = $$ (child = $pid)");
    return $pid;
  }
  else {
    ###
    ### Start the child process
    ###
    exec($cmd);
  }
}

sub _numSort { $a <=> $b; }

sub getPidInfo {
  my parallel::Jobs $this = shift;
  my ($pids) = @_;

  my $pid_info = $this->{pid_info};
  my $pid_list =
    join( util::Constants::COMMA, sort parallel::Jobs::_numSort @{$pids} );
  my $msgs = { cmd => "/bin/ps -j -p${pid_list} > $pid_info", };
  my @processes = ();

  unlink($pid_info) if ( -e $pid_info );
  $this->{tools}->cmds->executeCommand( $msgs, $msgs->{cmd},
    'Getting status of current pids' );
  return @processes if ( !-e $pid_info || -z $pid_info );

  my $fh = new FileHandle;
  $fh->open( $pid_info, '<' );
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    $line =~ s/^ +//;
    my @comps = split( / +/, $line );
    next if ( $comps[0] eq HEADER_ROW );
    my $defunct = $comps[6];
    my $struct  = {
      line => '(' . join( util::Constants::COMMA_SEPARATOR, @comps ) . ')',
      pid  => $comps[0],
      completed => ( defined($defunct) && $defunct eq DEFUNCT_ROW )
      ? util::Constants::TRUE
      : util::Constants::FALSE,
    };
    push( @processes, $struct );
  }
  $fh->close;
  unlink($pid_info) if ( -e $pid_info );

  return @processes;
}

sub terminateRun {
  my parallel::Jobs $this = shift;
  my ( $type, @pids ) = @_;

  my $tools = $this->{tools};

  foreach my $pid (@pids) {
    $this->{error_mgr}
      ->registerError( ERR_CAT, 1, [$pid], util::Constants::TRUE );
    my $cmd  = "kill $pid";
    my $msgs = {
      pid => $pid,
      cmd => $cmd,
    };
    $tools->cmds->executeCommand( $msgs, $cmd, "terminating $pid" );
  }
  $this->{error_mgr}
    ->registerError( ERR_CAT, 2, [$type], util::Constants::TRUE );
  $tools->setStatus( $tools->FAILED );
  $tools->saveStatus( $this->{status_file} );
  $tools->closeLogging;
  $tools->mailFile(
    $tools->getStatus,
    'terminated ' . $this->{dataset_name},
    $tools->getEndTime(util::Constants::TRUE),
    $tools->getLoggingFile
  );
  $tools->terminate;
}

################################################################################

1;

__END__

=head1 NAME

Jobs.pm

=head1 DESCRIPTION

This class manages running parallel threads.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Jobs(error_mgr, tools)>

This is the constructor for the class.

=cut
