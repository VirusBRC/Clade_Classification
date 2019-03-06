#!/usr/bin/perl
use lib "/opt/tools/hxnyclassifierMP/pipelines/lib";
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  runHxNyClustalwClassifier.pl
#
# Description:  This tools runs one sequence for the HxNy classifier
#               after it first aligns the reference fasta sequences
#               and the accession sequence using clustalw.
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
use Getopt::Std;
use Pod::Usage;

use Bio::Seq;
use Bio::SeqIO;

use ncbi::ErrMsgs;

use util::Constants;
use util::ErrMgr;
use util::Tools;

use parallel::Utils;

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
my $tools     = new util::Tools( $error_mgr, [ 'parallel', 'ncbi', ] );
my $utils     = new parallel::Utils( $error_mgr, $tools );
my $cmds      = $tools->cmds;

################################################################################
#
#			            Constants
#
################################################################################
###
### File types
###
sub AFA_TYPE     { return 'afa'; }
sub FASTA_TYPE   { return 'fasta'; }
sub PROFILE_TYPE { return 'profile'; }
sub SEQS_TYPE    { return 'seqs'; }

sub INPUT_TYPE  { return 'input'; }
sub OUTPUT_TYPE { return 'output'; }

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
    $opt_P,

    'classifierConfig',
    'classifierPerlLib',
    'classifierStatus',
    'classifierTool',
    'clustalWPath',
    'clustalwStatus',
    'gbAccession',
    'naSequenceId',
    'profileFasta',
    'seqOut',
    'sequence',
    'yearDate',
    'workspaceRoot'
  )
);

################################################################################
#
#				Main Program
#
################################################################################

my $acc           = $properties{gbAccession};
my $naSequenceId  = $properties{naSequenceId};
my $profileFasta  = $properties{profileFasta};
my $seqOut        = $properties{seqOut};
my $workspaceRoot = $properties{workspaceRoot};

$error_mgr->printHeader("Processing Sequence\n($acc, $naSequenceId)");
chdir($workspaceRoot);
###
### files
###
my $afa_file = join( util::Constants::DOT, OUTPUT_TYPE, AFA_TYPE );
my $na_file  = join( util::Constants::DOT, INPUT_TYPE,  FASTA_TYPE );
my $pafa_file =
  join( util::Constants::DOT, OUTPUT_TYPE, PROFILE_TYPE, AFA_TYPE );
my $seqs_file = join( util::Constants::SLASH,
  $workspaceRoot, join( util::Constants::DOT, SEQS_TYPE, AFA_TYPE ) );

my $fh = $utils->openFile($na_file);
my $fastaSeq = new Bio::SeqIO( -fh => $fh, -format => FASTA_TYPE );
$fastaSeq->width(1000);
my $bioSeq = new Bio::Seq(
  -display_id => $acc,
  -seq        => $properties{sequence}
);
$fastaSeq->write_seq($bioSeq);
$fh->close;
###
### Run clustalw using the profile
###
my $msgs = {
  cmd => join( util::Constants::SPACE,
    $properties{clustalWPath}, '-type=dna',
    '-profile',                '-output=fasta',
    "-profile1=$profileFasta", "-profile2=$na_file",
    "-outfile=$afa_file",      '> clustalw.std',
    '2> clustalw.err'
  ),
};
my $status = $cmds->executeCommand( $msgs, $msgs->{cmd}, 'running clustalw' );
$tools->setStatus( $status ? $tools->FAILED : $tools->SUCCEEDED );
$tools->saveStatus( $properties{clustalwStatus} );

if ( !$status ) {
  ###
  ### Get file for classifier
  ###
  my $ifh = $utils->openFile( $afa_file, '<' );
  my $ifasta  = new Bio::SeqIO( -fh => $ifh, -format => FASTA_TYPE );
  my $opfh    = $utils->openFile($pafa_file);
  my $opfasta = new Bio::SeqIO( -fh => $opfh, -format => FASTA_TYPE );
  my $sfh     = $utils->openFile($seqs_file);
  my $sfasta  = new Bio::SeqIO( -fh => $sfh, -format => FASTA_TYPE );
  while ( my $seq = $ifasta->next_seq ) {
    my $the_acc = $seq->display_id;
    $sfasta->write_seq($seq) if ( $the_acc eq $acc );
    $opfasta->write_seq($seq) if ( $the_acc ne $acc );
  }
  $ifh->close;
  $opfh->close;
  $sfh->close;
  ###
  ### Run classifier
  ###
  $ENV{PERL5LIB} =
    $properties{classifierPerlLib} . util::Constants::COLON . $ENV{PERL5LIB};
  my $msgs = {
    cmd => join( util::Constants::SPACE,
      $properties{classifierTool}, $properties{classifierConfig},
      $properties{yearDate},       $seqs_file,
      $seqOut,                     '> classifier.std',
      '2> classifier.err'
    ),
  };
  my $status =
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'running classifier' );
  $tools->setStatus( $status ? $tools->FAILED : $tools->SUCCEEDED );
  $tools->saveStatus( $properties{classifierStatus} );
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

runHxNyClustalwClassifier.pl

=head1 SYNOPSIS

   runHxNyClustalwClassifier.pl
     -P config_params_module

This tools runs one sequence for the HxNy classifier
after it first aligns the reference fasta sequences
and the accession sequence using clustalw.

=cut
