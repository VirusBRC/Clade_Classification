#!/usr/bin/perl
######################################################################
#                  Copyright (c) 2011 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  runGenbankSequences.pl
#
# Description:  This script processes the daily/monthly and peding genbank
#               sequences from NCBI.  This script assumes that
#               the software code base and configuration for this tool
#               has been installed (see runGenbankSequences.sh).  The
#               software base is installed using a special script from
#               a server connected to svn.
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
use Pod::Usage;

use util::Constants;
use util::ErrMgr;
use util::Tools;

use parallel::Utils;

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
  'addMissing',                'dbProperties',
  'dbQuery',                   'deleteMissing',
  'databaseName',              'familyNames',
  'genbankClass',              'loadSeqFile',
  'monthlyAllSeqFile',         'monthlyAllGBFile',
  'monthlyDeleteFilePatterns', 'monthlyFilePatterns',
  'ncDailyFileZip',            'password',
  'pendingFile',               'processObsolete',
  'schemaOwner',               'seqType',
  'serverType',                'sourceType',
  'taxonFile',                 'todayDayDate',
  'userName',                  'workspaceRoot',
  'dailyDbQuery',
];
my $ncbiUtils = new ncbi::Utils( $property_names, $error_mgr, $tools, $utils );

################################################################################
#
#				Main Program
#
################################################################################
###
### Set the run directory
###
chdir( $ncbiUtils->getRunDirectory );
###
### Instantiate Genbank class and the sequence processor
###
my $genbank = $ncbiUtils->getGenbankObject;
my $processor =
  $ncbiUtils->getProcessingObject( $ncbiUtils->PROCESS_CLASS_TYPE );
###
### Process Files
###
$genbank->process($processor);
$genbank->updatePendingFile;

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

runGenbankSequences.pl

=head1 SYNOPSIS

   runGenbankSequences.pl
     -P config_params_module -M (yes|no) -R reportLog -t YYYYMMDD -T databaseName

This runs the daily/monthly genbank flu/nonflu sequences.

=cut
