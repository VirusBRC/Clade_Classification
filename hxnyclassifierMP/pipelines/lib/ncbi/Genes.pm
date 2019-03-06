package ncbi::Genes;
######################################################################
#                  Copyright (c) 2014 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use FileHandle;
use Pod::Usage;
use ncbi::ErrMsgs;
use ncbi::GeneticCode;
use ncbi::Loader;

use parallel::Query;
use util::Constants;
use util::PathSpecifics;
use util::Statistics;
use util::Table;
use util::TableData;

use Bio::Seq;
use Bio::SeqIO;

use fields qw(
  discard
  discard_file
  error_mgr
  genetic_code
  fhs
  ncbi_utils
  out_files
  ref_data
  run_dir
  seq_len
  specifics
  statistic
  tools
  utils
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Gene Subdirectory
###
sub SEQ_FILE { return 'seq'; }
###
### Statistic Tag/Values
###
sub SEQ_TAG { return 'Seq Type'; }
sub SEQ_VALS { return [ 'Ambiguous', 'Unambiguous', ]; }

sub GENETYPE_TAG { return 'Gene Type'; }

sub FLTUYPE_TAG { return 'Influenza Type'; }
sub FLTUYPE_VALS { return [ 'A', 'B', 'C', 'O', ]; }

sub VARIANT_TAG { return 'Motif Variant'; }
###
### Sequence Length
###
sub COLS_ORD { return ( 'type', 'num', 'min', 'max', 'av' ); }

sub COLS {
  return (
    'type' => 'File Type',
    'num'  => 'Num Sequences',
    'min'  => 'Minimum Length',
    'max'  => 'Maximum Length',
    'av'   => 'Average Length'
  );
}
###
### Seq/File Types
###
sub AMBIGUOUS_TYPE   { return 'Ambiguous'; }
sub DISCARD_TYPE     { return 'discard'; }
sub ERROR_TYPE       { return 'Error'; }
sub LOADED_TYPE      { return 'loaded'; }
sub MOTIF_TYPE       { return 'Motif'; }
sub NATIVE_TYPE      { return 'Native'; }
sub SID_TYPE         { return 'sid'; }
sub TRANSLATION_TYPE { return 'Translation'; }
sub UNAMBIGUOUS_TYPE { return 'Unambiguous'; }
###
### Gene Names
###
sub UNKNOWN_GENE_NAME { return 'Unknown'; }

sub NATIVE_NAME { return 'Native'; }
sub OTHER_NAME  { return 'Other'; }
###
### Variant Names
###
sub NONE_VARIANT_NAME { return 'None'; }
###
### Queries
###
sub SEQID_QUERY { return 'annotFeatSeqIdQuery'; }

sub ANNOTATION_QUERY { return 'annotationQuery'; }
sub STG_QUERY        { return 'stgInsertQuery'; }
sub QUERIES          { return [ STG_QUERY, ANNOTATION_QUERY, ]; }
###
### Alignment
###
sub FASTA_TYPE { return 'fasta'; }
###
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::GENES_CAT; }

################################################################################
#
#				   Private Methods
#
################################################################################

sub _determineSeqType {
  my ncbi::Genes $this = shift;
  my ($seq) = @_;
  if ( $seq =~ /^[CTAG]+$/ ) {
    return UNAMBIGUOUS_TYPE;
  }
  else {
    return AMBIGUOUS_TYPE;
  }
}

sub _filterData {
  my ncbi::Genes $this = shift;
  my (@data) = @_;

  my @fdata       = ();
  my $fluTypeVals = FLTUYPE_VALS;
  foreach my $struct (@data) {
    my $org_name = $struct->{org_genus};
    my $type     = undef;
    foreach my $t ( @{$fluTypeVals} ) {
      if ( $t eq 'O' ) {
        $type = $t;
        last;
      }
      my $pattern = "Influenzavirus $t";
      next if ( $org_name !~ /$pattern/i );
      $type = $t;
      last;
    }
    ###
    ### Compute only Influenza A Virus
    ###
    next if ( $type ne 'A' );
    $struct->{type} = $type;
    $struct->{seq} =~ s/~/-/g;
    push( @fdata, $struct );
  }
  return @fdata;
}

sub _getFile {
  my ncbi::Genes $this = shift;
  my ($type) = @_;

  my $ncbi_utils = $this->{ncbi_utils};

  return join( util::Constants::SLASH,
    $this->{run_dir}, join( util::Constants::DOT, SEQ_FILE, $type ) );
}

