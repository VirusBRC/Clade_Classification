package tool::fomaSNP;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'chdir';
use File::Basename;
use FileHandle;
use Pod::Usage;

use util::Constants;
use util::Properties;
use util::TableData;

use tool::ErrMsgs;

use parallel::File::AccessionMap;
use parallel::File::OutputFiles;

use Bio::AlignIO;

use base 'tool::Tool';

use fields qw(
  clustalw
  clustalw_path
  cluster_align_path
  data
  getorf_path
  fasta_data
  file_group_tag
  files
  group_tag
  host
  length_cutoff
  log_base
  min_num_seq
  muscle_path
  output_file
  run_clustalw
  segment
  seqs_file_ord
  skip_groups
  skip_groups_file
  strain_name_cutoff
  subtype
  ucluster_path
  unknown_consensus_symbol
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
###
### Run Tool Properties
###
sub CLUSTALWFORSKIPGROUP_PROP   { return 'clustalwForSkipGroup'; }
sub CLUSTALWPATH_PROP           { return 'clustalWPath'; }
sub CLUSTERALIGNPATH_PROP       { return 'clusterAlignPath'; }
sub GETORFPATH_PROP             { return 'getOrfPath'; }
sub LENGTHCUTOFF_PROP           { return 'lengthCutoff'; }
sub LOGBASE_PROP                { return 'logBase'; }
sub MINNUMSEQ_PROP              { return 'minNumSeq'; }
sub MUSCLEPATH_PROP             { return 'musclePath'; }
sub RUNCLUSTALW_PROP            { return 'runClustalw'; }
sub SEQSFILEORD_PROP            { return 'seqsFileOrd'; }
sub SKIPGROUPS_PROP             { return 'skipGroups'; }
sub STRAINNAMECUTOFF_PROP       { return 'strainNameCutoff'; }
sub UCLUSTERPATH_PROP           { return 'uclusterPath'; }
sub UNKNOWNCONSENSUSSYMBOL_PROP { return 'unknownConsensusSymbol'; }

sub FOMASNP_PROPERTIES {
  return (
    CLUSTALWFORSKIPGROUP_PROP, CLUSTALWPATH_PROP,
    CLUSTERALIGNPATH_PROP,     GETORFPATH_PROP,
    LENGTHCUTOFF_PROP,         LOGBASE_PROP,
    MINNUMSEQ_PROP,            MUSCLEPATH_PROP,
    RUNCLUSTALW_PROP,          SEQSFILEORD_PROP,
    SKIPGROUPS_PROP,           STRAINNAMECUTOFF_PROP,
    UCLUSTERPATH_PROP,         UNKNOWNCONSENSUSSYMBOL_PROP
  );
}

sub FILE_TYPES { return ( 'properties', 'refseqs', 'seqs', 'strains' ); }
###
### Output Files
###
sub FOMA_FILE { return 'foma'; }
sub ZIP_FILE  { return 'zip'; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _setSkipGroups {
  my tool::fomaSNP $this = shift;

  $this->{skip_groups} = {};
  my $file = $this->{skip_groups_file};
  return if ( util::Constants::EMPTY_LINE($file) );
  my $fh = $this->openFile( $file, '<' );
  while ( !$fh->eof ) {
    my $val = $fh->getline;
    chomp($val);
    next if ( util::Constants::EMPTY_LINE($val) || $val =~ /^#/ );
    $this->{skip_groups}->{ uc($val) } = util::Constants::EMPTY_STR;
  }
  $fh->close;
}

sub _initializeData {
  my tool::fomaSNP $this = shift;
  ###
  ### Get the Files
  ###
  $this->{files} = {};
  my $dataDir = $this->getProperties->{dataFile};
  foreach my $suffix (FILE_TYPES) {
    my $file = join( util::Constants::SLASH,
      $dataDir, join( util::Constants::DOT, basename($dataDir), $suffix ) );
    $this->{files}->{$suffix} = $file;
  }
  my $files = $this->{files};
  ###
  ### Create output file
  ###
  $this->{output_file} =
    new parallel::File::OutputFiles( $this->getProperties->{outputFile},
    $this->{error_mgr} );
  my $output_file = $this->{output_file};
  $output_file->readFile
    if ( -e $output_file->getOutputFilesFile
    && !-z $output_file->getOutputFilesFile );
  ###
  ### Create data from the data directory
  ###
  $this->{data} = {
    properties => new util::Properties,
    refseqs    =>
      new parallel::File::AccessionMap( $files->{refseqs}, $this->{error_mgr} ),
    strains =>
      new parallel::File::AccessionMap( $files->{strains}, $this->{error_mgr} ),
    seqs => new util::TableData( undef, $this->{tools}, $this->{error_mgr} ),
  };
  eval { $this->{data}->{properties}->loadFile( $files->{properties} ); };
  my $status = $@;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 1,
    [ 'properties', $files->{properties} ],
    defined($@) && $@
  );
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 1,
    [ 'strains', $files->{strains} ],
    $this->{data}->{strains}->readFile
  );
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 1,
    [ 'refseqs', $files->{refseqs} ],
    $this->{data}->{refseqs}->readFile
  );
  ###
  ### Get standard properties
  ###
  my $properties = $this->{data}->{properties};
  $this->{file_group_tag} = $properties->getProperty('file_group_tag');
  $this->{group_tag}      = $properties->getProperty('group_tag');
  $this->{host}           = $properties->getProperty('host');
  $this->{segment}        = $properties->getProperty('segment');
  $this->{subtype}        = $properties->getProperty('subtype');

  $this->{data}->{seqs}->setTableData( 'seqs', $this->{seqs_file_ord} );
  $this->{data}->{seqs}->setFile( 'seqs', $files->{seqs} );
  $this->{data}->{seqs}->setTableInfoRaw('seqs');
}

