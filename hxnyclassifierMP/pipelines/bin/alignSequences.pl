#!/usr/bin/perl
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  alignSequence.pl
#
# Description:  This tool align na flu sequences from the database
#               and from files of various formats
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
use FileHandle;
use Getopt::Std;
use Pod::Usage;

use Bio::AlignIO;
use Bio::Seq;
use Bio::SeqIO;

use util::ErrMgr;
use util::ErrMsgs;
use util::Tools;

use parallel::ErrMsgs;
use parallel::Query;
use parallel::Utils;

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

my $error_mgr = new util::ErrMgr(parallel::ErrMsgs::ERROR_HEADER);
my $tools     = new util::Tools( $error_mgr, [ 'parallel', ] );
my $cmds      = $tools->cmds;
my $utils     = new parallel::Utils( $error_mgr, $tools );

################################################################################
#
#				   Constants
#
################################################################################
###
### Query Specific Properties from its Configuration
###
sub MAXELEMENTS_PROP     { return 'maxElements'; }
sub QUERYPARAMSUBS_PROP  { return 'queryParamSubs'; }
sub QUERYPARAMS_PROP     { return 'queryParams'; }
sub QUERYPREDICATES_PROP { return 'queryPredicates'; }
sub QUERYRESULTSORD_PROP { return 'queryResultsOrd'; }
sub QUERY_PROP           { return 'query'; }

sub QUERY_PROPERTIES {
  return (
    MAXELEMENTS_PROP,     QUERYPARAMSUBS_PROP, QUERYPARAMS_PROP,
    QUERYRESULTSORD_PROP, QUERY_PROP,          QUERYPREDICATES_PROP,
  );
}
###
### File types
###
sub AFA_TYPE    { return 'afa'; }
sub ALN_TYPE    { return 'aln'; }
sub FASTA_TYPE  { return 'fasta'; }
sub PHYLIP_TYPE { return 'phy'; }
sub TMP_TYPE    { return 'tmp'; }

sub INPUT_TYPE  { return 'input'; }
sub OUTPUT_TYPE { return 'output'; }
###
### Error Category
###
sub ERR_CAT { return util::ErrMsgs::PROG_CAT; }

################################################################################
#
#			    Local Functions
#
################################################################################

sub _getLocalDataProperties {
  my ($properties) = @_;

  my $lproperties = {};

  my ( $dataConfig, $loadingType, $loaded ) =
    $tools->newConfigParams( $properties->{dataConfig} );
  ###
  ### Get the properties specific class
  ###
  foreach my $property ( keys %{$properties} ) {
    my $val = $properties->{$property};
    if ( util::Constants::EMPTY_LINE($val) ) {
      $val = $dataConfig->getProperty($property);
    }
    $lproperties->{$property} = $val;
  }
  ###
  ### Get the properties specific to the query properties
  ###
  foreach my $property (QUERY_PROPERTIES) {
    $lproperties->{$property} = $dataConfig->getProperty($property);
  }

  return $lproperties;

}

sub _fasta2ClustalalW {
  my ( $fasta_file, $clustalw_file ) = @_;

  eval {
    my $in =
      Bio::AlignIO->new( '-file' => $fasta_file, '-format' => FASTA_TYPE );
    my $out = Bio::AlignIO->new(
      '-file'   => ">$clustalw_file",
      '-format' => 'clustalw'
    );
    while ( my $aln = $in->next_aln() ) { $out->write_aln($aln); }
  };
  my $status = $@;
  $status =
    ( defined($status) && $status )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  $error_mgr->exitProgram(
    ERR_CAT, 1,
    [
      'convert to clustalw format', FASTA_TYPE,
      $fasta_file,                  "error converting to file $clustalw_file",
    ],
    $status
  );
  return $status;
}

sub _createFile {
  my ( $properties, $suffix ) = @_;

  my @array = ();
  foreach my $comp ( 'subtype', 'host', 'segment', 'country' ) {
    my $val = $properties->{$comp};
    next if ( util::Constants::EMPTY_LINE($val) );
    push( @array, $val );
  }

  return join( util::Constants::SLASH,
    $properties->{workspaceRoot},
    join( util::Constants::DOT,
      join( util::Constants::UNDERSCORE, @array ), $suffix
    )
  );
}