sub _getFh {
  my ncbi::Genes $this = shift;
  my ( $type, $no_header ) = @_;

  $no_header =
    ( !util::Constants::EMPTY_LINE($no_header) && $no_header )
    ? util::Constants::TRUE
    : util::Constants::FALSE;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  return $this->{fhs}->{$type} if ( defined( $this->{fhs}->{$type} ) );
  my $file = $this->_getFile($type);
  $this->{error_mgr}->printMsg("opening $type\n$file");
  $this->{fhs}->{$type} = new FileHandle;
  $this->{fhs}->{$type}->open( $file, '>' );
  $this->{fhs}->{$type}->autoflush(util::Constants::TRUE);
  $this->{fhs}->{$type}->print(
    join( util::Constants::TAB, @{ $properties->{&STG_QUERY}->{queryParams} },
      )
      . util::Constants::NEWLINE
  ) if ( !$no_header );
  return $this->{fhs}->{$type};
}

sub _closeFhs {
  my ncbi::Genes $this = shift;

  my $fhs = $this->{fhs};
  foreach my $variant ( keys %{$fhs} ) {
    $fhs->{$variant}->close;
    delete( $fhs->{$variant} );
  }
}

sub _computeStats {
  my ncbi::Genes $this = shift;
  my ( $seqType, $gene, $fluType, $variant, $fileType, $seqLen ) = @_;

  $this->{statistic}->increment(
    SEQ_TAG,     $seqType, GENETYPE_TAG, $gene,
    FLTUYPE_TAG, $fluType, VARIANT_TAG,  $variant
  );
  my $seq_len = $this->{seq_len};
  if ( !defined( $seq_len->{$fileType} ) ) {
    $seq_len->{$fileType} = {
      type  => $fileType,
      min   => 9999999,
      max   => 0,
      num   => 0,
      av    => 0,
      total => 0,
    };
  }
  $seq_len = $seq_len->{$fileType};
  $seq_len->{num}++;
  $seq_len->{total} += $seqLen;
  if ( $seqLen < $seq_len->{min} ) { $seq_len->{min} = $seqLen; }
  if ( $seqLen > $seq_len->{max} ) { $seq_len->{max} = $seqLen; }
}

################################################################################
#
#                                  Motif Processing
#
################################################################################

