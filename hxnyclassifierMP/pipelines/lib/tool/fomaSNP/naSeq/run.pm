package tool::fomaSNP::naSeq::run;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use File::Basename;
use Pod::Usage;

use util::Constants;

use tool::ErrMsgs;

use base 'tool::fomaSNP::naSeq';

use fields qw(
  end_pos
  start_pos
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return tool::ErrMsgs::FOMASNP_CAT; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _getCDScoords {
  my tool::fomaSNP::naSeq::run $this = shift;
  my ($consFile) = @_;

  my $min_size = $this->{min_cds_size}->{ $this->{segment} };
  my $cmd =
      $this->{getorf_path}
    . " -outseq stdout -find 3 -noreverse 2> /dev/null -minsize $min_size $consFile"
    . "| grep '^>'";
  my @reStr  = `$cmd`;
  my $coords = [];
  foreach my $str (@reStr) {
    next if ( $str !~ /\[(\d+) - (\d+)\]/ );
    push( @{$coords}, { begin => $1, end => $2 } );
  }
  return $coords;
}

sub _generateStartEndPositions {
  my tool::fomaSNP::naSeq::run $this = shift;
  ###
  ### Calculate start and stop positions
  ###
  my $data              = $this->{fasta_data};
  my $special_snp_start = $this->{special_snp_start};
  my $special_snp_stop  = $this->{special_snp_stop};

  $this->{start_pos} = 0;
  $this->{end_pos}   = $#{ $data->{conArray} };
  my $changed_start_stop = util::Constants::FALSE;

  my $start_index = length( $special_snp_start->{seq} ) - 1;
  foreach my $index ( 0 .. $#{ $data->{conArray} } ) {
    my $str = util::Constants::EMPTY_STR;
    foreach my $sindex ( 0 .. $start_index ) {
      $str .= $data->{conArray}->[ $index + $sindex ]->{consensus};
    }
    if ( $str eq $special_snp_start->{seq} ) {
      $this->{start_pos} = $index;
      $this->{error_mgr}
        ->printMsg("_generateStartEndPositions:  start_pos = $index");
      $changed_start_stop = util::Constants::TRUE;
      last;
    }
    if ( $data->{conArray}->[$index]->{totalSeq} > $special_snp_start->{total} )
    {
      last;
    }
    if ( $index > $special_snp_start->{cutoff} ) { last; }
  }

  my $stop_index = length( $special_snp_stop->{seq} ) - 1;
  foreach my $index ( reverse 0 .. $#{ $data->{conArray} } ) {
    my $str = util::Constants::EMPTY_STR;
    foreach my $sindex ( reverse 0 .. $stop_index ) {
      $str .= $data->{conArray}->[ $index - $sindex ]->{consensus};
    }
    if ( $str eq $special_snp_stop->{seq} ) {
      $this->{end_pos} = $index;
      $this->{error_mgr}
        ->printMsg("_generateStartEndPositions:  end_pos = $index");
      $changed_start_stop = util::Constants::TRUE;
      last;
    }
    if ( $data->{conArray}->[$index]->{totalSeq} > $special_snp_stop->{total} )
    {
      last;
    }
    if ( $index < scalar @{ $data->{conArray} } - $special_snp_stop->{cutoff} )
    {
      last;
    }
  }
  $this->{error_mgr}->printHeader( "Start-End Positions\n"
      . "  length  = "
      . scalar @{ $data->{conArray} } . "\n"
      . "  changed = "
      . $changed_start_stop . "\n"
      . "  start   = "
      . $this->{start_pos} . "\n"
      . "  end     = "
      . $this->{end_pos} );

  return $changed_start_stop;
}

sub _generateAlleleFreq {
  my tool::fomaSNP::naSeq::run $this = shift;

  $this->{error_mgr}->printHeader("Generate Allele Frequencies");

  my $data          = $this->{fasta_data};
  my $workspaceRoot = $this->getProperties->{workspaceRoot};

  my $alignLen = scalar @{ $data->{conArray} };
  $this->{error_mgr}
    ->printMsg( "numSeq: " . $data->{numSeq} . ", alignLen: $alignLen\n" );
  ###
  ### Set leftmost and rightmost to the extremes of the ungapped sequence
  ### These coordinates are in 0-base-based coordinates
  ###
  my $leftmost  = 0;
  my $rightmost = $data->{ungapped_end} - 1;
  ###
  ### Now determine the maximum open reading frame
  ### The coordinates returned will be in 1-base-based
  ### coordinates
  ###
  my $ungappedConsensus =
    join( util::Constants::EMPTY_STR, @{ $data->{consensus} } );
  $ungappedConsensus =~ s/-//g;
  my $cons_fasta = join( util::Constants::SLASH, $workspaceRoot, 'cons.fasta' );
  my $consFh = $this->openFile($cons_fasta);
  $consFh->print(
    '>'
      . join( util::Constants::PIPE,
      'consensus', $data->{numSeq}, $alignLen, length($ungappedConsensus) )
      . "\n$ungappedConsensus\n"
  );
  $consFh->close;
  my $coords = $this->_getCDScoords($cons_fasta);

  if ( scalar @{$coords} > 0 ) {
    my @unGappedCDScoords = @{$coords};
    ###
    ### check the leftmost begin coord is ATG and rightmost end coord + 3 is STOP
    ###
    my @sortBegin = sort { $a->{begin} <=> $b->{begin} } @unGappedCDScoords;
    my @sortEnd   = sort { $a->{end} <=> $b->{end} } @unGappedCDScoords;
    $leftmost  = $sortBegin[0]->{begin};
    $rightmost = $sortEnd[-1]->{end};
    my $firstCodon = substr( $ungappedConsensus, $leftmost - 1, 3 );
    my $lastCodon  = substr( $ungappedConsensus, $rightmost,    3 );
    if ( $lastCodon !~ /^T(AA|AG|GA)$/ ) {
      ###
      ### no STOP and 3'UTR
      ### rightmost was the coord of STOP, now it's the end of seq
      ###
      $rightmost--;
    }
    ###
    ### Make the ungapped coordinates from getorf 0-base-based
    ###
    $leftmost--;
    $rightmost--;
  }
  my @maskedArray = ();
  for ( my $i = 0 ; $i <= $#{ $data->{consensus} } ; $i++ )
  {    ### initialize to non-coding
    $maskedArray[$i] = 0;
  }
  ###
  ### set coding region to 1
  ###
  my $gappedCoordBegin = $data->{unGap2GapMapping}->{$leftmost};
  my $gappedCoordEnd   = $data->{unGap2GapMapping}->{$rightmost};
  for ( my $n = $gappedCoordBegin ; $n <= $gappedCoordEnd ; $n++ ) {
    $maskedArray[$n] = 1;
  }
  ###
  ### Now generate files
  ###
  my $foma_file = $this->createFile( $this->FOMA_FILE );
  my $fomaFh    = $this->openFile($foma_file);

  my $lfoma_file = join( util::Constants::SLASH, $workspaceRoot, 'foma.table' );
  my $lfomaFh = $this->openFile($lfoma_file);

  $this->printTab( $lfomaFh, 'Position', 'Coding', 'FOMA', 'Consensus', 'A',
    'T', 'G', 'C', 'Deletion', 'NumberOfSequence' );

  my $seqPos = 1;
  my $seqNum = 1;
  for ( my $j = $this->{start_pos} ; $j <= $this->{end_pos} ; $j++ ) {
    my $col = $data->{conArray}->[$j];
    foreach my $alphabet ( keys %{ $data->{symbolHash} } ) {
      if ( !defined( $col->{$alphabet} ) ) { $col->{$alphabet} = 0; }
    }
    ###
    ### when there is no gap in the alignment, '-' won't showup in %{$data->{symbolHash}}
    ### and $col->{'-'} undefined. need to set it to 0.
    ###
    if ( !defined( $col->{&util::Constants::HYPHEN} ) ) {
      $col->{&util::Constants::HYPHEN} = 0;
    }
    my $coding   = 'yes';
    my $position = $seqPos;
    if ( $col->{consensus} eq util::Constants::HYPHEN ) {
      $coding   = 'N/A';
      $position = 'N/A';
      $seqPos--;
    }
    elsif ( $maskedArray[ $seqPos - 1 ] == 0 ) { $coding = 'no'; }
    my @dataArray = (
      $position,                        $coding,
      $col->{foma},                     $col->{consensus},
      $col->{A},                        $col->{T},
      $col->{G},                        $col->{C},
      $col->{&util::Constants::HYPHEN}, $col->{totalSeq},
      $seqNum
    );
    $this->printTab( $lfomaFh, @dataArray );

    $this->printTab(
      $fomaFh,          $this->{subtype}, $this->{host},
      $this->{segment}, @dataArray
    );
    $seqPos++;
    $seqNum++;
  }
  $lfomaFh->close;
  $fomaFh->close;

  $this->{output_file}->addOutputFile( $this->FOMA_FILE, $foma_file );
}

sub _prepareJPegFile {
  my tool::fomaSNP::naSeq::run $this = shift;
  ###
  ### Test whether foma data was generated or not
  ###
  my $data = $this->{fasta_data};
  my $foma = $data->{foma};
  return if ( util::Constants::EMPTY_LINE($foma) || scalar @{$foma} == 0 );

  my ( $input, $output, $prefix ) = $this->prepareJPegFiles;
  my $fh = $this->openFile($input);
  foreach my $index ( 0 .. $#{$foma} ) {
    $fh->print(
      join( util::Constants::COMMA, $index + 1, $foma->[$index] )
        . util::Constants::NEWLINE );
  }
  $fh->close;
}

sub _generateSnp {
  my tool::fomaSNP::naSeq::run $this = shift;

  my $data        = $this->{fasta_data};
  my $output_file = $this->{output_file};

  my $genbank_file = $this->createFile( $this->SNP_GENBANK_FILE );
  my $refseq_file  = $this->createFile( $this->SNP_REFSEQ_FILE );

  $this->{error_mgr}->printHeader("Generate SNP");
  ###
  ### Check header issue
  ###
  $this->{error_mgr}->registerError( ERR_CAT, 9, [], $data->{headerIssue} );
  if ( $data->{headerIssue} ) {
    $output_file->addOutputFile( $this->SNP_GENBANK_FILE, $genbank_file );
    $output_file->addOutputFile( $this->SNP_REFSEQ_FILE,  $refseq_file );
    return;
  }

  my $refseqs       = $this->getData->{refseqs};
  my $workspaceRoot = $this->getProperties->{workspaceRoot};

  my $alignLen = $#{ $data->{conArray} } + 1;
  $this->{error_mgr}
    ->printMsg( "numSeq: " . $data->{numSeq} . ", alignLen: $alignLen" );
  ###
  ### ungapped  :    1234   5678  90      index of seq (w/o gaps)
  ### gapped    : 0123456789012345678901  index of aln and cons
  ### aln       : ---ATCG---TTGG--AC----
  ### consensus : CCTAACGTT-CA---TACCT--
  ###
  my $genbankFh = $this->openFile($genbank_file);
  my $refseqFh  = $this->openFile($refseq_file);

  my $snpFile = join( util::Constants::SLASH, $workspaceRoot, 'snp.out' );
  my $snpFh = $this->openFile($snpFile);

  $this->printTab( $snpFh, 'Accession', 'Ungapped_Pos', 'Gapped_Pos', 'Type',
    'Symbol' );

  while ( my ( $acc, $aln ) = each %{ $data->{acc2Aln} } ) {
    if ( scalar @{ $data->{consensus} } != scalar @{$aln} ) {
      $this->{error_mgr}
        ->registerError( ERR_CAT, 10, [$acc], util::Constants::TRUE );
      $genbankFh->close;
      $refseqFh->close;
      $snpFh->close;
      $output_file->addOutputFile( $this->SNP_GENBANK_FILE, $genbank_file );
      $output_file->addOutputFile( $this->SNP_REFSEQ_FILE,  $refseq_file );
      return;
    }
    my ( $offset, $trailing ) = $this->{utils}->getOffsetTrailing($aln);
    ###
    ### comparison starts after leading -
    ###
    my $gapped_pos = 1;
    if   ( $offset < $this->{start_pos} ) { $offset     = $this->{start_pos}; }
    else                                  { $gapped_pos = $offset + 1; }
    ###
    ### comparison ends before trailing -
    ###
    if ( $trailing > $this->{end_pos} ) { $trailing = $this->{end_pos}; }

    my $ungapped_pos = 1;
    for ( my $i = 0 ; $i < $offset ; $i++ ) {
      if ( $aln->[$i] ne util::Constants::HYPHEN ) { $ungapped_pos++; }
    }
    for ( my $j = $offset ; $j <= $trailing ; $j++ ) {
      my ( $symCon, $symAcc ) = ( $data->{consensus}->[$j], $aln->[$j] );
      my @dataArray = ();
      if ( $symCon ne util::Constants::HYPHEN
        && $symAcc eq util::Constants::HYPHEN )
      {    ### DELETION
        @dataArray = ( $ungapped_pos - 1, $gapped_pos, 'deletion', $symCon );
      }
      elsif ( $symCon eq util::Constants::HYPHEN
        && $symAcc ne util::Constants::HYPHEN )
      {    ### INSERTION
        @dataArray = ( $ungapped_pos, $gapped_pos, 'insertion', $symAcc );
        $ungapped_pos++;
      }
      elsif ( $symCon eq util::Constants::HYPHEN
        && $symAcc eq util::Constants::HYPHEN )
      {    ### Match Gaps, DO NOTHING
      }
      elsif ( $symCon ne $symAcc ) {    ### MISMATCH
        @dataArray =
          ( $ungapped_pos, $gapped_pos, 'mismatch', $symCon . '->' . $symAcc );
        $ungapped_pos++;
      }
      else {                            ### IDENTICAL
        $ungapped_pos++;
      }
      $gapped_pos++;
      next if ( scalar @dataArray == 0 );
      $this->printTab( $snpFh, $acc, @dataArray );
      $this->printTab( $genbankFh, $this->{subtype}, $this->{host},
        $this->{segment}, $acc, @dataArray );
      $this->printTab( $refseqFh, $this->{subtype}, $this->{host},
        $this->{segment}, $refseqs->getVal($acc), @dataArray )
        if ( $refseqs->accDefined($acc) );
    }
  }
  $refseqFh->close;
  $genbankFh->close;
  $snpFh->close;

  $output_file->addOutputFile( $this->SNP_GENBANK_FILE, $genbank_file );
  $output_file->addOutputFile( $this->SNP_REFSEQ_FILE,  $refseq_file );
}

sub _reprocessClwOutFormat {
  my tool::fomaSNP::naSeq::run $this = shift;
  my ($file) = @_;

  my $cmds        = $this->{tools}->cmds;
  my $headLen     = $this->{strain_name_cutoff};
  my $output_file = $this->{output_file};
  my $seqEnd      = $this->{end_pos};
  my $seqLen      = $this->{seq_len};
  my $seqStart    = $this->{start_pos};
  ###
  ### First copy file to backup
  ###
  my $backup_file = join( util::Constants::DOT, $file, 'reprocess', 'backup' );
  my $msgs = { cmd => $cmds->COPY_FILE( $file, $backup_file ), };
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 8,
    [ $file, $backup_file ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'copying clw file' )
  );
  ###
  ### Read File
  ###
  my $iFh       = $this->openFile( $file, '<' );
  my $header    = [];
  my $lines     = [];
  my $data      = {};
  my $gotHeader = util::Constants::FALSE;
  while ( !$iFh->eof ) {
    my $line = $iFh->getline;
    chomp($line);
    if (
      !$gotHeader
      && ( util::Constants::EMPTY_LINE($line)
        || $line =~ /(muscle|clustal w)/i )
      )
    {
      push( @{$header}, $line );
      next;
    }
    $gotHeader = util::Constants::TRUE;
    next if ( length($line) < $headLen );
    my $header = substr( $line, 0, $headLen );
    my $seq = substr( $line, $headLen );
    if ( !defined( $data->{$header} ) ) {
      push( @{$lines}, $header );
      $data->{$header} = util::Constants::EMPTY_STR;
    }
    $data->{$header} .= $seq;
  }
  $iFh->close;
  ###
  ### Reduce sequence and generate new file
  ###
  my $totalSeqLen = 0;
  foreach my $header ( @{$lines} ) {
    $data->{$header} =
      substr( $data->{$header}, $seqStart, $seqEnd - $seqStart + 1 );
    if ( $totalSeqLen == 0 ) { $totalSeqLen = length( $data->{$header} ); }
  }
  my $tmp_file = $cmds->TMP_FILE( 'clw', 'tmp' );
  my $oFh = $this->openFile($tmp_file);
  foreach my $line ( @{$header} ) { $oFh->print("$line\n"); }
  my $start = 0;
  while ( $start < $totalSeqLen ) {
    foreach my $header ( @{$lines} ) {
      my $seq = $data->{$header};
      $oFh->print( $header . substr( $seq, $start, $seqLen ) . "\n" );
    }
    $oFh->print("\n");
    $start += $seqLen;
  }
  $oFh->close;

  $msgs = { cmd => $cmds->MOVE_FILE( $tmp_file, $file ), };
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 4,
    [ $tmp_file, $file ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'moving new clw file' )
  );

  my $zip_file = $this->createFile( $this->ZIP_FILE );
  if ( -e $zip_file ) {
    $msgs = { cmd => $cmds->RM_FILE($zip_file), };
    $this->{error_mgr}->exitProgram( ERR_CAT, 12, [$zip_file],
      $cmds->executeCommand( $msgs, $msgs->{cmd}, 'removing zip file' ) );
  }

  $msgs = { cmd => "zip -r $zip_file " . basename($file), };
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 5,
    [ $file, $zip_file ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'zipping up clw file' )
  );
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $utils, $error_mgr, $tools ) = @_;

  my tool::fomaSNP::naSeq::run $this =
    $that->SUPER::new( $utils, $error_mgr, $tools );

  $this->{end_pos}   = undef;
  $this->{start_pos} = undef;

  return $this;
}

