package ncbi::PAXGeneNew;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
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
  motifs
  ncbi_utils
  out_files
  ref_data
  run_dir
  seq_len
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
### PAX Subdirectory
###
sub SEQ_FILE { return 'seq'; }
###
### The PA-X Motif
###
sub MOTIF            { return 'TTT'; }
sub REF_MOTIF_PREFIX { return 'TCCTTT'; }
sub REF_FRAMESHIFT   { return 'C'; }
sub REF_MOTIF_SUFFIX { return 'GTC'; }
###
### Statistic
###
sub SEQ_TAG    { return 'Seq (Unambiguous/Ambiguous)'; }
sub SEQ_VALS   { return [ 'Ambiguous', 'Unambiguous', ]; }
sub PATYPE_TAG { return 'PA- Type'; }

sub PATYPE_VALS {
  return [ 'PA-X41', 'PA-X61', 'PA-XOther', 'PA-Native', 'Unknown', ];
}
sub FLTUYPE_TAG  { return 'Influenza Type'; }
sub FLTUYPE_VALS { return [ 'A', 'B', 'C', 'O', ]; }
sub VARIANT_TAG  { return 'Motif Variant'; }
sub VARIANT_VALS { return [ 'A', 'T', 'C', 'G', 'None', ]; }
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
### Types
###
sub AMBIGUOUS_TYPE   { return 'Ambiguous'; }
sub ERROR_TYPE       { return 'Error'; }
sub MOTIF_TYPE       { return 'Motif'; }
sub NATIVE_TYPE      { return 'Native'; }
sub TRANSLATION_TYPE { return 'Translation'; }
sub UNAMBIGUOUS_TYPE { return 'Unambiguous'; }

sub LOADED_TYPE { return 'loaded'; }
sub SID_TYPE    { return 'sid'; }

sub DISCARD_TYPE { return 'discard'; }
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
sub ERR_CAT { return ncbi::ErrMsgs::PAXGENE_CAT; }

################################################################################
#
#				   Private Methods
#
################################################################################