sub _getProtein {
  my ncbi::Genes $this = shift;
  my ($seq) = @_;

  my $geneticCode = $this->{genetic_code};
  my $i           = length($seq);
  my @sseq        = split( //, $seq );
  my @aminoacids  = ();
  my $m           = 0;
  while ( $m <= $i - 3 ) {
    my $k = $m;
    my $l = $m + 2;
    push( @aminoacids, join( util::Constants::EMPTY_STR, @sseq[ $k .. $l ] ) );
    $m = $l + 1;
  }

  my $start       = 0;
  my $end         = 0;
  my $aminoacids  = util::Constants::EMPTY_STR;
  my $found_start = util::Constants::FALSE;
  my $found_stop  = util::Constants::FALSE;
  foreach my $codon_index ( 0 .. $#aminoacids ) {
    my $aminoacid = $geneticCode->getAminoAcid( $aminoacids[$codon_index] );
    $end += 3;
    if ( $codon_index == 0 && $aminoacid eq $geneticCode->START_CODON ) {
      $found_start = util::Constants::TRUE;
      $start++;
    }
    elsif ( $aminoacid eq $geneticCode->STOP_CODON ) {
      $found_stop = util::Constants::TRUE;
      last;
    }
    $aminoacids .= $aminoacid;
  }
  if ( !$found_stop ) {
    $end = util::Constants::HYPHEN;
    $this->{error_mgr}->printMsg("Cannot find STOP");
  }
  if ( !$found_start ) {
    $start      = undef;
    $end        = undef;
    $aminoacids = util::Constants::EMPTY_STR;
    $this->{error_mgr}->printMsg("Cannot find START");
  }
  $this->{error_mgr}->printMsg("protein ($start, $end) = $aminoacids")
    if ($found_start);
  return ( $start, $end, $aminoacids );
}

sub _getStrictPrefixProtein {
  my ncbi::Genes $this = shift;
  my ($seq) = @_;

  my $geneticCode = $this->{genetic_code};
  my $i           = length($seq);
  my @sseq        = split( //, $seq );
  my @aminoacids  = ();
  my $m           = 0;
  while ( $m <= $i - 3 ) {
    my $k = $m;
    my $l = $m + 2;
    push( @aminoacids, join( util::Constants::EMPTY_STR, @sseq[ $k .. $l ] ) );
    $m = $l + 1;
  }

  my $start       = 0;
  my $end         = 0;
  my $aminoacids  = util::Constants::EMPTY_STR;
  my $found_start = util::Constants::FALSE;
  foreach my $codon_index ( 0 .. $#aminoacids ) {
    my $aminoacid = $geneticCode->getAminoAcid( $aminoacids[$codon_index] );
    $end += 3;
    if ( $codon_index == 0 && $aminoacid eq $geneticCode->START_CODON ) {
      $found_start = util::Constants::TRUE;
      $start++;
    }
    $aminoacids .= $aminoacid;
  }
  if ( !$found_start ) {
    $start      = undef;
    $end        = undef;
    $aminoacids = util::Constants::EMPTY_STR;
    $this->{error_mgr}->printMsg("Cannot find START");
  }
  $this->{error_mgr}->printMsg("protein ($start, $end) = $aminoacids")
    if ($found_start);
  return ( $start, $end, $aminoacids );
}

sub _getPrefixProtein {
  my ncbi::Genes $this = shift;
  my ( $gap_info, $prefix, $ref_data ) = @_;

  my $geneticCode = $this->{genetic_code};

  my $i          = length($prefix);
  my @sprefix    = split( //, $prefix );
  my @aminoacids = ();
  my $remainder  = 0;
  my $non2gapped = $gap_info->{non2gapped};
  ###
  ### This is the start of the reference protein!
  ###
  my $pstart = undef;
  if ( defined($ref_data) ) {
    $pstart = $ref_data->{gap_info}->{non2gapped}->{ $ref_data->{pstart} - 1 };
  }

  while (
    $i >= 0
    && ( !defined($ref_data)
      || ( $non2gapped->{$i} >= $pstart ) )
    )
  {
    my $k = $i - 3;
    my $l = $i - 1;
    if ( ( defined($ref_data) && $k >= 0 && $non2gapped->{$k} < $pstart )
      || $k < 0 )
    {
      $remainder = $i;
      last;
    }
    unshift( @aminoacids,
      join( util::Constants::EMPTY_STR, @sprefix[ $k .. $l ] ) );
    $i = $k;
  }

  my $start = $remainder;
  my $end   = 0;
  $this->{error_mgr}->printMsg("remainder = $remainder");
  my $aminoacids  = util::Constants::EMPTY_STR;
  my $found_start = util::Constants::FALSE;
  foreach my $codon (@aminoacids) {
    my $aminoacid = $geneticCode->getAminoAcid($codon);
    if ( !$found_start && $aminoacid ne $geneticCode->START_CODON ) {
      $start += 3;
      next;
    }
    elsif ( !$found_start && $aminoacid eq $geneticCode->START_CODON ) {
      $start++;
      $end = $start + 2;
    }
    elsif ($found_start) {
      $end += 3;
    }
    $found_start = util::Constants::TRUE;
    $aminoacids .= $aminoacid;
  }
  if (
    defined($ref_data)
    && (
      ( $found_start && ( $end - $start + 1 ) < $ref_data->{prefix_len} )
      || ( !$found_start
        && length($prefix) - $remainder < $ref_data->{prefix_len} )
    )
    )
  {
    $found_start = util::Constants::TRUE;

    $aminoacids = util::Constants::EMPTY_STR;
    $start      = $remainder + 1;
    $end        = $remainder + 3 * scalar @aminoacids;
    foreach my $index ( 0 .. $#aminoacids ) {
      my $codon     = $aminoacids[$index];
      my $aminoacid = $geneticCode->getAminoAcid($codon);
      $aminoacids .= $aminoacid;
    }
  }
  if ( !$found_start ) {
    $start      = undef;
    $end        = undef;
    $aminoacids = util::Constants::EMPTY_STR;
    $this->{error_mgr}->printMsg("Cannot find START");
  }
  $this->{error_mgr}->printMsg("prefix ($start, $end) = $aminoacids")
    if ($found_start);
  ###
  ### $start and $end are 1-based relative coordinates to prefix length
  ###
  return ( $start, $end, $aminoacids );
}

sub _getSuffixProtein {
  my ncbi::Genes $this = shift;
  my ( $suffix, $start ) = @_;

  my $geneticCode = $this->{genetic_code};

  my $i          = length($suffix);
  my @ssuffix    = split( //, $suffix );
  my @aminoacids = ();
  my $m          = 0;
  while ( $m <= $i - 3 ) {
    my $k = $m;
    my $l = $m + 2;
    push( @aminoacids,
      join( util::Constants::EMPTY_STR, @ssuffix[ $k .. $l ] ) );
    $m = $l + 1;
  }

  my $end        = $start + 2;
  my $aminoacids = util::Constants::EMPTY_STR;
  my $found_last = util::Constants::FALSE;
  foreach my $codon (@aminoacids) {
    my $aminoacid = $geneticCode->getAminoAcid($codon);
    if ( $aminoacid eq $geneticCode->STOP_CODON ) {
      $found_last = util::Constants::TRUE;
      last;
    }
    $end += 3;
    $aminoacids .= $aminoacid;
  }
  if ( !$found_last ) {
    $start      = undef;
    $end        = undef;
    $aminoacids = util::Constants::EMPTY_STR;
    $this->{error_mgr}->printMsg("Cannot find END");
  }
  $this->{error_mgr}->printMsg("suffix ($start, $end) = $aminoacids")
    if ($found_last);
  ###
  ### $start and $end are 1-based absolute coordinates with respect to $start
  ###
  return ( $start, $end, $aminoacids );
}

sub _determineProtGiId {
  my ncbi::Genes $this = shift;
  my ( $gb_gi, $pstart, $send ) = @_;

  my $cds_start = defined($pstart) ? $pstart : util::Constants::HYPHEN;
  my $cds_end   = defined($send)   ? $send   : util::Constants::HYPHEN;

  my $protein_gi =
    join( util::Constants::UNDERSCORE, 'IRD', $gb_gi, $cds_start, $cds_end );
  my $protein_id = join( util::Constants::DOT, $protein_gi, '1' );
  return ( $protein_gi, $protein_id, $cds_start, $cds_end );
}

sub _determineSingleIntProt {
  my ncbi::Genes $this = shift;
  my ( $start, $end ) = @_;
  my $interval = util::Constants::EMPTY_STR;
  if ( defined($start) ) {
    $interval .= "${start}..${end}";
  }
  else {
    $interval .= "-..-";
  }
  return $interval;
}

sub _determineIntProt {
  my ncbi::Genes $this = shift;
  my ( $pstart, $pend, $paminoacids, $sstart, $send, $saminoacids ) = @_;
  my $interval = 'join(';
  $interval .=
    $this->_determineSingleIntProt( $pstart, $pend ) . util::Constants::COMMA;
  $interval .= $this->_determineSingleIntProt( $sstart, $send );
  $interval .= ')';
  my $protein = $paminoacids . $saminoacids;
  return ( $interval, $protein );
}

sub _getFastaFileName {
  my ncbi::Genes $this = shift;
  my ($acc)            = @_;
  my $file_name        = join( util::Constants::SLASH,
    $this->{run_dir}, join( util::Constants::DOT, $acc, FASTA_TYPE ) );
  return $file_name;
}

sub _createFastaFile {
  my ncbi::Genes $this = shift;
  my ( $seq, $acc ) = @_;
  my $file_name = $this->_getFastaFileName($acc);
  my $fh        = new FileHandle;
  $fh->open( $file_name, '>' );
  $fh->autoflush(util::Constants::TRUE);
  my $profile = new Bio::SeqIO( -fh => $fh, -format => FASTA_TYPE );
  $profile->width(10000);
  my $bioSeq = new Bio::Seq( -display_id => "$acc", -seq => $seq );
  $profile->write_seq($bioSeq);
  $fh->close;

  return $file_name;
}

sub _computeAlignments {
  my ncbi::Genes $this = shift;
  my ( $gap_info, $acc ) = @_;
  $this->{error_mgr}->printMsg("RE-ALIGNING SEQUENCES");
  my $cmds       = $this->{tools}->cmds;
  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $ref_data   = $this->{ref_data};

  my $seq     = $gap_info->{ungapped_seq};
  my $ref_seq = $ref_data->{gap_info}->{ungapped_seq};
  my $ref_acc = $ref_data->{gb_accession};

  my $ref_fasta = $this->_createFastaFile( $ref_seq, $ref_acc );
  my $seq_fasta = $this->_createFastaFile( $seq,     $acc );
  my $aligned_fasta = $this->_getFastaFileName('clustalw_aligned');
  ###
  ### Align the sequences
  ###
  my $cmd = join( util::Constants::SPACE,
    $properties->{clustalWPath}, '-output=fasta',
    '-align',                    '-gapopen=20',
    '-gapext=1',                 '-type=dna',
    "-profile1=$ref_fasta",      "-profile2=$seq_fasta",
    "-outfile=$aligned_fasta",   '>> clustalw.std',
    '2>> clustalw.err'
  );
  my $msgs = { cmd => $cmd, };
  my $status = $cmds->executeCommand( $msgs, $cmd, 'running clustalw' );
  unlink($ref_fasta);
  unlink($seq_fasta);
  if ($status) {
    $this->{error_mgr}->printMsg("Error running clustalw");
    unlink($aligned_fasta);
    return ( undef, undef );
  }
  ###
  ### Get the gapped sequences
  ###
  my $fh = new FileHandle;
  $fh->open( $aligned_fasta, '<' );
  my $fasta           = new Bio::SeqIO( -fh => $fh, -format => FASTA_TYPE );
  my $ref_aligned_seq = undef;
  my $aligned_seq     = undef;
  while ( my $seq = $fasta->next_seq ) {
    my $the_acc = $seq->display_id;
    if ( $the_acc eq $acc ) {
      $aligned_seq = $seq->seq;
    }
    elsif ( $the_acc eq $ref_acc ) {
      $ref_aligned_seq = $seq->seq;
    }
  }
  $fh->close;
  unlink($aligned_fasta);
  ###
  ### Regenerate the gap_info and ref_data
  ###
  my $new_gap_info = $ncbi_utils->calculateUngapped($aligned_seq);
  my $ref_gap_info = $ncbi_utils->calculateUngapped($ref_aligned_seq);
  my $new_ref_data =
    $this->findRefMotif( $ref_data->{gb_gi}, $ref_acc, $ref_gap_info );
  $new_ref_data->{gap_info} = $ref_gap_info;

  return ( $new_gap_info, $new_ref_data );
}

sub _getQueryProperties {
  my ncbi::Genes $this = shift;
  my ($query_properties) = @_;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  my $queryProperties = { %{$query_properties} };
  foreach my $property ( keys %{$properties} ) {
    $queryProperties->{$property} = $properties->{$property};
  }

  return $queryProperties;
}

sub _getRefData {
  my ncbi::Genes $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  $this->{ref_data} = undef;

  my $query = new parallel::Query( undef, $this->{error_mgr}, $this->{tools} );
  my @data = $this->_filterData(
    $query->getData(
      $this->_getQueryProperties( $properties->{referenceQuery} )
    )
  );
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 1, [ $properties->{referenceQuery}->{query}, ],
    $query->getErrorStatus );

  my $struct = $data[0];
  $this->{error_mgr}
    ->printHeader( "reference accession = " . $struct->{gb_accession} );
  $this->{tools}->printStruct( '$struct', $struct );
  my $gap_info = $ncbi_utils->calculateUngapped( $struct->{seq} );
  $this->{ref_data} =
    $this->findRefMotif( $struct->{gb_gi}, $struct->{gb_accession}, $gap_info );
  $this->{ref_data}->{gap_info} = $gap_info;
  $this->{tools}->printStruct( '$this->{ref_data}', $this->{ref_data} );
}

################################################################################
#
#                                  Discard Processing
#
################################################################################

sub _readDiscardFile {
  my ncbi::Genes $this = shift;

  my $discard_file = $this->{discard_file};

  $this->{discard} = {
    current => {},
    new     => {},
  };

  return if ( !-s $discard_file );
  $this->{error_mgr}->printHeader("Reading discards\n  file = $discard_file");
  my $fh = new FileHandle;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 2,
    [ 'read file', $discard_file, 'unable to read file', ],
    !$fh->open( $discard_file, '<' )
  );
  while ( !$fh->eof ) {
    my $na_sequence_id = $fh->getline;
    chomp($na_sequence_id);
    next if ( util::Constants::EMPTY_LINE($na_sequence_id) );
    $this->{error_mgr}->printMsg($na_sequence_id);
    $this->{discard}->{current}->{$na_sequence_id} = util::Constants::EMPTY_STR;
  }
  $fh->close;
}

sub _setDiscardFile {
  my ncbi::Genes $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  ###
  ### Set the final discard file
  ###
  $this->{discard_file} = getPath( $properties->{discardFile} );
  ###
  ### Set the working discard file
  ###
  my $discard_file = $this->_getFile(DISCARD_TYPE);
  $this->{out_files}->{&DISCARD_TYPE} = $discard_file;
  $ncbi_utils->resetFile( $discard_file, DISCARD_TYPE . " file" );
}

sub _discardFile {
  my ncbi::Genes $this = shift;

  return $this->{discard_file};
}

sub _getDiscardFile {
  my ncbi::Genes $this = shift;

  return $this->{out_files}->{&DISCARD_TYPE};
}

sub _inDiscardFile {
  my ncbi::Genes $this = shift;
  my ($struct) = @_;

  my $current = $this->{discard}->{current};
  my $new     = $this->{discard}->{new};

  return util::Constants::FALSE
    if ( !defined( $current->{ $struct->{na_sequence_id} } ) );
  $this->{error_mgr}->printMsg("Previously discarded, will discard");
  if ( !defined( $new->{ $struct->{na_sequence_id} } ) ) {
    $new->{ $struct->{na_sequence_id} } = util::Constants::EMPTY_STR;
    my $fh = $this->_getFh( DISCARD_TYPE, util::Constants::TRUE );
    $fh->print( $struct->{na_sequence_id} . "\n" );
  }
  return util::Constants::TRUE;
}

sub _addDiscardFile {
  my ncbi::Genes $this = shift;
  my ($struct) = @_;

  my $new = $this->{discard}->{new};

  $this->{error_mgr}->printMsg("Adding to discard");
  return if ( defined( $new->{ $struct->{na_sequence_id} } ) );
  $new->{ $struct->{na_sequence_id} } = util::Constants::EMPTY_STR;
  my $fh = $this->_getFh( DISCARD_TYPE, util::Constants::TRUE );
  $fh->print( $struct->{na_sequence_id} . "\n" );
}

sub _updateDiscardFile {
  my ncbi::Genes $this = shift;
  ###
  ### Now Update discard File
  ###
  ### 1.  Make backup current discard file
  ### 2.  Set discard file
  ###
  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $today_date = $properties->{todayDayDate};

  my $cmds = $this->{tools}->cmds;
  my $msgs = {};
  my $backupDiscardFile =
    join( util::Constants::DOT, $this->_discardFile, $today_date );
  if ( $ncbi_utils->isMonthly ) {
    $backupDiscardFile .= util::Constants::DOT . 'monthly';
  }
  my $sourceFile = $this->_getDiscardFile;
  unlink($backupDiscardFile) if ( -e $backupDiscardFile );
  $msgs->{cmd} = $cmds->COPY_FILE( $sourceFile, $backupDiscardFile );
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 2,
    [
      'copy', $sourceFile,
      "Cannot backup new discard file to $backupDiscardFile",
    ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'backup new discard file' )
  );
  unlink( $this->_discardFile ) if ( -e $this->_discardFile );
  $msgs->{cmd} = $cmds->COPY_FILE( $sourceFile, $this->_discardFile );
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 2,
    [
      'copy', $sourceFile,
      "Cannot copy new discard file to " . $this->_discardFile,
    ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'copy discard file' )
  );
}

