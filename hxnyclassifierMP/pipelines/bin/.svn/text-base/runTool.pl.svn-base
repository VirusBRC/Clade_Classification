#!/usr/bin/perl
######################################################################
#                  Copyright (c) 2011 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  runTool.pl
#
# Description:  This runs an instance of a tool.
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

use parallel::Utils;

use tool::ErrMsgs;

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

my $error_mgr = new util::ErrMgr(tool::ErrMsgs::ERROR_HEADER);
my $tools     = new util::Tools( $error_mgr, [ 'parallel', 'tool', ] );
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
  $tools->setContext(
    $opt_P,

    'dataFile',
    'dataFileLock',
    'errFile',
    'outputFile',
    'sleepInterval',
    'statusFile',
    'stdFile',
    'toolClass',
    'toolName',
    'toolOptions',
    'toolOptionReplacements',
    'toolOptionVals',
    'toolRunDirectory',
    'outputFileSuffix',

    $tools->getPropertySet($opt_P)
  )
);

################################################################################
#
#				Main Program
#
################################################################################

my $tool = $utils->createTool( $properties{toolClass} );
$tool->run;

################################################################################
#
#				Epiplogue
#
################################################################################

$tools->saveStatus( $properties{statusFile} );
$tools->closeLogging;
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

runTool.pl

=head1 SYNOPSIS

   runTool.pl
     -P config_params_module

This runs an instance of a tool.

=cut
