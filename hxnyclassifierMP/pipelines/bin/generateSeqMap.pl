#!/usr/bin/perl -w
######################################################################
#                  Copyright (c) 2011 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  partitionByFamily.pl
#
# Description:  This tools generates the seq map for a set of files.
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
use File::Basename;
use File::Find ();
use FileHandle;
use Getopt::Std;
use Pod::Usage;

use util::ErrMgr;
use util::ErrMsgs;
use util::Tools;

use Bio::SeqIO;

use parallel::ErrMsgs;
use parallel::File::DataFiles;
use parallel::File::OrthologMap;

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
###
### for the convenience of &wanted calls,
### including -eval statements:
###
use vars qw(*FIND_NAME
  *FIND_DIR
  *FIND_PRUNE);
*FIND_NAME  = *File::Find::name;
*FIND_DIR   = *File::Find::dir;
*FIND_PRUNE = *File::Find::prune;

my @_FILES_ = ();

sub _filesWanted {
  my ( $dev, $ino, $mode, $nlink, $uid, $gid );
  ( ( $dev, $ino, $mode, $nlink, $uid, $gid ) = lstat($_) )
    && -f _
    && /^.+\.faa\z/s
    && push( @_FILES_, $FIND_NAME );
}

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
my %properties =
  $tools->setWorkspaceProperty(
  $tools->setContext( $opt_P, 'dataFiles', 'seqMapFile', 'workspaceRoot' ) );

my $seqMapFile = $properties{seqMapFile};
my $dataFiles  =
  new parallel::File::DataFiles( $properties{dataFiles}, $error_mgr );
$dataFiles->readFile;

################################################################################
#
#				Main Program
#
################################################################################
###
### Get the id to family name map
###
foreach my $family_name ( $dataFiles->getPrefixes ) {
  my $dir = $dataFiles->getDataFile($family_name);
  $error_mgr->printHeader( "Generating Seq Map\n"
      . "  family_name = $family_name\n"
      . "  dir         = $dir" );
  chdir($dir);
  @_FILES_ = ();
  File::Find::find( { wanted => \&_filesWanted }, util::Constants::DOT );
  my $faaSuffix = 'faa';
  my $mapFile   = join( util::Constants::SLASH, $dir, $seqMapFile );
  my $map       = new parallel::File::OrthologMap( $mapFile, $error_mgr );

  foreach my $faaFile (@_FILES_) {
    my $name = basename($faaFile);
    $name    =~ s/\.$faaSuffix$//;
    $faaFile =~ s/^\.\///;
    $faaFile = join( util::Constants::SLASH, $dir, $faaFile );
    $error_mgr->printMsg("faaFile = $faaFile ($name)");
    my $fh = new FileHandle;
    $fh->open( $faaFile, '<' );
    my $fasta = new Bio::SeqIO( -fh => $fh, -format => "fasta" );

    while ( my $seq = $fasta->next_seq ) {
      my $id = $seq->display_id;
      $error_mgr->printMsg("$id");
      my @row          = split( /\|/, $id );
      my $gb_accession = $row[1];
      my $gi           = $row[3];
      my $swissprot    = $row[5];
      $map->addSequence( $gb_accession, $gi, $name, $swissprot,
        $map->READ_STATUS );
    }
    $fh->close;
  }
  $map->writeFile;
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

generateSeqMap.pl

=head1 SYNOPSIS

   generateSeqMap.pl
     -P properties_module

This tools generates the seq map for a set of files.

=cut