sub _computeDiscardStats {
  my ncbi::Genes $this = shift;
  my ( $struct, $gap_info ) = @_;

  my $seq        = $gap_info->{ungapped_seq};
  my $fileType   = undef;
  my $gene       = undef;
  my $is_reverse = 'NA';
  my $seqType    = $this->_determineSeqType($seq);
  my $variant    = NONE_VARIANT_NAME;

  if ( $seqType eq UNAMBIGUOUS_TYPE ) {
    $fileType = NATIVE_TYPE;
    $gene     = $this->getNativeGeneName;
  }
  else {
    $fileType = $seqType;
    $gene     = UNKNOWN_GENE_NAME;
  }
  my $fh = $this->_getFh($fileType);
  $fh->print(
    join( util::Constants::TAB,
      util::Constants::EMPTY_STR, $struct->{na_sequence_id},
      $struct->{gb_accession},    $struct->{type},
      util::Constants::EMPTY_STR, util::Constants::EMPTY_STR,
      length($seq),               $gene,
      util::Constants::EMPTY_STR, util::Constants::EMPTY_STR,
      util::Constants::EMPTY_STR, util::Constants::EMPTY_STR,
      $seq,                       $variant,
      $is_reverse
      )
      . util::Constants::NEWLINE
  );
  $this->_computeStats( $seqType, $gene, $struct->{type}, $variant, $fileType,
    length($seq) );
}