sub _generateFoma {
  my tool::fomaSNP $this = shift;
  my ($symFreq) = @_;

  my $foma      = 0;
  my $totalFreq = 0;
  foreach my $pi ( @{$symFreq} ) {
    $totalFreq += $pi;
    $foma += $pi * ( log($pi) / log( $this->{log_base} ) );
  }
  $totalFreq = sprintf( "%.6f", $totalFreq );
  $this->{error_mgr}->exitProgram( ERR_CAT, 6, [$totalFreq], $totalFreq > 1 );
  ###
  ### Generate final presentation value
  ###
  $foma = sprintf( "%.2f", 0 - $foma ) * 100;
  return $foma;
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $properties, $utils, $error_mgr, $tools ) = @_;

  push( @{$properties}, FOMASNP_PROPERTIES );

  my tool::fomaSNP $this =
    $that->SUPER::new( 'fomaSNP', $properties, $utils, $error_mgr, $tools );

  my $lproperties = $this->getLocalDataProperties;

  $this->{clustalw_path}            = $lproperties->{clustalWPath};
  $this->{clustalw}                 = $lproperties->{clustalwForSkipGroup};
  $this->{cluster_align_path}       = $lproperties->{clusterAlignPath};
  $this->{data}                     = undef;
  $this->{fasta_data}               = undef;
  $this->{files}                    = undef;
  $this->{getorf_path}              = $lproperties->{getOrfPath};
  $this->{group_tag}                = undef;
  $this->{host}                     = undef;
  $this->{length_cutoff}            = $lproperties->{lengthCutoff};
  $this->{log_base}                 = $lproperties->{logBase};
  $this->{min_num_seq}              = $lproperties->{minNumSeq};
  $this->{muscle_path}              = $lproperties->{musclePath};
  $this->{run_clustalw}             = $lproperties->{runClustalw};
  $this->{segment}                  = undef;
  $this->{seqs_file_ord}            = $lproperties->{seqsFileOrd};
  $this->{skip_groups_file}         = $lproperties->{skipGroups};
  $this->{skip_groups}              = undef;
  $this->{strain_name_cutoff}       = $lproperties->{strainNameCutoff};
  $this->{subtype}                  = undef;
  $this->{ucluster_path}            = $lproperties->{uclusterPath};
  $this->{unknown_consensus_symbol} = $lproperties->{unknownConsensusSymbol};

  return $this;
}

sub createInfluenzaFile {
  my tool::fomaSNP $this = shift;
  my ( $infix, $suffix ) = @_;

  return join( util::Constants::SLASH,
    $this->getProperties->{workspaceRoot},
    join( util::Constants::UNDERSCORE,
      join( util::Constants::DOT, 'Influenza', $infix, $suffix ),
      $this->fileGroupTag
    )
  );
}

sub createFile {
  my tool::fomaSNP $this = shift;
  my ($suffix) = @_;

  #######################
  ### Abstract Method ###
  #######################
}

sub runData {
  my tool::fomaSNP $this = shift;

  #######################
  ### Abstract Method ###
  #######################
}

sub run {
  my tool::fomaSNP $this = shift;

  $this->_initializeData;
  $this->_setSkipGroups;

  $ENV{MUSCLE}   = $this->{muscle_path};
  $ENV{UCLUSTER} = $this->{ucluster_path};

  my $properties = $this->getProperties;
  chdir( $properties->{workspaceRoot} );
  $this->{error_mgr}->printHeader( "GroupTag " . $this->groupTag );

  $this->runData;
  $this->{output_file}->writeFile(util::Constants::TRUE);
}

sub getFiles {
  my tool::fomaSNP $this = shift;
  return $this->{files};
}

sub getData {
  my tool::fomaSNP $this = shift;
  return $this->{data};
}

