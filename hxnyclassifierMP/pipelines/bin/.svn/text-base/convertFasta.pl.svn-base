#!/usr/bin/perl -w
######################################################################
#                  Copyright (c) 2011 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  convertFasta.pl
#
# Description:  This tools converts the fasta files to have correct organism.
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

use Bio::Seq;
use Bio::SeqIO;

use parallel::ErrMsgs;
use parallel::File::DataFiles;
use parallel::File::OrthologGroup;
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
    && /^.+\.fasta\z/s
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
my %properties = $tools->setWorkspaceProperty(
  $tools->setContext(
    $opt_P,              'blastComputeDir',
    'compliantFastaDir', 'computeDirectory',
    'dataFiles',         'goodProteinFasta',
    'groupFile',         'seqMapFile',
    'workspaceRoot'
  )
);

my $blastComputeDir   = $properties{blastComputeDir};
my $compliantFastaDir = $properties{compliantFastaDir};
my $computeDirectory  = $properties{computeDirectory};
my $goodProteinFasta  = $properties{goodProteinFasta};
my $groupFile         = $properties{groupFile};
my $seqMapFile        = $properties{seqMapFile};

my $dataFiles =
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
my $fastaSuffix = 'fasta';
foreach my $family_name ( $dataFiles->getPrefixes ) {
  my $dir = $dataFiles->getDataFile($family_name);
  $error_mgr->printHeader( "Correcting Compliant Fasta Files\n"
      . "  family_name = $family_name\n"
      . "  dir         = $dir" );
  my $mapFile = join( util::Constants::SLASH, $dir, $seqMapFile );
  my $map = new parallel::File::OrthologMap( $mapFile, $error_mgr );
  $map->readFile;
  my $computeDir =
    $tools->setWorkspaceForProperty( $computeDirectory->{$family_name} );

  my $compliantDir =
    join( util::Constants::SLASH, $computeDir, $compliantFastaDir );
  chdir($compliantDir);
  @_FILES_ = ();
  File::Find::find( { wanted => \&_filesWanted }, util::Constants::DOT );
  my $newCompliantDir = $cmds->createDirectory(
    join( util::Constants::DOT, $compliantDir, 'NEW' ),
    'creating corrected compliant directory',
    util::Constants::TRUE
  );

  foreach my $fastaFile (@_FILES_) {
    $fastaFile =~ s/^\.\///;
    $fastaFile = join( util::Constants::SLASH, $compliantDir, $fastaFile );
    $error_mgr->printMsg("fastaFile = $fastaFile");
    my $fh = new FileHandle;
    $fh->open( $fastaFile, '<' );
    my $fasta     = new Bio::SeqIO( -fh => $fh, -format => "fasta" );
    my $newFasta  = undef;
    my $nfh       = undef;
    my $nOrganism = undef;
    while ( my $seq = $fasta->next_seq ) {
      my $id = $seq->display_id;
      $error_mgr->printMsg("$id");
      my ( $organism, $gi ) = split( /\|/, $id );
      if ( !defined($newFasta) ) {
        my $data = $map->getDataByGi($gi);
        $nOrganism = $data->{ $map->ORGANISM_COL };
        my $newFastaFile = join( util::Constants::SLASH,
          $newCompliantDir,
          join( util::Constants::DOT, $nOrganism, $fastaSuffix ) );
        $nfh = new FileHandle;
        $nfh->open( $newFastaFile, '>' );
        $newFasta = new Bio::SeqIO( -fh => $nfh, -format => "fasta" );
      }
      my $bioSeq = new Bio::Seq(
        -display_id => join( util::Constants::PIPE, $nOrganism, $gi ),
        -seq        => uc( $seq->seq )
      );
      my $length = length( $seq->seq ) + 1;
      $newFasta->width($length);
      $newFasta->write_seq($bioSeq);
      $nfh->print("\n");
    }
    $nfh->close if ( defined($nfh) );
    $fh->close;
  }
  ###
  ### Convert Blast Fasta File (groupProteins.fasta)
  ###
  my $blastFastaFile = join( util::Constants::SLASH,
    $computeDir, $blastComputeDir, $goodProteinFasta );
  $error_mgr->printHeader( "Correcting Blast Fasta File\n"
      . "  family_name = $family_name\n"
      . "  file        = $blastFastaFile" );
  my $fh = new FileHandle;
  $fh->open( $blastFastaFile, '<' );
  my $fasta = new Bio::SeqIO( -fh => $fh, -format => "fasta" );
  my $newBlastFastaFile = join( util::Constants::DOT, $blastFastaFile, 'NEW' );
  my $nfh = new FileHandle;
  $nfh->open( $newBlastFastaFile, '>' );
  my $newFasta = new Bio::SeqIO( -fh => $nfh, -format => "fasta" );
  $newFasta->width(10000);

  while ( my $seq = $fasta->next_seq ) {
    my $id = $seq->display_id;
    $error_mgr->printMsg("$id");
    my ( $organism, $gi ) = split( /\|/, $id );
    my $data      = $map->getDataByGi($gi);
    my $nOrganism = $data->{ $map->ORGANISM_COL };
    my $bioSeq    = new Bio::Seq(
      -display_id => join( util::Constants::PIPE, $nOrganism, $gi ),
      -seq        => uc( $seq->seq )
    );
    $newFasta->write_seq($bioSeq);
    $nfh->print("\n");
  }
  $nfh->close;
  $fh->close;

  my $group_file = join( util::Constants::SLASH, $computeDir, $groupFile );
  $error_mgr->printHeader( "Correcting Group File\n"
      . "  family_name = $family_name\n"
      . "  file        = $group_file" );
  my $groups = new parallel::File::OrthologGroup( $group_file, $error_mgr );
  $groups->readFile;
  my $newGroupFile = join( util::Constants::DOT, $group_file, 'NEW' );
  my $ngroups = new parallel::File::OrthologGroup( $newGroupFile, $error_mgr );

  foreach my $group_id ( $groups->getGroupIds ) {
    foreach my $item ( $groups->getGroupData($group_id) ) {
      my $data     = $map->getDataByGi( $item->{ $groups->GI_COL } );
      my $organism = $data->{ $map->ORGANISM_COL };
      $ngroups->addItem( $group_id, $organism, $item->{ $groups->GI_COL } );
    }
  }
  $ngroups->writeFile;
  my $newOutGroupFile = join( util::Constants::DOT, $group_file, 'out', 'NEW' );
  $ngroups->writeLinearFile($newOutGroupFile);
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

convertFasta.pl

=head1 SYNOPSIS

   convertFasta.pl
     -P properties_module

This tools converts the fasta files to have correct organism.

=cut