################################################################################
#
#			     Delta File Processing
#
################################################################################

sub _readDeltaFile {
  my ncbi::Genes $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $deltaFile  = $properties->{deltaFile};
  my $delta      = [];

  return $delta if ( !-s $deltaFile );
  $this->{error_mgr}->printHeader("Reading Delta\n  file = $deltaFile");
  my $fh = new FileHandle;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 2,
    [ 'read file', $deltaFile, 'unable to read file', ],
    !$fh->open( $deltaFile, '<' )
  );

  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    next if ( util::Constants::EMPTY_LINE($line) );
    my ( $na_sequence_id, $accession ) = split( /\t/, $line );
    $this->{error_mgr}->printMsg($na_sequence_id);
    push( @{$delta}, $na_sequence_id );
  }
  $fh->close;
  return $delta;
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::Genes $this = shift;
  my ( $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{discard}      = {};
  $this->{error_mgr}    = $error_mgr;
  $this->{genetic_code} = new ncbi::GeneticCode( $error_mgr, $tools, $utils );
  $this->{fhs}          = {};
  $this->{ncbi_utils}   = $ncbi_utils;
  $this->{out_files}    = {};
  $this->{seq_len}      = {};
  $this->{specifics}    = $ncbi_utils->getProperties->{geneSpecifics};
  $this->{tools}        = $tools;
  $this->{utils}        = $utils;

  $this->{run_dir} = join( util::Constants::SLASH,
    $ncbi_utils->getDataDirectory,
    $ncbi_utils->getProperties->{datasetName}
  );

  my $gene_types = $this->getGeneTypeValues;
  push( @{$gene_types}, $this->getNativeGeneName, UNKNOWN_GENE_NAME );
  my $variant_values = $this->getVariantValues;
  push( @{$variant_values}, NONE_VARIANT_NAME );
  $this->{statistic} = new util::Statistics(
    'Sequence Types', undef,        $error_mgr,  SEQ_TAG,
    SEQ_VALS,         GENETYPE_TAG, $gene_types, FLTUYPE_TAG,
    FLTUYPE_VALS,     VARIANT_TAG,  $variant_values
  );
  $this->{statistic}->setShowTotal(util::Constants::TRUE);

  return $this;
}