sub _filterData {
  my ncbi::PAXGeneNew $this = shift;
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

sub _isUnambiguous {
  my ncbi::PAXGeneNew $this = shift;
  my ($seq) = @_;
  return ( $seq =~ /^[CTAG]+$/ )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

sub _getFile {
  my ncbi::PAXGeneNew $this = shift;
  my ($type) = @_;

  my $ncbi_utils = $this->{ncbi_utils};

  return join( util::Constants::SLASH,
    $this->{run_dir}, join( util::Constants::DOT, SEQ_FILE, $type ) );
}

sub _getFh {
  my ncbi::PAXGeneNew $this = shift;
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
    )
    if ( !$no_header );
  return $this->{fhs}->{$type};
}

sub _closeFhs {
  my ncbi::PAXGeneNew $this = shift;

  my $fhs = $this->{fhs};
  foreach my $variant ( keys %{$fhs} ) {
    $fhs->{$variant}->close;
    delete( $fhs->{$variant} );
  }
}

sub _computeStats {
  my ncbi::PAXGeneNew $this = shift;
  my ( $seqType, $gene, $fluType, $variant, $fileType, $seqLen ) = @_;

  $this->{statistic}->increment(
    SEQ_TAG,     $seqType, PATYPE_TAG,  $gene,
    FLTUYPE_TAG, $fluType, VARIANT_TAG, $variant
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

sub _getPrefixProtein {
  my ncbi::PAXGeneNew $this = shift;
  my ( $gap_info, $prefix, $motif, $ref_data ) = @_;

  my $geneticCode = $this->{genetic_code};

  $motif = substr( $motif, 0, length($motif) - 1 );
  $prefix .= $motif;

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
    $pstart = $ref_data->{non2gapped}->{ $ref_data->{pstart} - 1 };
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
  return ( $start, $end, $aminoacids );
}

sub _getSuffixProtein {
  my ncbi::PAXGeneNew $this = shift;
  my ( $suffix, $pend ) = @_;

  my $geneticCode = $this->{genetic_code};

  my $i          = length($suffix);
  my @ssuffix    = split( //, $suffix );
  my @aminoacids = ();
  my $m          = 0;
  while ( $m < $i - 3 ) {
    my $k = $m;
    my $l = $m + 2;
    if ( $l >= $i ) { last; }
    push( @aminoacids,
      join( util::Constants::EMPTY_STR, @ssuffix[ $k .. $l ] ) );
    $m = $l + 1;
  }

  my $start      = $pend + 2;
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
  return ( $start, $end, $aminoacids );
}

sub _determineIntProt {
  my ncbi::PAXGeneNew $this = shift;
  my ( $pstart, $pend, $paminoacids, $sstart, $send, $saminoacids ) = @_;
  my $interval = 'join(';
  if ( defined($pstart) ) {
    $interval .= "${pstart}..${pend},";
  }
  else {
    $interval .= "-..-,";
  }
  if ( defined($sstart) ) {
    $interval .= "${sstart}..${send}";
  }
  else {
    $interval .= "-..-";
  }
  $interval .= ')';
  my $protein = $paminoacids . $saminoacids;
  return ( $interval, $protein );
}

sub _determineGene {
  my ncbi::PAXGeneNew $this = shift;
  my ($saminoacids) = @_;

  my $gene = 'Unknown';
  if ( !util::Constants::EMPTY_LINE($saminoacids) ) {
    $gene = 'PA-X';
    if ( length($saminoacids) == 41
      || length($saminoacids) == 61 )
    {
      $gene .= length($saminoacids);
    }
    else {
      $gene .= 'Other';
    }
  }
  $this->{error_mgr}->printMsg( "gene (" . length($saminoacids) . ") = $gene" );

  return $gene;
}

sub _determineProtGiId {
  my ncbi::PAXGeneNew $this = shift;
  my ( $gb_gi, $pstart, $send ) = @_;

  my $cds_start = defined($pstart) ? $pstart : util::Constants::HYPHEN;
  my $cds_end   = defined($send)   ? $send   : util::Constants::HYPHEN;

  my $protein_gi =
    join( util::Constants::UNDERSCORE, 'IRD', $gb_gi, $cds_start, $cds_end );
  my $protein_id = join( util::Constants::DOT, $protein_gi, '1' );
  return ( $protein_gi, $protein_id, $cds_start, $cds_end );
}

sub _findRefMotif {
  my ncbi::PAXGeneNew $this = shift;
  my ( $ref_seq, $gb_gi, $gb_accession ) = @_;

  my $ncbi_utils = $this->{ncbi_utils};

  my $mstruct      = undef;
  my $gap_info     = $ncbi_utils->calculateUngapped($ref_seq);
  my $seq          = $gap_info->{ungapped_seq};
  my $motif_prefix = REF_MOTIF_PREFIX . REF_FRAMESHIFT;
  my $motif        = $motif_prefix . REF_MOTIF_SUFFIX;
  my $patterns     = [$motif];
  if ( !$this->{utils}->foundPattern( $seq, $patterns ) ) {
    $this->{error_mgr}
      ->registerError( ERR_CAT, 5, [$gb_accession], util::Constants::TRUE );
    return $mstruct;
  }
  $seq =~ /$motif/;
  my $prefix = $`;
  my $suffix = $';    #';

  my $ungapped_ref_start = length($prefix) + 3;
  my $gapped_ref_start   = $gap_info->{non2gapped}->{$ungapped_ref_start};
  my $ungapped_ref_end   = length($prefix) + length($motif_prefix) - 1;
  my $gapped_ref_end     = $gap_info->{non2gapped}->{$ungapped_ref_end};

  $this->{error_mgr}->printHeader( "_findRefMotif\n"
      . "ungapped_ref_start = $ungapped_ref_start\n"
      . "gapped_ref_start   = $gapped_ref_start\n"
      . "ungapped_ref_end   = $ungapped_ref_end\n"
      . "gapped_ref_end     = $gapped_ref_end\n" );

  my ( $pstart, $pend, $paminoacids ) =
    $this->_getPrefixProtein( $gap_info, $prefix, $motif_prefix, undef );
  my ( $sstart, $send, $saminoacids ) =
    $this->_getSuffixProtein( REF_MOTIF_SUFFIX . $suffix, $pend );
  my ( $interval, $protein ) =
    $this->_determineIntProt( $pstart, $pend, $paminoacids, $sstart, $send,
    $saminoacids );
  my $gene = $this->_determineGene($saminoacids);
  my ( $protein_gi, $protein_id, $cds_start, $cds_end ) =
    $this->_determineProtGiId( $gb_gi, $pstart, $send );

  $mstruct = {
    cds_end      => $cds_end,
    cds_start    => $cds_start,
    gene         => $gene,
    interval     => $interval,
    is_reverse   => 'N',
    motif        => MOTIF,
    paminoacids  => $paminoacids,
    pend         => $pend,
    prefix       => $prefix,
    protein      => $protein,
    protein_gi   => $protein_gi,
    protein_id   => $protein_id,
    pstart       => $pstart,
    saminoacids  => $saminoacids,
    send         => $send,
    seq          => $seq,
    sstart       => $sstart,
    suffix       => $suffix,
    variant      => REF_FRAMESHIFT,
    gb_gi        => $gb_gi,
    gb_accession => $gb_accession,

    ungapped_ref_start => $ungapped_ref_start,
    gapped_ref_start   => $gapped_ref_start,
    ungapped_ref_end   => $ungapped_ref_end,
    gapped_ref_end     => $gapped_ref_end,

    non2gapped       => $gap_info->{non2gapped},
    gapped2non       => $gap_info->{gapped2non},
    non_gapped_end   => $gap_info->{non_gapped_end},
    non_gapped_start => $gap_info->{non_gapped_start},
    sseq             => $gap_info->{sseq},
    useq             => $gap_info->{useq},
    start            => $gap_info->{start},
    end              => $gap_info->{end},
    ungapped_seq     => $gap_info->{ungapped_seq},
  };
  $mstruct->{prefix_len} = $mstruct->{pend} - $mstruct->{pstart} + 1;

  return $mstruct;
}

sub _getFastaFileName {
  my ncbi::PAXGeneNew $this = shift;
  my ($acc)                 = @_;
  my $file_name             = join( util::Constants::SLASH,
    $this->{run_dir}, join( util::Constants::DOT, $acc, FASTA_TYPE ) );
  return $file_name;
}

sub _createFastaFile {
  my ncbi::PAXGeneNew $this = shift;
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
  my ncbi::PAXGeneNew $this = shift;
  my ( $gap_info, $acc ) = @_;

  my $cmds       = $this->{tools}->cmds;
  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $ref_data   = $this->{ref_data};

  my $seq     = $gap_info->{ungapped_seq};
  my $ref_seq = $ref_data->{ungapped_seq};
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
  my $new_ref_data =
    $this->_findRefMotif( $ref_aligned_seq, $ref_data->{gb_gi}, $ref_acc );

  return ( $new_gap_info, $new_ref_data );
}

sub _findMotif {
  my ncbi::PAXGeneNew $this = shift;
  my ( $gap_info, $gb_gi, $ref_data ) = @_;

  my $mstruct                  = undef;
  my $seq                      = $gap_info->{ungapped_seq};
  my $ungapped_seq_motif_start =
    $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_start} };
  my $ungapped_seq_motif_end =
    $gap_info->{gapped2non}->{ $ref_data->{gapped_ref_end} };
  ###
  ### Short sequence cannot find frameshift, return immediately
  ###
  return $mstruct
    if ( !defined($ungapped_seq_motif_start)
    || !defined($ungapped_seq_motif_end) );

  my $seqMotif = join( util::Constants::EMPTY_STR,
    @{ $gap_info->{useq} }
      [ $ungapped_seq_motif_start .. $ungapped_seq_motif_end ] );

  my $prefixIndex = $ungapped_seq_motif_start - 1;
  my $prefix      = join( util::Constants::EMPTY_STR,
    @{ $gap_info->{useq} }[ 0 .. $prefixIndex ] );
  my $suffixIndex = $ungapped_seq_motif_end + 1;
  my $suffix      = join( util::Constants::EMPTY_STR,
    @{ $gap_info->{useq} }[ $suffixIndex .. $#{ $gap_info->{useq} } ] );

  $this->{error_mgr}->printHeader( "_findMotif\n"
      . "ungapped_seq_motif_start = $ungapped_seq_motif_start\n"
      . "ungapped_seq_motif_end   = $ungapped_seq_motif_end\n"
      . "seqMotif                 = $seqMotif\n"
      . "prefixIndex              = $prefixIndex\n"
      . "suffixIndex              = $suffixIndex\n" );

  $this->{error_mgr}->printMsg(
    "seq    = $seq\n" . "prefix = $prefix\n" . "suffix = $suffix\n" );

  foreach my $variant ( keys %{ $this->{motifs} } ) {
    my $motif = $this->{motifs}->{$variant};
    next if ( $seqMotif ne $motif );
    my ( $pstart, $pend, $paminoacids ) =
      $this->_getPrefixProtein( $gap_info, $prefix, $motif, $ref_data );
    my ( $sstart, $send, $saminoacids ) =
      $this->_getSuffixProtein( $suffix, $pend );
    my ( $interval, $protein ) =
      $this->_determineIntProt( $pstart, $pend, $paminoacids, $sstart, $send,
      $saminoacids );
    my $gene = $this->_determineGene($saminoacids);
    my ( $protein_gi, $protein_id, $cds_start, $cds_end ) =
      $this->_determineProtGiId( $gb_gi, $pstart, $send );

    $mstruct = {
      cds_end     => $cds_end,
      cds_start   => $cds_start,
      gene        => $gene,
      interval    => $interval,
      is_reverse  => 'N',
      motif       => $motif,
      paminoacids => $paminoacids,
      pend        => $pend,
      prefix      => $prefix,
      protein     => $protein,
      protein_gi  => $protein_gi,
      protein_id  => $protein_id,
      pstart      => $pstart,
      saminoacids => $saminoacids,
      send        => $send,
      seq         => $seq,
      sstart      => $sstart,
      suffix      => $suffix,
      variant     => $variant,

      non2gapped       => $gap_info->{non2gapped},
      gapped2non       => $gap_info->{gapped2non},
      non_gapped_end   => $gap_info->{non_gapped_end},
      non_gapped_start => $gap_info->{non_gapped_start},
      sseq             => $gap_info->{sseq},
      useq             => $gap_info->{useq},
      start            => $gap_info->{start},
      end              => $gap_info->{end},
      ungapped_seq     => $gap_info->{ungapped_seq},
    };
    last;
  }
  return $mstruct;
}

sub _getRefData {
  my ncbi::PAXGeneNew $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  $this->{ref_data} = undef;

  my $query = new parallel::Query( undef, $this->{error_mgr}, $this->{tools} );
  my @data =
    $this->_filterData( $query->getData( $properties->{referenceQuery} ) );
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 1, [ $properties->{referenceQuery}->{query}, ],
    $query->getErrorStatus );

  my $struct = $data[0];
  $this->{error_mgr}
    ->printHeader( "reference accession = " . $struct->{gb_accession} );
  $this->{tools}->printStruct( '$struct', $struct );
  $this->{ref_data} =
    $this->_findRefMotif( $struct->{seq}, $struct->{gb_gi},
    $struct->{gb_accession} );
  $this->{tools}->printStruct( '$this->{ref_data}', $this->{ref_data} );
}

################################################################################
#
#                                  Discard Processing
#
################################################################################

sub _readDiscardFile {
  my ncbi::PAXGeneNew $this = shift;

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
  my ncbi::PAXGeneNew $this = shift;

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
  my ncbi::PAXGeneNew $this = shift;

  return $this->{discard_file};
}

sub _getDiscardFile {
  my ncbi::PAXGeneNew $this = shift;

  return $this->{out_files}->{&DISCARD_TYPE};
}

sub _inDiscardFile {
  my ncbi::PAXGeneNew $this = shift;
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
  my ncbi::PAXGeneNew $this = shift;
  my ($struct) = @_;

  my $new = $this->{discard}->{new};

  $this->{error_mgr}->printMsg("Adding to discard");
  return if ( defined( $new->{ $struct->{na_sequence_id} } ) );
  $new->{ $struct->{na_sequence_id} } = util::Constants::EMPTY_STR;
  my $fh = $this->_getFh( DISCARD_TYPE, util::Constants::TRUE );
  $fh->print( $struct->{na_sequence_id} . "\n" );
}

sub _updateDiscardFile {
  my ncbi::PAXGeneNew $this = shift;
  ###
  ### Now Update discard File
  ###
  ### 1.  Make backup current discard file
  ### 2.  Set discard file
  ###
  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $today_date = $properties->{todayDayDate};

  my $cmds              = $this->{tools}->cmds;
  my $msgs              = {};
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

################################################################################
#
#			     Delta File Processing
#
################################################################################

sub _readDeltaFile {
  my ncbi::PAXGeneNew $this = shift;

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
  my ncbi::PAXGeneNew $this = shift;
  my ( $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{discard}      = {};
  $this->{error_mgr}    = $error_mgr;
  $this->{genetic_code} = new ncbi::GeneticCode( $error_mgr, $tools, $utils );
  $this->{fhs}          = {};
  $this->{ncbi_utils}   = $ncbi_utils;
  $this->{out_files}    = {};
  $this->{seq_len}      = {};
  $this->{tools}        = $tools;
  $this->{utils}        = $utils;

  $this->{run_dir} = join( util::Constants::SLASH,
    $ncbi_utils->getDataDirectory,
    $ncbi_utils->getProperties->{datasetName}
  );

  $this->{motifs} = $this->{genetic_code}->getPaxMotifs(MOTIF);

  $this->{statistic} = new util::Statistics(
    'Sequence Types', undef,       $error_mgr,  SEQ_TAG,
    SEQ_VALS,         PATYPE_TAG,  PATYPE_VALS, FLTUYPE_TAG,
    FLTUYPE_VALS,     VARIANT_TAG, VARIANT_VALS
  );
  $this->{statistic}->setShowTotal(util::Constants::TRUE);

  return $this;
}

sub process {
  my ncbi::PAXGeneNew $this = shift;

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
  my ncbi::PAXGeneNew $this = shift;

  $this->{error_mgr}->printHeader("Getting Sequences");

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  my $geneticCode      = $this->{genetic_code};
  my $stopCodonPattern = $geneticCode->STOP_CODON;

  $this->{fhs}     = {};
  $this->{seq_len} = {};

  $this->{tools}
    ->cmds->createDirectory( $this->{run_dir}, 'Creating pax directory',
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
  my @data = $this->_filterData( $query->getData($selectQuery) );
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
    my $ref_data = undef;
    my $gap_info = $ncbi_utils->calculateUngapped( $struct->{seq} );
    if ( length( $struct->{seq} ) == scalar @{ $this->{ref_data}->{sseq} } ) {
      ###
      ### If the auto-curation alignment lengths are the
      ### same, then proceed using the reference data
      ###
      $ref_data = $this->{ref_data};
    }
    else {
      ###
      ### If the auto-curation alignment length different,
      ### must recompute alignment and generate the gap_info
      ### for the sequence and ref_data for the reference sequence
      ###
      $this->{error_mgr}->printMsg("RE-ALIGNING SEQUENCES");
      ( $gap_info, $ref_data ) =
        $this->_computeAlignments( $gap_info, $struct->{gb_accession} );
    }
    my $mstruct = $this->_findMotif( $gap_info, $struct->{gb_gi}, $ref_data );
    if ( defined($mstruct) ) {
      my $seqType = undef;
      if ( $this->_isUnambiguous( $mstruct->{seq} ) ) {
        $seqType = UNAMBIGUOUS_TYPE;
      }
      else { $seqType = AMBIGUOUS_TYPE; }
      ###
      ### It is an error for the variant to be a 'A' or 'G' or 'T'
      ###
      my $fileType = undef;
      if ( $mstruct->{variant} eq 'A'
        || $mstruct->{variant} eq 'G'
        || $mstruct->{variant} eq 'T' )
      {
        $this->{error_mgr}->registerError( ERR_CAT, 3,
          [ $mstruct->{variant}, $struct->{gb_accession} ],
          util::Constants::TRUE );
        $fileType = ERROR_TYPE;

      }
      elsif ( !defined( $mstruct->{pstart} )
        || !defined( $mstruct->{sstart} ) )
      {
        $fileType = $seqType;
        $mstruct->{gene} = 'Unknown';
      }
      elsif ( $mstruct->{paminoacids} =~ /$stopCodonPattern/ ) {
        $fileType = TRANSLATION_TYPE;
      }
      else {
        $fileType = MOTIF_TYPE;
        my $sfh = $this->_getFh( SID_TYPE, util::Constants::TRUE );
        $sfh->print(
          join( util::Constants::SPACE,
            $struct->{gb_accession}, $struct->{na_sequence_id},
            $struct->{gb_accession}
            )
            . util::Constants::NEWLINE
        );
      }
      $this->_addDiscardFile($struct) if ( $fileType ne MOTIF_TYPE );
      my $fh = $this->_getFh($fileType);
      $fh->print(
        join( util::Constants::TAB,
          util::Constants::EMPTY_STR, $struct->{na_sequence_id},
          $struct->{gb_accession},    $struct->{type},
          $mstruct->{protein_id},     $mstruct->{protein_gi},
          length( $mstruct->{seq} ),  $mstruct->{gene},
          $mstruct->{interval},       $mstruct->{cds_start},
          $mstruct->{cds_end},        $mstruct->{protein},
          $mstruct->{seq},            $mstruct->{variant},
          $mstruct->{is_reverse}
          )
          . util::Constants::NEWLINE
      );
      $this->_computeStats( $seqType, $mstruct->{gene}, $struct->{type},
        $mstruct->{variant}, $fileType, length( $mstruct->{seq} ),
      );
      next;
    }
    $this->_addDiscardFile($struct);
    my $seq        = $gap_info->{ungapped_seq};
    my $fileType   = undef;
    my $gene       = undef;
    my $is_reverse = 'NA';
    my $seqType    = undef;
    my $variant    = 'None';

    if ( $this->_isUnambiguous($seq) ) {
      $fileType = NATIVE_TYPE;
      $gene     = 'PA-Native';
      $seqType  = UNAMBIGUOUS_TYPE;
    }
    else {
      $fileType = AMBIGUOUS_TYPE;
      $gene     = 'Unknown';
      $seqType  = AMBIGUOUS_TYPE;
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
  $this->_closeFhs;
  $this->_updateDiscardFile;
}

sub processToDb {
  my ncbi::PAXGeneNew $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;

  my $ord = $properties->{&STG_QUERY}->{queryParams};

  my $file = $this->_getFile(MOTIF_TYPE);
  if ( !-s $file ) {
    $ncbi_utils->addReport("PA-X protein annotation:  no motifs found\n");
    return;
  }

  my $data = new util::TableData( undef, $this->{tools}, $this->{error_mgr} );
  $data->setTableData( MOTIF_TYPE, $ord );
  $data->setFile( MOTIF_TYPE, $file );
  $data->setTableInfo(MOTIF_TYPE);

  $this->{tools}->startTransaction(util::Constants::TRUE);
  my $queries = QUERIES;
  my $loader  = new ncbi::Loader( 'PA-X protein annotation',
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
  ### Error(s) in  Run
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
  $ncbi_utils->addReport( "PA-X protein annotation:  success "
      . ( ( $db->getCommitCount - $errorCount ) / 2 )
      . ", error $errorCount\n" );
  $this->{tools}->finalizeTransaction;
  my $fh = $this->_getFh( LOADED_TYPE, util::Constants::TRUE );
  $fh->print("successful load\n");
  $this->_closeFhs;
}

sub printStatistics {
  my ncbi::PAXGeneNew $this = shift;

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

################################################################################
1;

__END__

=head1 NAME

PAXGene.pm

=head1 SYNOPSIS

  use ncbi::PAXGene;

=head1 DESCRIPTION

The PA-X gene processor.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::PAXGene(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
