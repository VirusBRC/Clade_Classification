package ncbi::PAXGene;
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
sub MOTIF_PREFIX { return 'TC'; }
sub MOTIF_SUFFIX { return 'TTT'; }
###
### Statistic
###
sub SEQ_TAG      { return 'Seq (Unambiguous/Ambiguous)'; }
sub SEQ_VALS     { return [ 'Ambiguous', 'Unambiguous', ]; }
sub REVERSE_TAG  { return 'Reverse Seq'; }
sub REVERSE_VALS { return [ 'N', 'Y', 'NA', ]; }
sub PATYPE_TAG   { return 'PA- Type'; }

sub PATYPE_VALS {
	return [ 'PA-X41', 'PA-X61', 'PA-XOther', 'PA-Native', 'Unknown', ];
}
sub FLTUYPE_TAG        { return 'Influenza Type'; }
sub FLTUYPE_VALS       { return [ 'A', 'B', 'C', 'O', ]; }
sub VARIANT_TAG        { return 'Motif Variant'; }
sub VARIANT_VALS       { return [ 'A', 'T', 'C', 'G', 'None', ]; }
sub SERINE_VARIANT_TAG { return 'Serine Variant'; }
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
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::PAXGENE_CAT; }

################################################################################
#
#				   Private Methods
#
################################################################################

sub _filterData {
	my ncbi::PAXGene $this = shift;
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
	my ncbi::PAXGene $this = shift;
	my ($seq) = @_;
	return ( $seq =~ /^[CTAG]+$/ )
	  ? util::Constants::TRUE
	  : util::Constants::FALSE;
}

sub _getFile {
	my ncbi::PAXGene $this = shift;
	my ($type) = @_;

	my $ncbi_utils = $this->{ncbi_utils};

	return join( util::Constants::SLASH,
		$this->{run_dir}, join( util::Constants::DOT, SEQ_FILE, $type ) );
}

sub _getFh {
	my ncbi::PAXGene $this = shift;
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
		join( util::Constants::TAB,
			@{ $properties->{&STG_QUERY}->{queryParams} },
		  )
		  . util::Constants::NEWLINE
	) if ( !$no_header );
	return $this->{fhs}->{$type};
}

sub _closeFhs {
	my ncbi::PAXGene $this = shift;

	my $fhs = $this->{fhs};
	foreach my $variant ( keys %{$fhs} ) {
		$fhs->{$variant}->close;
		delete( $fhs->{$variant} );
	}
}