sub process {
  my ncbi::Genes $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  if ( $properties->{generate} ) {
    $this->generateLoad;
    $this->printStatistics;
  }
  if ( $properties->{load} ) {
    $this->processToDb;
  }
  $ncbi_utils->printReport;
}

sub generateLoad {
  my ncbi::Genes $this = shift;

  $this->{error_mgr}->printHeader("Getting Sequences");

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  $this->{fhs}     = {};
  $this->{seq_len} = {};
  $this->{tools}->cmds->createDirectory( $this->{run_dir},
    'Creating ' . $this->getGeneSymbol . ' directory',
    util::Constants::TRUE );
  $this->_setDiscardFile;
  $this->_readDiscardFile;
  $this->_getRefData;
  ###
  ### Get the delta sequences if requested
  ###
  my $selectQuery = $properties->{selectQuery};
  if ( $properties->{useDelta} ) {
    $selectQuery->{naSequenceIds} = $this->_readDeltaFile;
  }
  my $query = new parallel::Query( undef, $this->{error_mgr}, $this->{tools} );
  my @data =
    $this->_filterData(
    $query->getData( $this->_getQueryProperties($selectQuery) ) );
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 1, [ $properties->{selectQuery}->{query}, ],
    $query->getErrorStatus );
  $this->{error_mgr}->printHeader( "all seqs = " . scalar @data );
  ###
  ### Process Sequences
  ###
  foreach my $struct (@data) {
    $this->{error_mgr}
      ->printHeader( 'Sequence Accession = ' . $struct->{gb_accession} );
    next if ( $this->_inDiscardFile($struct) );
    my $gap_info = undef;
    my $mstruct  = undef;
    if ( $struct->{gb_accession} eq $this->{ref_data}->{gb_accession} ) {
      $gap_info = $this->{ref_data}->{gap_info};
      $mstruct  = $this->{ref_data};
    }
    else {
      my $ref_data = undef;
      ( $gap_info, $ref_data ) =
        $this->_computeAlignments(
        $ncbi_utils->calculateUngapped( $struct->{seq} ),
        $struct->{gb_accession} );
      $mstruct = $this->findMotif( $gap_info, $struct->{gb_gi}, $ref_data );
    }
    if ( defined($mstruct) ) {
      $this->assignMotif( $struct, $mstruct );
    }
    else {
      $this->_addDiscardFile($struct);
      $this->_computeDiscardStats( $struct, $gap_info );
    }
  }
  $this->_closeFhs;
  $this->_updateDiscardFile;
}