sub _openFile {
  my ( $file, $mode, $return_status ) = @_;
  ###
  ### Set mode and return_status
  ###
  $mode = util::Constants::EMPTY_LINE($mode) ? '>' : $mode;
  $return_status =
    ( !util::Constants::EMPTY_LINE($return_status) && $return_status )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  ###
  ### Open file handle
  ###
  my $fh         = new FileHandle;
  my $status     = !$fh->open( $file, $mode );
  my $status_msg = $!;
  $status =
    ( defined($status) && $status )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  $fh->autoflush(util::Constants::TRUE)
    if ( !$status && ( $mode eq '>' || $mode eq '>>' ) );
  ###
  ### return file handle and status if requested
  ###
  return ( $fh, $status ) if ($return_status);
  ###
  ### return file handle only if there was no error
  ###
  $error_mgr->exitProgram( ERR_CAT, 1, [ $mode, 'text', $file, $status_msg ],
    $status );
  return $fh;
}

sub _readFasta {
  my ( $db_dups, $db_seqs, $seqs, $fh ) = @_;

  my $fasta = new Bio::SeqIO( -fh => $fh, -format => FASTA_TYPE );
  while ( my $seq = $fasta->next_seq ) {
    my $acc = $seq->display_id;
    my $seq = $seq->seq;
    $error_mgr->printMsg("fasta $acc");
    if ( defined( $db_seqs->{$acc} ) ) {
      $db_dups->{$acc} = util::Constants::EMPTY_STR;
      $error_mgr->printMsg("  $acc appeared in database");
      delete( $db_seqs->{$acc} );
    }
    $seqs->{$acc} = { acc => $acc, seq => $seq, };
  }
  $fh->close;
}

sub _readPhylip {
  my ( $db_dups, $db_seqs, $seqs, $fh ) = @_;
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    next if ( util::Constants::EMPTY_LINE($line) || $line =~ /^\d+\s+\d+$/ );
    my ( $acc, $seq ) = split( /\s+/, $line );
    $error_mgr->printMsg("phylip $acc");
    if ( defined( $db_seqs->{$acc} ) ) {
      $db_dups->{$acc} = util::Constants::EMPTY_STR;
      $error_mgr->printMsg("  $acc appeared in database");
      delete( $db_seqs->{$acc} );
    }
    $seqs->{$acc} = { acc => $acc, seq => $seq, };
  }
}

sub _getSeqInfo {
  my ( $db_dups, $db_seqs, $seqs, $path, $format ) = @_;

  my $fh = _openFile( $path, '<' );
  _readPhylip( $db_dups, $db_seqs, $seqs, $fh ) if ( $format eq PHYLIP_TYPE );
  _readFasta( $db_dups, $db_seqs, $seqs, $fh ) if ( $format eq FASTA_TYPE );
  $fh->close;
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
  $tools->setContextWithoutOpenLogging(
    $opt_P,

    'clustalWPath',
    'clusterAlignPath',
    'country',
    'dataConfig',
    'databaseName',
    'datasetName',
    'host',
    'musclePath',
    'password',
    'profileSeqs',
    'runTool',
    'schemaOwner',
    'segment',
    'serverType',
    'subtype',
    'uclusterPath',
    'userName',

    $tools->getPropertySet($opt_P)
  )
);

my $run_version = $tools->cmds->TMP_FILE('align');
$properties{workspaceRoot} =
  join( util::Constants::SLASH, $properties{workspaceRoot}, $run_version );
$cmds->createDirectory(
  $properties{workspaceRoot},
  'creating workspace',
  util::Constants::TRUE
);

my $logFile = join( util::Constants::SLASH,
  $tools->executionDir,
  join( util::Constants::DOT, $properties{datasetName}, $run_version, 'log' ) );
$tools->openLoggingWithLogFile( $logFile, undef, util::Constants::FALSE );

################################################################################
#
#				Main Program
#
################################################################################
###
### Set execution focus
###
chdir( $properties{workspaceRoot} );
###
### Create Files
###
my $dbd_file  = _createFile( \%properties, 'dbdups' );
my $dup_file  = _createFile( \%properties, 'dups' );
my $prof_file = _createFile( \%properties, 'profile' );
###
### Get Database data
###
my $db_seqs = {};
my $query   = new parallel::Query( undef, $error_mgr, $tools );

foreach my $datum ( $query->getData( _getLocalDataProperties( \%properties ) ) )
{
  $error_mgr->printMsg( "db " . $datum->{ncbiacc} );
  $db_seqs->{ $datum->{ncbiacc} } =
    { acc => $datum->{ncbiacc}, seq => $datum->{seq}, };
}
###
### Read the existing sequences (they may override the db sequences)
###
my $dups_with_db = {};
my $profile_seqs = {};
my $file         = $properties{profileSeqs};
my $path         = $tools->setWorkspaceForProperty( $file->{path} );
my $format       = $file->{format};
_getSeqInfo( $dups_with_db, $db_seqs, $profile_seqs, $path, $format );
my $infix = basename( $file->{path} );
$infix =~ s/\.$format$//;
###
### Create profile_file
###
my $fh = _openFile($prof_file);
my $profileSeq = new Bio::SeqIO( -fh => $fh, -format => FASTA_TYPE );
$profileSeq->width(10000);