sub _computeStats {
	my ncbi::PAXGene $this = shift;
	my (
		$seqType,  $is_reverse, $gene,     $fluType,
		$svariant, $nvariant,   $fileType, $seqLen
	) = @_;

	$this->{statistic}->increment(
		SEQ_TAG,            $seqType,  REVERSE_TAG, $is_reverse,
		PATYPE_TAG,         $gene,     FLTUYPE_TAG, $fluType,
		SERINE_VARIANT_TAG, $svariant, VARIANT_TAG, $nvariant
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
	my ncbi::PAXGene $this = shift;
	my ( $gap_info, $prefix, $motif ) = @_;

	my $geneticCode = $this->{genetic_code};
	my $ref_data    = $this->{ref_data};

	$motif = substr( $motif, 0, length($motif) - 1 );
	$prefix .= $motif;

	my $i          = length($prefix);
	my @sprefix    = split( //, $prefix );
	my @aminoacids = ();
	my $remainder  = 0;
	my $non2gapped = $gap_info->{non2gapped};

	while (
		$i >= 0
		&& ( !defined($ref_data)
			|| ( $non2gapped->{$i} >= $ref_data->{non_gapped_start} ) )
	  )
	{
		my $k = $i - 3;
		my $l = $i - 1;
		if (
			(
				   defined($ref_data)
				&& $k >= 0
				&& $non2gapped->{$k} < $ref_data->{non_gapped_start}
			)
			|| $k < 0
		  )
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
	my ncbi::PAXGene $this = shift;
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
	my ncbi::PAXGene $this = shift;
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
	my ncbi::PAXGene $this = shift;
	my ($saminoacids) = @_;

	my $gene = 'Unknown';
	if ( !util::Constants::EMPTY_LINE($saminoacids) ) {
		$gene = 'PA-X';
		if (   length($saminoacids) == 41
			|| length($saminoacids) == 61 )
		{
			$gene .= length($saminoacids);
		}
		else {
			$gene .= 'Other';
		}
	}
	$this->{error_mgr}
	  ->printMsg( "gene (" . length($saminoacids) . ") = $gene" );

	return $gene;
}

sub _determineProtGiId {
	my ncbi::PAXGene $this = shift;
	my ( $gb_gi, $pstart, $send ) = @_;

	my $cds_start = defined($pstart) ? $pstart : util::Constants::HYPHEN;
	my $cds_end   = defined($send)   ? $send   : util::Constants::HYPHEN;

	my $protein_gi =
	  join( util::Constants::UNDERSCORE, 'IRD', $gb_gi, $cds_start, $cds_end );
	my $protein_id = join( util::Constants::DOT, $protein_gi, '1' );
	return ( $protein_gi, $protein_id, $cds_start, $cds_end );
}

sub _findMotif {
	my ncbi::PAXGene $this = shift;
	my ( $gap_info, $gb_gi ) = @_;

	my $mstruct = undef;
  OUTTER_LOOP:
	foreach my $direction ( 'forward', 'reverse' ) {
		my $is_reverse = ( $direction eq 'forward' ) ? 'N' : 'Y';
		my $seq = join( util::Constants::EMPTY_STR, @{ $gap_info->{useq} } );
		if ( $is_reverse eq 'Y' ) {
			$seq = $this->{genetic_code}->reverseStrand($seq);
		}
		foreach my $variant ( keys %{ $this->{motifs} } ) {
			my $motif    = $this->{motifs}->{$variant};
			my $patterns = [$motif];
			next if ( !$this->{utils}->foundPattern( $seq, $patterns ) );
			my @variants = split( /:/, $variant );
			my $svariant = $variants[0];
			my $nvariant = $variants[1];
			$this->{error_mgr}->printMsg(
"motif = $motif, variant = $variant, svariant = $svariant, nvariant = $nvariant"
			);
			$seq =~ /$motif/;
			my $prefix = $`;
			my $suffix = $';    #';
			my ( $pstart, $pend, $paminoacids ) =
			  $this->_getPrefixProtein( $gap_info, $prefix, $motif );
			my ( $sstart, $send, $saminoacids ) =
			  $this->_getSuffixProtein( $suffix, $pend );
			my ( $interval, $protein ) =
			  $this->_determineIntProt( $pstart, $pend, $paminoacids, $sstart,
				$send, $saminoacids );
			my $gene = $this->_determineGene($saminoacids);
			my ( $protein_gi, $protein_id, $cds_start, $cds_end ) =
			  $this->_determineProtGiId( $gb_gi, $pstart, $send );

			$mstruct = {
				cds_end     => $cds_end,
				cds_start   => $cds_start,
				gene        => $gene,
				interval    => $interval,
				is_reverse  => $is_reverse,
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
				svariant    => $svariant,
				variant     => $nvariant,

				non2gapped       => $gap_info->{non2gapped},
				gapped2non       => $gap_info->{gapped2non},
				non_gapped_end   => $gap_info->{non_gapped_end},
				non_gapped_start => $gap_info->{non_gapped_start},
				sseq             => $gap_info->{sseq},
				useq             => $gap_info->{useq},
				start            => $gap_info->{start},
				end              => $gap_info->{end},
			};
			last OUTTER_LOOP;
		}
	}
	return $mstruct;
}

sub _getRefData {
	my ncbi::PAXGene $this = shift;

	my $ncbi_utils = $this->{ncbi_utils};
	my $properties = $ncbi_utils->getProperties;

	$this->{ref_data} = undef;

	my $query =
	  new parallel::Query( undef, $this->{error_mgr}, $this->{tools} );
	my @data =
	  $this->_filterData( $query->getData( $properties->{referenceQuery} ) );
	$this->{error_mgr}
	  ->exitProgram( ERR_CAT, 1, [ $properties->{referenceQuery}->{query}, ],
		$query->getErrorStatus );

	my $struct = $data[0];
	$this->{tools}->printStruct( '$struct', $struct );
	$this->{error_mgr}
	  ->printHeader( "reference accession = " . $struct->{gb_accession} );

	my $gap_info = $ncbi_utils->calculateUngapped( $struct->{seq} );
	$this->{tools}->printStruct( '$gap_info', $gap_info );
	$this->{ref_data} = $this->_findMotif( $gap_info, $struct->{gb_gi} );
	$this->{ref_data}->{prefix_len} =
	  $this->{ref_data}->{pend} - $this->{ref_data}->{pstart} + 1;
	$this->{tools}->printStruct( '$this->{ref_data}', $this->{ref_data} );
}

################################################################################
#
#                                  Discard Processing
#
################################################################################

sub _readDiscardFile {
	my ncbi::PAXGene $this = shift;

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
		$this->{discard}->{current}->{$na_sequence_id} =
		  util::Constants::EMPTY_STR;
	}
	$fh->close;
}

sub _setDiscardFile {
	my ncbi::PAXGene $this = shift;

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
	my ncbi::PAXGene $this = shift;

	return $this->{discard_file};
}

sub _getDiscardFile {
	my ncbi::PAXGene $this = shift;

	return $this->{out_files}->{&DISCARD_TYPE};
}

sub _inDiscardFile {
	my ncbi::PAXGene $this = shift;
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
	my ncbi::PAXGene $this = shift;
	my ($struct) = @_;

	my $new = $this->{discard}->{new};

	$this->{error_mgr}->printMsg("Adding to discard");
	return if ( defined( $new->{ $struct->{na_sequence_id} } ) );
	$new->{ $struct->{na_sequence_id} } = util::Constants::EMPTY_STR;
	my $fh = $this->_getFh( DISCARD_TYPE, util::Constants::TRUE );
	$fh->print( $struct->{na_sequence_id} . "\n" );
}

sub _updateDiscardFile {
	my ncbi::PAXGene $this = shift;
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

################################################################################
#
#				    Methods
#
################################################################################

sub new {
	my ncbi::PAXGene $this = shift;
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

	$this->{motifs} =
	  $this->{genetic_code}->getMotifs( MOTIF_PREFIX, MOTIF_SUFFIX );

	$this->{statistic} = new util::Statistics(
		'Sequence Types', undef,
		$error_mgr,       SEQ_TAG,
		SEQ_VALS,         REVERSE_TAG,
		REVERSE_VALS,     PATYPE_TAG,
		PATYPE_VALS,      FLTUYPE_TAG,
		FLTUYPE_VALS,     SERINE_VARIANT_TAG,
		VARIANT_VALS,     VARIANT_TAG,
		VARIANT_VALS
	);
	$this->{statistic}->setShowTotal(util::Constants::TRUE);

	return $this;
}

sub process {
	my ncbi::PAXGene $this = shift;

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
	my ncbi::PAXGene $this = shift;

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

	my $query =
	  new parallel::Query( undef, $this->{error_mgr}, $this->{tools} );
	my @data =
	  $this->_filterData( $query->getData( $properties->{selectQuery} ) );
	$this->{error_mgr}
	  ->exitProgram( ERR_CAT, 1, [ $properties->{selectQuery}->{query}, ],
		$query->getErrorStatus );
	$this->{error_mgr}->printHeader( "all seqs = " . scalar @data );
	###
	### Process Sequences
	###
	foreach my $struct (@data) {
		$this->{error_mgr}->printMsg( $struct->{gb_accession} );
		next if ( $this->_inDiscardFile($struct) );
		my $gap_info = $ncbi_utils->calculateUngapped( $struct->{seq} );
		my $mstruct = $this->_findMotif( $gap_info, $struct->{gb_gi} );
		if ( defined($mstruct) ) {
			my $seqType = undef;
			if ( $this->_isUnambiguous( $mstruct->{seq} ) ) {
				$seqType = UNAMBIGUOUS_TYPE;
			}
			else { $seqType = AMBIGUOUS_TYPE; }
			###
			### It is an error for the variant to be a 'A' or 'G'
			###
			my $fileType = undef;
			if ( $mstruct->{variant} eq 'A' || $mstruct->{variant} eq 'G' ) {
				$this->{error_mgr}->registerError( ERR_CAT, 3,
					[ $mstruct->{variant}, $struct->{gb_accession} ],
					util::Constants::TRUE );
				$fileType = ERROR_TYPE;

			}
			elsif (!defined( $mstruct->{pstart} )
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
			$this->_computeStats(
				$seqType,             $mstruct->{is_reverse},
				$mstruct->{gene},     $struct->{type},
				$mstruct->{svariant}, $mstruct->{variant},
				$fileType,            length( $mstruct->{seq} ),
			);
			next;
		}
		$this->_addDiscardFile($struct);
		my $seq        = $gap_info->{ungapped_seq};
		my $fileType   = undef;
		my $gene       = undef;
		my $is_reverse = 'NA';
		my $seqType    = undef;
		my $svariant   = 'None';
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
		$this->_computeStats( $seqType, $is_reverse, $gene, $struct->{type},
			$svariant, $variant, $fileType, length($seq) );
	}
	$this->_closeFhs;
	$this->_updateDiscardFile;
}

sub processToDb {
	my ncbi::PAXGene $this = shift;

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
		SEQID_QUERY, $queries, $this->{error_mgr}, $this->{tools},
		$this->{utils}, $this->{ncbi_utils} );
	$loader->setSeqIdComp( $properties->{seqIdComp} );

	$this->{error_mgr}->printHeader("Loading Sequences");
	my $queryStatus = util::Constants::FALSE;
	my $errorCount  = 0;
  OUTTER_LOOP:
	foreach my $struct ( @{ $data->getTableInfo(MOTIF_TYPE) } ) {
		$this->{error_mgr}->printMsg( '('
			  . $struct->{gb_accession} . ', '
			  . $struct->{na_sequence_id}
			  . ')' );
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
		$this->{error_mgr}
		  ->exitProgram( ERR_CAT, 4, [], util::Constants::TRUE );
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
	my ncbi::PAXGene $this = shift;

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