sub processToDb {
  my ncbi::Genes $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  my $ord = $properties->{&STG_QUERY}->{queryParams};

  my $file = $this->_getFile(MOTIF_TYPE);
  if ( !-s $file ) {
    $ncbi_utils->addReport(
      $this->getGeneSymbol . " protein annotation:  no motifs found\n" );
    return;
  }

  my $data = new util::TableData( undef, $this->{tools}, $this->{error_mgr} );
  $data->setTableData( MOTIF_TYPE, $ord );
  $data->setFile( MOTIF_TYPE, $file );
  $data->setTableInfo(MOTIF_TYPE);

  $this->{tools}->startTransaction(util::Constants::TRUE);
  my $queries = QUERIES;
  my $loader  = new ncbi::Loader( $this->getGeneSymbol . ' protein annotation',
    SEQID_QUERY, $queries, $this->{error_mgr}, $this->{tools}, $this->{utils},
    $this->{ncbi_utils} );
  $loader->setSeqIdComp( $properties->{seqIdComp} );

  $this->{error_mgr}->printHeader("Loading Sequences");
  my $queryStatus = util::Constants::FALSE;
  my $errorCount  = 0;
OUTTER_LOOP:
  foreach my $struct ( @{ $data->getTableInfo(MOTIF_TYPE) } ) {
    $this->{error_mgr}->printMsg(
      '(' . $struct->{gb_accession} . ', ' . $struct->{na_sequence_id} . ')' );
    ###
    ### Get seq_id
    ###
    my $status = $loader->getSeqId($struct);
    $queryStatus = $status ? $status : $queryStatus;
    last if ($status);
    ###
    ### execute updates
    ###
    foreach my $queryName ( @{$queries} ) {
      my $status = $loader->executeUpdate( $queryName, $struct );
      $errorCount++ if ($status);
      $queryStatus = $status ? $status : $queryStatus;
      next OUTTER_LOOP if ($status);
    }
  }
  ###
  ### Error(s) in Run
  ###
  my $db = $this->{tools}->getSession;
  if ($queryStatus) {
    $ncbi_utils->addReport(
          "PA-X protein annotation (ERRORS ENCOUNTERED):  inserts executed "
        . ( $db->getCommitCount - $errorCount )
        . ", insert errors $errorCount\n" );
    $this->{tools}->rollbackTransaction;
    $this->{error_mgr}->exitProgram( ERR_CAT, 4, [], util::Constants::TRUE );
  }
  ###
  ### Successful Run
  ###
  $ncbi_utils->addReport( $this->getGeneSymbol
      . " protein annotation:  success "
      . ( ( $db->getCommitCount - $errorCount ) / scalar @{$queries} )
      . ", error $errorCount\n" );
  $this->{tools}->finalizeTransaction;
  my $fh = $this->_getFh( LOADED_TYPE, util::Constants::TRUE );
  $fh->print("successful load\n");
  $this->_closeFhs;
}