foreach my $acc ( sort keys %{$profile_seqs} ) {
  my $datum = $profile_seqs->{$acc};
  my $bioSeq = new Bio::Seq( -display_id => "$acc", -seq => $datum->{seq} );
  $profileSeq->write_seq($bioSeq);
}
$fh->close;
###
### Print duplicates with database
###
my $dbfh = _openFile($dbd_file);
foreach my $acc ( sort keys %{$dups_with_db} ) {
  $dbfh->print("$acc\n");
}
$dbfh->close;
###
### Determine dups in db data so as to run
### it only once
###
my $fdb_seqs = {};
my $db_dups  = {};
foreach my $acc ( keys %{$db_seqs} ) {
  my $seq = $db_seqs->{$acc}->{seq};
  if ( !defined( $db_dups->{$seq} ) ) {
    $fdb_seqs->{$acc} = $db_seqs->{$acc};
    $db_dups->{$seq}  = {
      first  => $acc,
      others => [],
    };
  }
  else {
    push( @{ $db_dups->{$seq}->{others} }, $acc );
  }
}
###
### Generate duplicates file so that only run once
###
my $dfh = _openFile($dup_file);
foreach my $dup ( values %{$db_dups} ) {
  next if ( scalar @{ $dup->{others} } == 0 );
  $dfh->print(
    join( util::Constants::TAB, $dup->{first}, @{ $dup->{others} } )
      . util::Constants::NEWLINE );
}
$dfh->close;
###
### Run tool
###
my $status = util::Constants::FALSE;
if ( $properties{runTool} eq 'clustalWPath' ) {
  foreach my $acc ( sort keys %{$fdb_seqs} ) {
    my $datum = $fdb_seqs->{$acc};

    my $afa_file = join( util::Constants::DOT, $acc, OUTPUT_TYPE, AFA_TYPE );
    my $aln_file = join( util::Constants::DOT, $acc, OUTPUT_TYPE, ALN_TYPE );
    my $na_file  = join( util::Constants::DOT, $acc, INPUT_TYPE,  FASTA_TYPE );
    my $pafa_file =
      join( util::Constants::DOT, $acc, OUTPUT_TYPE, $infix, AFA_TYPE );
    my $tmp_file = join( util::Constants::DOT, $acc, TMP_TYPE );

    my $fh = _openFile($na_file);
    my $fastaSeq = new Bio::SeqIO( -fh => $fh, -format => FASTA_TYPE );
    $fastaSeq->width(10000);
    my $bioSeq = new Bio::Seq( -display_id => "$acc", -seq => $datum->{seq} );
    $fastaSeq->write_seq($bioSeq);
    $fh->close;

    my $msgs =
      {   cmd => $properties{ $properties{runTool} }
        . " -type=dna -profile -output=fasta "
        . " -profile1=$prof_file -profile2=$na_file  -outfile=$afa_file", };
    $status = $cmds->executeCommand( $msgs, $msgs->{cmd}, 'running clustalw' );
    $error_mgr->printMsg("Error running clustalw") if ($status);
    if ( !$status ) {
      $status =
        _fasta2ClustalalW( $afa_file, $aln_file )
        ? util::Constants::TRUE
        : util::Constants::FALSE;
      next if ($status);
      my $ofh     = _openFile($tmp_file);
      my $ofasta  = new Bio::SeqIO( -fh => $ofh, -format => FASTA_TYPE );
      my $opfh    = _openFile($pafa_file);
      my $opfasta = new Bio::SeqIO( -fh => $opfh, -format => FASTA_TYPE );

      my $fh = _openFile( $afa_file, '<' );
      my $fasta = new Bio::SeqIO( -fh => $fh, -format => FASTA_TYPE );
      while ( my $seq = $fasta->next_seq ) {
        my $the_acc = $seq->display_id;
        $ofasta->write_seq($seq) if ( $the_acc eq $acc );
        $opfasta->write_seq($seq) if ( $the_acc ne $acc );
      }
      $fh->close;
      $ofh->close;
      $opfh->close;
      $msgs->{cmd} = $cmds->MOVE_FILE( $tmp_file, $afa_file );
      $status =
        $cmds->executeCommand( $msgs, $msgs->{cmd}, 'copying temporary file' );
      $error_mgr->printMsg("Error copying files") if ($status);
    }
  }
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

alignSequence.pl

=head1 SYNOPSIS

   alignSequence.pl
     -P config_params_module

This tool align na flu sequences from the database
and from files of various formats

=cut
