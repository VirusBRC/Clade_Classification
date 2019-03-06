#!/usr/bin/perl -w
######################################################################
#                  Copyright (c) 2011 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  removeFeatureIdsFromAggregate.pl
#
# Description:  This tools removes feature ids from the aggregate file.
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
use Cwd 'chdir';
use FileHandle;
use Getopt::Std;
use Pod::Usage;

use util::ErrMgr;
use util::ErrMsgs;
use util::PathSpecifics;
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

my $error_mgr = new util::ErrMgr();
my $tools     = new util::Tools( $error_mgr, [] );
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
my %properties = $tools->setWorkspaceProperty($tools->setContext
  ( $opt_P,
    'keepIdsFile',
    'aggregateFiles',
    'backupSuffix',
    'workspaceRoot'
  ));

my $keepIdsFile    = $properties{keepIdsFile};
my $aggregateFiles = $properties{aggregateFiles};
my $backupSuffix   = $properties{backupSuffix};

################################################################################
#
#				Main Program
#
################################################################################
###
### Get the feature ids to keep
###
my $fh = new FileHandle;
$fh->open($keepIdsFile, '<');
my $keepIds = {};
while (!$fh->eof) {
  my $line = $fh->getline;
  chomp($line);
  $keepIds->{$line} = util::Constants::EMPTY_STR;
}
$fh->close;
###
### Remove unwanted feature ids
###
my $removedIds = {};
foreach my $aggregateFile (@{$aggregateFiles}) {
  $aggregateFile = $tools->setWorkspaceForProperty($aggregateFile);
  my $backupFile = join(util::Constants::DOT, $aggregateFile, $backupSuffix);
  my $tmpFile =
    join(util::Constants::SLASH,
         $properties{workspaceRoot},
         $cmds->TMP_FILE('removeFeatureIds'));
  $fh->open($aggregateFile, '<');
  my $ofh = new FileHandle;
  $ofh->open($tmpFile, '>');
  $ofh->autoflush(util::Constants::TRUE);
  while (!$fh->eof) {
    my $line = $fh->getline;
    chomp($line);
    my @comps = split(/\t/, $line);
    my $id = $comps[0];
    if (!defined($keepIds->{$id})) {
      $removedIds->{$id} = util::Constants::EMPTY_STR;
      next
    }
    $ofh->print("$line\n");
  }
  $fh->close;
  $ofh->close;
  ###
  ### Backup original file
  ###
  my $msgs = {};
  $msgs->{cmd} = $cmds->MOVE_FILE($aggregateFile, $backupFile);
  $cmds->executeCommand($msgs, $msgs->{cmd}, 'backup original file');
  $msgs->{cmd} = $cmds->MOVE_FILE($tmpFile, $aggregateFile);
  $cmds->executeCommand($msgs, $msgs->{cmd}, 'backup original file');
}
###
### Report removed Ids
###
my @removed_ids = sort keys %{$removedIds};
$error_mgr->printHeader("Removed IDs\n  count = " . scalar @removed_ids);
$error_mgr->printMsg(join(util::Constants::NEWLINE, @removed_ids));

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

removeFeatureIdsFromAggregate.pl

=head1 SYNOPSIS

   removeFeatureIdsFromAggregate.pl
     -P properties_module

This tools removes feature ids from the aggregate file.

=cut