sub fileGroupTag {
  my tool::fomaSNP $this = shift;
  return $this->{file_group_tag};
}

sub groupTag {
  my tool::fomaSNP $this = shift;
  return $this->{group_tag};
}

sub openFile {
  my tool::fomaSNP $this = shift;
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
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 2, [ $mode, $file, $status_msg ], $status );
  return $fh;
}

sub fasta2ClustalalW {
  my tool::fomaSNP $this = shift;
  my ( $fasta_file, $clustalw_file ) = @_;

  eval {
    my $in = Bio::AlignIO->new( '-file' => $fasta_file, '-format' => 'fasta' );
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
  $this->{error_mgr}
    ->registerError( ERR_CAT, 3, [ $fasta_file, $clustalw_file ], $status );
  return $status;
}

sub clwOutStrainNameFormat {
  my tool::fomaSNP $this = shift;
  my ($file) = @_;

  my $strains     = $this->getData->{strains};
  my $output_file = $this->{output_file};
  my $cmds        = $this->{tools}->cmds;

  my $zip_file = $this->createFile(ZIP_FILE);
  if ( !-e $file ) {
    $output_file->addOutputFile( ZIP_FILE, $zip_file );
    return;
  }
  ###
  ### First copy file to backup
  ###
  my $backup_file = join( util::Constants::DOT, $file, 'backup' );
  my $msgs = { cmd => $cmds->COPY_FILE( $file, $backup_file ), };
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 8,
    [ $file, $backup_file ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'copying clw file' )
  );
  ###
  ### Now create new clw file
  ###
  my $iFh = $this->openFile( $file, '<' );
  my $tmp_file = $cmds->TMP_FILE( 'clw', 'tmp' );
  my $oFh       = $this->openFile($tmp_file);
  my $line_diff = 0;
  while ( !$iFh->eof ) {
    my $line = $iFh->getline;
    chomp($line);
    if ( util::Constants::EMPTY_LINE($line)
      || $line =~ /(muscle|clustal w)/i )
    {
      $oFh->print("$line\n");
      next;
    }
    my ( $header, $seq ) = split( / +/, $line );
    if (
      !( $line =~ /^ +$/ || $line =~ /\*/ || $line =~ / \./ || $line =~ /:/ )
      && ( util::Constants::EMPTY_LINE($header)
        || util::Constants::EMPTY_LINE($seq) )
      )
    {
      $oFh->print("$line\n");
      next;
    }
    my ( $acc, $junk ) = split( /\//, $header );
    $acc =~ s/\|//g;
    my $strain   = $strains->getVal($acc);
    my $new_line = util::Constants::EMPTY_STR;
    if ( defined($strain) ) {
      $new_line = "$acc|$strain";
      if ( length($new_line) > $this->{strain_name_cutoff} ) {
        $new_line = substr( $new_line, 0, $this->{strain_name_cutoff} );
      }
      my $add_char = $this->{strain_name_cutoff} - length($new_line);
      if ( $add_char > 0 ) {
        for ( my $j = 0 ; $j < $add_char ; $j++ ) {
          $new_line .= util::Constants::SPACE;
        }
      }
      $new_line .= $seq;
      if ( $line_diff == 0 ) { $line_diff = length($new_line) - length($line); }
    }
    elsif ( $line =~ /^ +$/ || $line =~ /\*/ || $line =~ / \./ || $line =~ /:/ )
    {
      $new_line = &util::Constants::SPACE x $line_diff . $line;
    }
    else {
      $new_line = $line;
    }
    $oFh->print("$new_line\n");
  }
  $iFh->close;
  $oFh->close;
  $msgs = { cmd => $cmds->MOVE_FILE( $tmp_file, $file ), };
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 4,
    [ $tmp_file, $file ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'moving new clw file' )
  );

  $msgs = { cmd => "zip -r $zip_file " . basename($file), };
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 5,
    [ $file, $zip_file ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'zipping up clw file' )
  );
  $output_file->addOutputFile( ZIP_FILE, $zip_file );
}