sub runData {
  my tool::fomaSNP::naSeq::run $this = shift;

  my $cmds        = $this->{tools}->cmds;
  my $data        = $this->getData->{seqs}->getTableInfo('seqs');
  my $groupTag    = uc( $this->groupTag );
  my $properties  = $this->getData->{properties};
  my $skip_groups = $this->{skip_groups};

  my $offset      = $properties->getProperty('offset');
  my $trailing    = $properties->getProperty('trailing');
  my $max_seq_len = $properties->getProperty('max_seq_len');
  my $realign     = $properties->getProperty('realign');

  my $afa_file = $this->createFile('afa');
  my $aln_file = $this->createFile('aln');
  my $na_file  = $this->createFile('fasta');
  ###
  ### Log tool type to use...
  ###
  if ( defined( $skip_groups->{$groupTag} ) ) {
    if ( $this->{clustalw} ) {
      $this->{error_mgr}->printMsg("Running clustalw");
    }
    else {
      $this->{error_mgr}->printMsg("Running muscle");
    }
  }
  ###
  ### Already Aligned Sequences
  ###
  if ( !$realign ) {
    $this->{error_mgr}
      ->printMsg("Use pre-aligned seq for snp analysis for this group\n");
    my $fh = $this->openFile($afa_file);
    $this->{error_mgr}->printMsg("Generating .afa file: $afa_file");
    foreach my $idata ( @{$data} ) {
      my $align_seq = $idata->{align_seq};
      $align_seq = substr( $align_seq, $offset, $trailing - $offset + 1 );
      $fh->print( '>' . $idata->{ncbiacc} . "|\n$align_seq\n" );
    }
    $fh->close;
    my $status = $this->fasta2ClustalalW( $afa_file, $aln_file );
    $realign = ($status) ? 2 : $realign;
  }
  ###
  ### Must realign sequences
  ###
  if ($realign) {
    $this->{error_mgr}->printMsg("Need realign na sequence for this group\n");
    my $fh = $this->openFile($na_file);
    $this->{error_mgr}->printMsg("Generating .fasta file: $na_file");
    my $na_count = 0;
    foreach my $idata ( @{$data} ) {
      my $seq = $idata->{seq};
      next
        if ( $realign != 2
        && length($seq) / $max_seq_len <= $this->{length_cutoff} );
      $na_count++;
      $fh->print( '>' . $idata->{ncbiacc} . "|\n$seq\n" );
    }
    $fh->close;
    if ( $na_count < $this->{min_num_seq} ) {
      $this->{error_mgr}->printHeader(
"After cutoff number of sequences insufficient for meaningful snp analysis ($na_count)"
      );
      return;
    }
    ###
    ### Run clustalw if requested
    ###
    if ( $this->{run_clustalw}
      || ( defined( $skip_groups->{$groupTag} ) && $this->{clustalw} ) )
    {
      my $status = util::Constants::FALSE;
      if ( !-e $afa_file ) {
        my $msgs =
          {   cmd => $this->{clustalw_path}
            . " -type=dna -align -output=fasta "
            . "-infile=$na_file -outfile=$afa_file", };
        $status =
          $cmds->executeCommand( $msgs, $msgs->{cmd}, 'running clustalw' );
        $this->{error_mgr}
          ->printMsg("Error running clustalw, will run muscle instead")
          if ($status);
      }
      if ( !$status ) {
        $realign =
          ( $this->fasta2ClustalalW( $afa_file, $aln_file ) )
          ? util::Constants::TRUE
          : util::Constants::FALSE;
      }
    }
    ###
    ### Otherwise, run muscle otherwise,
    ### or if error generating aln_file using clustalw
    ###
    if ($realign) {
      my $cmd = $this->{muscle_path}
        . " -in $na_file -fastaout $afa_file -clwout $aln_file ";
      if ( $na_count >= $this->{muscle_cutoff} ) {
        $cmd .= " -maxiters 1 -diags1 ";
      }
      my $status = util::Constants::FALSE;
      if ( !-e $aln_file || !-e $afa_file ) {
        my $msgs = { cmd => $cmd, };
        $status =
          $cmds->executeCommand( $msgs, $msgs->{cmd}, 'running muscle' );
        $this->{error_mgr}->printMsg(
          "Muscle failed on this group of $na_count flu DNA sequences")
          if ($status);
        next if ($status);
      }
    }
  }
  ###
  ### Process the Files
  ###
  $this->clwOutStrainNameFormat($aln_file);

  my $status = $this->readFastaFile($afa_file);
  $this->{error_mgr}->registerError( ERR_CAT, 11, [], $status );
  return if ($status);
  $this->_reprocessClwOutFormat($aln_file)
    if ( $this->_generateStartEndPositions );

  $this->_generateAlleleFreq;
  $this->_prepareJPegFile;

  $this->_generateSnp
    if ( $this->{run_snp} && $this->{host} ne $this->{pandemic}->{name} );
}

################################################################################

1;

__END__

=head1 NAME

run.pm

=head1 DESCRIPTION

This class defines the runner for NA sequence fomaSNP.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::fomaSNP::naSeq::run(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