sub printStatistics {
  my ncbi::Genes $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $statistic  = $this->{statistic};

  $ncbi_utils->addReport( $statistic->printStr );
  $statistic->print;

  foreach my $fileType ( keys %{ $this->{seq_len} } ) {
    my $seq_len = $this->{seq_len}->{$fileType};
    $seq_len->{av} = $seq_len->{total} / $seq_len->{num};
    my ( $int, $dec ) = split( /\./, $seq_len->{av} );
    if ( !util::Constants::EMPTY_LINE($dec) && $dec > 0 ) {
      my @dec = split( //, $dec );
      $int++ if ( $dec[0] >= 5 );
    }
    $seq_len->{av} = $int;
  }
  my $table = new util::Table( $this->{error_mgr}, COLS );
  $table->setColumnOrder(COLS_ORD);
  $table->setColumnJustification( 'type', $table->LEFT_JUSTIFY );
  $table->setColumnJustification( 'num',  $table->RIGHT_JUSTIFY );
  $table->setColumnJustification( 'min',  $table->RIGHT_JUSTIFY );
  $table->setColumnJustification( 'max',  $table->RIGHT_JUSTIFY );
  $table->setColumnJustification( 'av',   $table->RIGHT_JUSTIFY );
  $table->setRowOrder('sub {$a->{type} cmp $b->{type};}');
  $table->setData( values %{ $this->{seq_len} } );
  $table->setInHeader(util::Constants::TRUE);
  $ncbi_utils->addReport( $table->generateTableStr );
  $table->generateTable('Sequence Lengths by File Type');
}

sub getGeneSymbol {
  my ncbi::Genes $this = shift;
  return $this->{specifics}->{symbol};
}

sub getVariantValues {
  my ncbi::Genes $this = shift;
  return $this->{specifics}->{variants};
}

sub getGeneTypeValues {
  my ncbi::Genes $this = shift;
  ###                                  ###
  ### Abstract Method                  ###
  ### Reference to array of gene types ###
  ###                                  ###
  my $gene_types = [];
  return $gene_types;
}

sub getNativeGeneName {
  my ncbi::Genes $this = shift;
  ##############################
  ### Re-implmentable Method ###
  ##############################
  return join( util::Constants::HYPHEN, $this->getGeneSymbol, NATIVE_NAME );
}

sub determineGeneProductName {
  my ncbi::Genes $this = shift;
  my ($aminoacids) = @_;
  ###                             ###
  ### Abstract Method             ###
  ### Determine gene product name ###
  ###                             ###
  return UNKNOWN_GENE_NAME;
}

sub findRefMotif {
  my ncbi::Genes $this = shift;
  my ( $gb_gi, $gb_accession, $gap_info ) = @_;
  ###                               ###
  ### Abstract Method               ###
  ### Find reference motif sequence ###
  ###                               ###
  return undef;
}

sub findMotif {
  my ncbi::Genes $this = shift;
  my ( $gap_info, $gb_gi, $ref_data ) = @_;
  ###                         ###
  ### Abstract Method         ###
  ### Find motif for sequence ###
  ###                         ###
  return undef;
}

sub assignMotif {
  my ncbi::Genes $this = shift;
  my ( $struct, $mstruct ) = @_;
  ###                                    ###
  ### Abstract Method                    ###
  ### Assign motif and update statistics ###
  ###                                    ###
}

################################################################################
1;

__END__

=head1 NAME

Genes.pm

=head1 SYNOPSIS

  use ncbi::Genes;

=head1 DESCRIPTION

The Genes abstract processor.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Genes(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
