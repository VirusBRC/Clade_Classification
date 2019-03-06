#!/usr/bin/perl -w
######################################################################
#                  Copyright (c) 2011 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  partitionByFamily.pl
#
# Description:  This tools partitions a file by familyName.
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
use lib '/home/dbadmin/perl/pipelines_sw/pipelines/lib';

use Carp qw(cluck);
use FileHandle;
use Getopt::Std;
use Pod::Usage;

use parallel::ErrMsgs;
use parallel::Query;

use util::ErrMgr;
use util::ErrMsgs;
use util::Tools;

################################################################################
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

my $error_mgr = new util::ErrMgr(parallel::ErrMsgs::ERROR_HEADER);
my $tools     = new util::Tools( $error_mgr, [ 'parallel', ] );
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
  $opt_P
);
getopts("P:");
###
### Make Sure Required Parameters Are Available
### Otherwise, print usage message.
###
if ( !defined($opt_P) ) {
  my $msg_opt;
  if ( !defined($opt_P) ) { $msg_opt = "-P propertiesFile"; }
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

###
### Set Context
###
my %properties = $tools->setWorkspaceProperty(
  $tools->setContext(
    $opt_P,               'aggregateFile',
    'aggregateFileComps', 'databaseName',
    'endDate',            'familyNames',
    'idCol',              'maxElements',
    'password',           'query',
    'queryFamilyName',    'queryId',
    'queryParamSubs',     'queryParams',
    'queryResultsOrd',    'schemaOwner',
    'serverType',         'startDate',
    'userName',           'workspaceRoot'
  )
);

my $aggregateFile = $properties{aggregateFile};
my $idCol         = $properties{idCol};

my $queryFamilyName = $properties{queryFamilyName};
my $queryId         = $properties{queryId};

my $aggregateFileComps = $properties{aggregateFileComps};

################################################################################
#
#				Main Program
#
################################################################################
###
### Get the id to family name map
###
$error_mgr->printHeader("Getting ID to Family Name Map");

my $idToFamilyName = {};
my $queryMgr       = new parallel::Query( undef, $error_mgr, $tools );
my @data           = $queryMgr->getData( \%properties );
$error_mgr->exitProgram(
  ERR_CAT, 1,
  [
    'id to family map',
    'database query',
    'using query',
    'failed to execute query',
  ],
  $queryMgr->getErrorStatus
);
foreach my $struct (@data) {
  $idToFamilyName->{ $struct->{$queryId} } = $struct->{$queryFamilyName};
}
###
### Read the data and organize by family
###
$error_mgr->printHeader("Getting Data to Partition");
my $fh = new FileHandle;
$fh->open( $aggregateFile, '<' );
my $ids           = {};
my $data          = {};
my $count_total   = 0;
my $count_skipped = 0;
my $count_kept    = 0;

while ( !$fh->eof ) {
  $count_total++;
  my $line = $fh->getline;
  chomp($line);
  my @comps = split( /\t/, $line );
  my $id = $comps[$idCol];
  if ( !defined( $ids->{$id} ) ) {
    my $familyName = $idToFamilyName->{$id};
    if ( util::Constants::EMPTY_LINE($familyName) ) {
      $count_skipped++;
      $error_mgr->printError( "Cannot find family for id = $id",
        util::Constants::TRUE );
      next;
    }
    if ( !defined( $data->{$familyName} ) ) {
      $error_mgr->printMsg("Have $familyName data");
      $data->{$familyName} = [];
    }
    $ids->{$id} = $familyName;
  }
  $count_kept++;
  push( @{ $data->{ $ids->{$id} } }, $line );
}
$fh->close;
$error_mgr->printMsg( "Counts\n"
    . "  total   = $count_total\n"
    . "  kept    = $count_kept\n"
    . "  skipped = $count_skipped" );
###
### Write data
###
$error_mgr->printHeader("Writing Files");
foreach my $familyName ( sort keys %{$data} ) {
  my @comps = ($familyName);
  foreach my $comp ( @{$aggregateFileComps} ) {
    my $val = $properties{$comp};
    if ( util::Constants::EMPTY_LINE($val) ) { $val = $comp; }
    push( @comps, $val );
  }
  my $ffile = join( util::Constants::SLASH,
    $properties{workspaceRoot},
    join( util::Constants::DOT, @comps )
  );
  $error_mgr->printMsg("$ffile = $ffile");
  $fh->open( $ffile, '>' );
  $fh->autoflush(util::Constants::TRUE);
  foreach my $line ( @{ $data->{$familyName} } ) { $fh->print("$line\n"); }
  $fh->close;
}

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

partitionByFamily.pl

=head1 SYNOPSIS

   partitionByFamily.pl
     -P properties_module

This tools partitions a file by familyName.

=cut