sub readFastaFile {
  my tool::fomaSNP $this = shift;
  my ($fasta_file) = @_;

  $this->{error_mgr}
    ->printHeader( "Reading Fasta File\n" . "  file = $fasta_file" );

  my $status = util::Constants::TRUE;
  $this->{fasta_data} = {
    acc2Aln          => {},
    conArray         => [],
    consensus        => [],
    foma             => [],
    headerIssue      => util::Constants::FALSE,
    numSeq           => 0,
    printHash        => {},
    symbolHash       => {},
    unGap2GapMapping => {},
    ungapped_end     => 0,
  };
  my $data = $this->{fasta_data};
  ###
  ### initialize example for nucleotide (similar for amino-acids)
  ###
  ###   $data->{conArray} =
  ###     [
  ###      {A=>7, T=>1, C=>1, G=>1, '-'=>0},
  ###      {A=>0, T=>8, C=>0, G=>0, '-'=>2},
  ###      ...
  ###     ]
  ###
  $/ = '>';
  my $fh = $this->openFile( $fasta_file, '<' );
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    next if ( $line !~ s/^([^\n]+)\n// );
    my $header = $1;
    $this->{error_mgr}->printMsg("doing, $header");
    my $acc = undef;
    if ( $header =~ /^([^\|]+)\|/ ) {
      $acc = $1;
    }
    else {
      $acc = $header;
      $this->{error_mgr}
        ->printWarning( "problem_with_header $header", util::Constants::TRUE );
      $data->{headerIssue} = util::Constants::TRUE;
    }
    $line =~ s/\n//g;
    my ( $nonGapStart, $nonGapEnd, $seq ) =
      $this->{utils}->getOffsetTrailing($line);
    $data->{acc2Aln}->{$acc} = $seq;
    for ( my $i = $nonGapStart ; $i <= $nonGapEnd ; $i++ ) {
      $status = util::Constants::FALSE;
      my $symbol = $seq->[$i];
      $data->{symbolHash}->{$symbol} = util::Constants::EMPTY_STR;
      if ( !defined( $data->{conArray}->[$i] ) ) {
        $data->{conArray}->[$i] = {};
      }
      if ( defined( $data->{conArray}->[$i]->{$symbol} ) ) {
        $data->{conArray}->[$i]->{$symbol}++;
      }
      else { $data->{conArray}->[$i]->{$symbol} = 1; }    ### first time
    }
    $data->{numSeq}++;
  }
  $fh->close;
  $/ = util::Constants::NEWLINE;
  return $status if ($status);
  ###
  ### initialize example for nucleotide (similar for amino-acid)
  ###
  ###   $data->{printHash} =
  ###     {
  ###      'A'=> [0,0,0,...,0],
  ###      'T'=> [0,0,0,...,0],
  ###      'C'=> [0,0,0,...,0],
  ###      'G'=> [0,0,0,...,0],
  ###      '-'=> [0,0,0,...,0],
  ###     }
  ###
  foreach my $alphabet ( keys %{ $data->{symbolHash} } ) {
    $data->{printHash}->{$alphabet} = [];
    foreach my $index ( 0 .. $#{ $data->{conArray} } ) {
      $data->{printHash}->{$alphabet}->[$index] = 0;
    }
  }
  foreach my $cindex ( 0 .. $#{ $data->{conArray} } ) {
    my $col        = $data->{conArray}->[$cindex];
    my $conSymbol  = $this->{unknown_consensus_symbol};
    my $totalCount = 0;
    my $symFreq    = [];
    foreach my $val ( values %{$col} ) { $totalCount += $val; }
    foreach my $symbol ( keys %{$col} ) {
      my $symCount = $col->{$symbol};
      $data->{printHash}->{$symbol}->[$cindex] = $symCount;
      push( @{$symFreq}, $symCount / $totalCount );
      if ( $symCount > $totalCount / 2 ) { $conSymbol = $symbol; }
    }
    $data->{foma}->[$cindex]                  = $this->_generateFoma($symFreq);
    $data->{consensus}->[$cindex]             = $conSymbol;
    $data->{conArray}->[$cindex]->{totalSeq}  = $totalCount;
    $data->{conArray}->[$cindex]->{consensus} = $conSymbol;
    $data->{conArray}->[$cindex]->{foma}      = $data->{foma}->[$cindex];
    if ( $conSymbol ne util::Constants::HYPHEN ) {
      $data->{unGap2GapMapping}->{ $data->{ungapped_end} } = $cindex;
      $data->{ungapped_end}++;
    }
  }
  ###
  ### Debugging Data
  ###
  if ( $this->{error_mgr}->isDebugging ) {
    my $workspaceRoot = $this->getProperties->{workspaceRoot};
    my $serializer    = $this->{tools}->serializer;
    my $gaf_file = join( util::Constants::SLASH, $workspaceRoot, 'gaf.log' );
    my $gafFh    = $this->openFile($gaf_file);
    $gafFh->print(
      $serializer->serializeObject(
        $data, $serializer->PERL_OBJECT_WRITE_OPTIONS
      )
    );
    $gafFh->close;
  }
  ###
  ###
  ###
  return $status;
}

sub getTab {
  my tool::fomaSNP $this = shift;
  my (@cols) = @_;
  return join( "\t", @cols ) . "\n";
}

sub printTab {
  my tool::fomaSNP $this = shift;
  my ( $fh, @cols ) = @_;
  $fh->print( $this->getTab(@cols) );
}

################################################################################

1;

__END__

=head1 NAME

fomaSNP.pm

=head1 DESCRIPTION

This class defines the runner for fomaSNP.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::fomaSNP(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
