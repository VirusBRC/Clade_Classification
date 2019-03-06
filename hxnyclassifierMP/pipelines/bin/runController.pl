#!/usr/bin/perl
######################################################################
#                  Copyright (c) 2011 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  runController.pl
#
# Description:  This tool runs parallel processing controller
#
# Assumptions:
#
######################################################################

################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Carp qw(cluck);
use Getopt::Std;
use Pod::Usage;

use util::ErrMgr;
use util::ErrMsgs;
use util::Tools;

use parallel::Controller;
use parallel::ErrMsgs;
use parallel::Utils;

################################################################################
#
#				Signal Handlers
#
################################################################################

$SIG{HUP}  = 'signalHandler';
$SIG{INT}  = 'signalHandler';
$SIG{QUIT} = 'signalHandler';
$SIG{TERM} = 'signalHandler';

################################################################################
#
#				   Error and Message Management
#
################################################################################

my $error_mgr = new util::ErrMgr(parallel::ErrMsgs::ERROR_HEADER);
my $tools     = new util::Tools( $error_mgr, [ 'parallel', ] );
my $cmds      = $tools->cmds;
my $utils     = new parallel::Utils( $error_mgr, $tools );

################################################################################
#
#				   Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return util::ErrMsgs::PROG_CAT; }

################################################################################
#
#			    Parameter Initialization
#
################################################################################

use vars qw(
  $opt_P
);
getopts("P:");

###
### Make Sure Required Parameters Are Available
### Otherwise, print usage message.
###
if ( !defined($opt_P) ) {
  my $msg_opt;
  if ( !defined($opt_P) ) { $msg_opt = "-P config_params_module"; }
  my $message = "You must supply the $msg_opt option";
  pod2usage(
    -message => $message,
    -exitval => 2,
    -verbose => util::Constants::TRUE,
    -output  => \*STDERR
  );
}

STDERR->autoflush(util::Constants::TRUE);    ### Make unbuffered
STDOUT->autoflush(util::Constants::TRUE);    ### Make unbuffered
select STDOUT;

################################################################################
#
#				Parameter Setup
#
################################################################################

my %properties = $tools->setWorkspaceProperty(
  $tools->setContextWithoutOpenLogging(
    $opt_P,

    'datasetName',
    'email',
    'emailTo',
    'errorFiles',
    'jobInfo',
    'maxProcesses',
    'pipelineComponents',
    'pipelineOrder',
    'processSleep',
    'retryLimit',
    'retrySleep',
    'runsCols',
    'runsInfo',
    'runTool',
    'statusFile',

    'databaseName',
    'password',
    'schemaOwner',
    'serverType',
    'userName',

    $tools->getPropertySet($opt_P)
  )
);

$tools->setEmail( $properties{emailTo} ) if ( $properties{email} );

$utils->setJobInfo( $properties{jobInfo} );
my $controller =
  new parallel::Controller( $properties{runVersion}, $utils, $error_mgr,
  $tools );
my $info = $utils->writeRunsInfo( \%properties, $controller->getRunVersion );
$tools->mailMsg(
  'STARTED',
  $properties{datasetName},
  $tools->getStartTime(util::Constants::TRUE), $info
);
my $logFile = join( util::Constants::SLASH,
  $tools->executionDir,
  join( util::Constants::DOT,
    $properties{datasetName},
    $controller->getRunVersion, 'log'
  )
);
$tools->openLoggingWithLogFile($logFile, undef, util::Constants::TRUE);

my $pipelineComponents = $properties{pipelineComponents};
my @pipelineTools      = ();
foreach my $comp_class ( @{ $properties{pipelineOrder} } ) {
  my $component = $utils->createComponent( $controller, $comp_class );
  push( @pipelineTools, $component );
  $component->setRun if ( $pipelineComponents->{$comp_class} );
}

################################################################################
#
#				Main Program
#
################################################################################

$controller->runComponents(@pipelineTools);

################################################################################
#
#				Epiplogue
#
################################################################################

$tools->saveStatus( $controller->getStatusFile );
$tools->closeLogging;
$tools->mailFile(
  $tools->getStatus,
  'completed ' . $properties{datasetName},
  $tools->getEndTime(util::Constants::TRUE),
  $tools->getLoggingFile
);
$tools->terminate;

################################################################################
#
#				Signal Handler
#
################################################################################

sub signalHandler {
  my $signal = shift;
  cluck $signal;
  my $print_prefix = 'ERROR(signalHandler):  ';
  eval {
    my $sig = undef;
    if    ( $signal eq 'HUP' )     { $sig = "SIGHUP"; }
    elsif ( $signal eq 'QUIT' )    { $sig = "SIGQUIT"; }
    elsif ( $signal eq 'INT' )     { $sig = "SIGINT"; }
    elsif ( $signal eq 'TERM' )    { $sig = "SIGTERM"; }
    elsif ( $signal eq '__DIE__' ) { $sig = "__DIE__"; }
    $error_mgr->printMsg( $print_prefix . $sig );
    $error_mgr->printMsg(
      $print_prefix . "End-Of-signalHandler, POSIX EXIT CODE = 2\n" );
    $tools->setStatus( $tools->FAILED );
    $tools->saveStatus( $properties{statusFile} );
    $tools->closeLogging;
    $tools->terminate;
  };
}

__END__

=head1 NAME

runController.pl

=head1 SYNOPSIS

   runController.pl
     -P config_params_module

This runs the parallelization controller.

=cut
