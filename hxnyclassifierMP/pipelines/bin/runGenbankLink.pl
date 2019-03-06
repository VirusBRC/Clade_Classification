#!/usr/bin/perl
######################################################################
#                  Copyright (c) 2011 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  runGenbankDownload.pl
#
# Description:
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
use Cwd 'chdir';
use File::Basename;
use Pod::Usage;

use util::Constants;
use util::ErrMgr;
use util::Tools;

use parallel::Utils;

use ncbi::Download::Daily;
use ncbi::Download::Monthly;
use ncbi::Utils;

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

my $error_mgr = new util::ErrMgr();
my $tools     = new util::Tools( $error_mgr, [ 'ncbi', 'parallel' ] );
my $utils     = new parallel::Utils( $error_mgr, $tools );
my $cmds      = $tools->cmds;

################################################################################
#
#			    Setup std and err
#
################################################################################

STDERR->autoflush(util::Constants::TRUE);    ### Make unbuffered
STDOUT->autoflush(util::Constants::TRUE);    ### Make unbuffered
select STDOUT;

################################################################################
#
#				Parameter Setup
#
################################################################################

my $property_names = [
    'dailyLinkFile',
    'databaseName',
    'gbReleaseNumberFile',
    'linkFiles',
    'monthlyFilePattern',
    'monthlyFileSubstitutor',
    'monthlyFiles',
    'password',
    'retryLimit',
    'retrySleep',
    'schemaOwner',
    'serverType',
    'sourceDirectory',
    'todayDayDate',
    'userName',
    'workspaceRoot',
];
my $ncbiUtils = new ncbi::Utils( $property_names, $error_mgr, $tools, $utils );
my $linkage =
  $ncbiUtils->getProcessingObject( $ncbiUtils->LINK_CLASS_TYPE );

################################################################################
#
#				Main Program
#
################################################################################
###
### Link Files
### Record Timestamp
### Record Release Number
### Register job
### Update report
###
chdir( $ncbiUtils->getDataDirectory );
$linkage->print( "begin section link "
    . $ncbiUtils->getCmd("date")
    . "\n--------------------------------------------------------------------------------"
);
$linkage->link;
$linkage->recordReleaseNumber;
$linkage->registerJob;
$linkage->updateReport;
$linkage->print("\nFinished Link...");

################################################################################
#
#				Epiplogue
#
################################################################################

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
    $tools->closeLogging;
    $tools->terminate;
  };
}

__END__

=head1 NAME

runGenbankLink.pl

=head1 SYNOPSIS

   runGenbankLink.pl
     -P config_params_module -M (yes|no) -R reportLog -t YYYYMMDD -T databaseName [ -G (yes|no) ] -R report_file -M monthly

This runs the genbank sequence linking process.

=cut
