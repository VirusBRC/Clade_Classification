#!/usr/bin/perl
######################################################################
#                  Copyright (c) 2011 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  updatePendingFile.pl
#
# Description:  This script processes the monthly changes files to
#               determine new pending records and adds them to the
#               pending file ready for next day processing.
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
use util::ErrMsgs;
use util::Tools;

use parallel::Utils;

use ncbi::Genbank;

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
#				   Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return util::ErrMsgs::PROG_CAT; }

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
### Instantiate the Base Genbank class and the sequence processor
###
my $genbank = newBase ncbi::Genbank( $error_mgr, $tools, $utils, $ncbiUtils );
my $class     = join( '::', 'ncbi', $ncbiUtils->PROCESS_CLASS_TYPE, 'UpdateMonthlyPending' );
my $processor = $ncbiUtils->getObject($class);
###
### Process Files
###
$processor->setGenbank($genbank);
$processor->processFiles;

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

updatePendingFile.pl

=head1 SYNOPSIS

   updatePendingFile.pl
     -P config_params_module 

This script processes the monthly changes files to
determine new pending records and adds them to the
pending file ready for next day processing.

=cut
