#!/usr/bin/perl
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  processH5N1Classifier.pl
#
# Description:  This tools processeses the H5N1 classifier.
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
use FileHandle;
use Getopt::Std;
use Pod::Usage;

use util::ConfigParams;
use util::Constants;
use util::ErrMgr;
use util::PathSpecifics;
use util::Tools;

use ncbi::ErrMsgs;
use ncbi::ReplaceH5N1TempDir;

###############################################################################
#
#				Signal Handlers
#
################################################################################

$SIG{HUP}  = 'signalHandler';
$SIG{INT}  = 'signalHandler';
$SIG{TERM} = 'signalHandler';

################################################################################
#
#				   Error and Message Management
#
################################################################################

my $error_mgr = new util::ErrMgr(ncbi::ErrMsgs::ERROR_HEADER);
my $tools     = new util::Tools( $error_mgr, [ 'ncbi', ] );
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
#			    Parameter Initialization
#
################################################################################

use vars qw(
  $opt_E
  $opt_P
  $opt_F
);
getopts("E:F:P:");

###
### Make Sure Required Parameters Are Available
### Otherwise, print usage message.
###
if ( !defined($opt_E) || !defined($opt_F) || !defined($opt_P) ) {
  my $message = "You must supply the";
  if ( !defined($opt_E) ) { $message .= " -E execution_directory option"; }
  if ( !defined($opt_F) ) { $message .= " -F fasta_file option"; }
  if ( !defined($opt_P) ) { $message .= " -P config_params_module option"; }
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
###
### Set Context
###
my $property_names = [
  'allNaSequenceIdsQuery', 'allSeqs',
  'className',             'classifierConfig',
  'classifierConfig',      'classifierPerlLib',
  'classifierTool',        'clustalWPath',
  'countries',             'databaseName',
  'datasetName',           'debugSwitch',
  'executionDirectory',    'fasta',
  'fastaFile',             'generate',
  'host',                  'jobInfo',
  'load',                  'logInfix',
  'maxProcesses',          'naSequenceIds',
  'naSidFile',             'password',
  'processSleep',          'profileSeqs',
  'propertySet',           'retryLimit',
  'retrySleep',            'runTool',
  'schemaOwner',           'segments',
  'selectQuery',           'seqsOrd',
  'serverType',            'statusFile',
  'subtype',               'todayDayDate',
  'updateQuery',           'userName',
  'workspaceRoot',         'seqMrkrSeqIdQuery',
  'seqIdComp',
];
my $configParams       = $opt_P;
my $executionDirectory = getPath($opt_E);
my $fastaFile          = getPath($opt_F);

$cmds->createDirectory( $executionDirectory, 'creating execution directory' );

my $properties       = new util::ConfigParams($error_mgr);
my $configParamsFile = getPath($configParams);
if ( -e $configParamsFile ) {
  $properties->loadFile($configParamsFile);
}
else {
  $properties->configModule($configParams);
}

################################################################################
#
#				Main Program
#
################################################################################

my $runProperties = new util::ConfigParams($error_mgr);
foreach my $property ( @{$property_names} ) {
  $runProperties->setProperty( $property, $properties->getProperty($property) );
}
###
### !!Assume that the classifierConfig is an absolute path in this case!!
###
my $classifierConfig = $properties->getProperty('classifierConfig');
my $replacer         = new ncbi::ReplaceH5N1TempDir($error_mgr);
$replacer->setTempDir($executionDirectory);
$replacer->replaceTempDir( $executionDirectory, $classifierConfig );
$classifierConfig = $replacer->getXmlFile;

$runProperties->setProperty( 'classifierConfig',   $classifierConfig );
$runProperties->setProperty( 'executionDirectory', $executionDirectory );
$runProperties->setProperty( 'workspaceRoot',      $executionDirectory );
$runProperties->setProperty( 'propertySet',        $property_names );

my $seqsOrd = [ 'defline', 'h5n1_clade', ];
$runProperties->setProperty( 'seqsOrd', $seqsOrd );

$runProperties->setProperty( 'allSeqs',   util::Constants::FALSE );
$runProperties->setProperty( 'fasta',     util::Constants::TRUE );
$runProperties->setProperty( 'fastaFile', getPath($fastaFile) );
$runProperties->setProperty( 'generate',  util::Constants::TRUE );
$runProperties->setProperty( 'load',      util::Constants::FALSE );
my $tmpFile      = $cmds->TMP_FILE('H5N1');
my $propertyFile = join( util::Constants::SLASH,
  $executionDirectory, join( util::Constants::DOT, $tmpFile, 'properties' ) );
my $reportLog = join( util::Constants::SLASH,
  $executionDirectory, join( util::Constants::DOT, $tmpFile, 'report' ) );

$runProperties->storeFile($propertyFile);
my $msgs = {
  cmd => join( util::Constants::SPACE,
    join( util::Constants::SLASH, $tools->scriptPath, 'processGenbank.pl' ),
    '-P', $propertyFile, '-R', $reportLog, '-t',
    $properties->getProperty('todayDayDate'),
    '-M no', '-T NOOP'
  ),
};

my $status =
  $cmds->executeCommand( $msgs, $msgs->{cmd},
  'Running classifier for fasta file' );
$error_mgr->exitProgram( ERR_CAT, 1,
  [ 'run classifier', 'fasta file', $fastaFile, $status ], $status );

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
    print STDOUT "\n\n", $print_prefix . "SIGNAL = $signal\n",
      $print_prefix . "NAME   = ";
    if ( $signal eq 'HUP' ) {
      print STDOUT "SIGHUP\n";
    }
    elsif ( $signal eq 'INT' ) {
      print STDOUT "SIGINT\n";
    }
    elsif ( $signal eq 'TERM' ) {
      print STDOUT "SIGTERM\n";
    }
    elsif ( $signal eq '__DIE__' ) {
      print STDOUT "__DIE__\n";
    }
    print STDOUT $print_prefix . "End-Of-signalHandler, POSIX EXIT CODE = 2\n";
    POSIX::_exit(2);
  };
}

__END__

=head1 NAME

processH5N1ClassifierByFastaFile.pl

=head1 SYNOPSIS

   processH5N1ClassifierByFastaFile.pl -P config_params_module -E execution_directory -F fasta_file

This tools processeses the H5N1 classifier with
fasta_file input.

=cut
