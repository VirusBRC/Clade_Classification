package tool::ortholog;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'chdir';
use File::Basename;
use File::Find ();
use FileHandle;
use Pod::Usage;

use Bio::SeqIO;

use util::Constants;
use util::Db;
use util::DbQuery;
use util::ErrMsgs;
use util::PathSpecifics;
use util::Properties;
use util::Table;

use parallel::File::OutputFiles;
use parallel::File::OrthologGroup;
use parallel::File::OrthologMap;

use tool::ErrMsgs;

use base 'tool::Tool';

use fields qw(
  recompute
  restart_steps
  runtimes
  seq_map
  start_time
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return tool::ErrMsgs::ORTHOLOG_CAT; }
###
### Run Tool Properties
###
sub CHANGESUFFIX_PROP       { return 'changeSuffix'; }
sub DELETESUFFIX_PROP       { return 'deleteSuffix'; }
sub FASTASUFFIX_PROP        { return 'fastaSuffix'; }
sub GROUPSFILE_PROP         { return 'groupsFile'; }
sub MAPPSUFFIX_PROP         { return 'mapSuffix'; }
sub ORTHOLOGSUFFIX_PROP     { return 'orthologSuffix'; }
sub ORTHOMCLCONFIGFILE_PROP { return 'orthomclConfigFile'; }
sub PRIORRUNROOT_PROP       { return 'priorRunRoot'; }
sub RESTARTSTEP_PROP        { return 'restartStep'; }
sub RUNVERSION_PROP         { return 'runVersion'; }
sub SEQMAPFILE_PROP         { return 'seqMapFile'; }

sub ORTHOLOG_PROPERTIES {
  return [
    CHANGESUFFIX_PROP,       DELETESUFFIX_PROP, FASTASUFFIX_PROP,
    GROUPSFILE_PROP,         MAPPSUFFIX_PROP,   ORTHOLOGSUFFIX_PROP,
    ORTHOMCLCONFIGFILE_PROP, PRIORRUNROOT_PROP, RESTARTSTEP_PROP,
    RUNVERSION_PROP,         SEQMAPFILE_PROP,
  ];
}
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
###
### File Specifics
###
sub POOR_PROTEINS     { return 'poorProteins'; }
sub GOOD_PROTEINS     { return 'goodProteins'; }
sub GROUPS            { return 'groups'; }
sub MCLINPUT          { return 'mclInput'; }
sub MCLOUTPUT         { return 'mclOutput'; }
sub ORTHOMCL_PAIRS    { return 'orthomclPairs'; }
sub SIMILAR_SEQUENCES { return 'similarSequences'; }

sub DB_SUFFIX    { return 'db' }
sub FAA_SUFFIX   { return 'faa' }
sub FASTA_SUFFIX { return 'fasta'; }
sub LOG_SUFFIX   { return 'log'; }
sub NEW_SUFFIX   { return 'new'; }
sub OUT_SUFFIX   { return 'out'; }
sub RERUN_SUFFIX { return 'rerun' }
sub TEXT_SUFFIX  { return 'txt'; }

sub POOR_PROTEINS_FASTA {
  return join( util::Constants::DOT, POOR_PROTEINS, FASTA_SUFFIX );
}

sub GOOD_PROTEINS_DB { return GOOD_PROTEINS; }

sub GOOD_PROTEINS_FASTA {
  return join( util::Constants::DOT, GOOD_PROTEINS, FASTA_SUFFIX );
}

sub GOOD_PROTEINS_DB_FASTA {
  return join( util::Constants::DOT, GOOD_PROTEINS, DB_SUFFIX, FASTA_SUFFIX );
}

sub NEW_QUERY_FASTA {
  return join( util::Constants::DOT, GOOD_PROTEINS, NEW_SUFFIX, FASTA_SUFFIX );
}

sub BLAST_OUT_FILE {
  return join( util::Constants::DOT, GOOD_PROTEINS, OUT_SUFFIX, TEXT_SUFFIX );
}

sub MCLINPUT_FILE  { return MCLINPUT; }
sub MCLOUTPUT_FILE { return MCLOUTPUT; }

sub ORTHOMCL_PAIRS_LOG {
  return join( util::Constants::DOT, ORTHOMCL_PAIRS, LOG_SUFFIX );
}

sub SIMILAR_SEQUENCES_FILE {
  return join( util::Constants::DOT, SIMILAR_SEQUENCES, TEXT_SUFFIX );
}
###
### Query Handle Name
###
sub DATA_ACQUISITION_QUERY { return 'data_acquisition'; }
###
### Restart Points
###
sub CREATE_AND_ADJUST_STEP     { return 'Create and Adjust Fasta'; }
sub DETERMINE_SEQ_STATUS_STEP  { return 'Determine Seq Status'; }
sub GENERATE_GOOD_PROTEIN_STEP { return 'Generate goodProtein Fasta'; }
sub GROUPS_PARSER_STEP         { return 'groupsParser'; }
sub INITIALIZE_SCHEMA_STEP     { return 'Initialize Schema'; }
sub MCL_TOOL_STEP              { return 'mclTool'; }
sub ORTHOMCL_BLAST_PARSER_STEP { return 'orthomclBlastParser'; }
sub ORTHOMCL_DUMP_PAIRS_STEP   { return 'orthomclDumpPairsFiles'; }
sub ORTHOMCL_LOAD_BLAST_STEP   { return 'orthomclLoadBlast'; }
sub ORTHOMCL_MCL_TO_GROUP_STEP { return 'orthomclMclToGroups'; }
sub ORTHOMCL_PAIRS_STEP        { return 'orthomclPairs'; }
sub RUN_BLASTALL_STEP          { return 'Run blastall'; }
sub RUN_RECOMPUTE_STEP         { return 'updateOrtho'; }

sub RESTART_STEPS {
  return {
    &DETERMINE_SEQ_STATUS_STEP  => 0,
    &CREATE_AND_ADJUST_STEP     => 1,
    &GENERATE_GOOD_PROTEIN_STEP => 2,
    &RUN_BLASTALL_STEP          => 3,
    &RUN_RECOMPUTE_STEP         => 4,
    &ORTHOMCL_BLAST_PARSER_STEP => 5,
    &INITIALIZE_SCHEMA_STEP     => 6,
    &ORTHOMCL_LOAD_BLAST_STEP   => 7,
    &ORTHOMCL_PAIRS_STEP        => 8,
    &ORTHOMCL_DUMP_PAIRS_STEP   => 9,
    &MCL_TOOL_STEP              => 10,
    &ORTHOMCL_MCL_TO_GROUP_STEP => 11,
    &GROUPS_PARSER_STEP         => 12,
  };
}

################################################################################
#
#				Private Methods
#
################################################################################

sub _getPriorFile {
  my tool::ortholog $this = shift;
  my ( $familyName, $type ) = @_;

  my $properties = $this->getProperties;

  my $groupsFile   = $properties->{groupsFile};
  my $priorRunRoot = $properties->{priorRunRoot};

  my @fileName = ($groupsFile);
  if ( !util::Constants::EMPTY_LINE($type) ) { push( @fileName, $type ); }

  my $priorFile = join( util::Constants::SLASH,
    $priorRunRoot, $familyName, join( util::Constants::DOT, @fileName ) );

  return $priorFile;
}

sub _determineSequenceStatus {
  my tool::ortholog $this = shift;
  my ( $familyName, $orthoRootDirectory ) = @_;

  $this->{recompute} = util::Constants::FALSE;

  my $properties = $this->getProperties;

  my $faaFileDir   = $properties->{dataFile};
  my $mapSuffix    = $properties->{mapSuffix};
  my $priorRunRoot = $properties->{priorRunRoot};
  my $seqMapFile   = $properties->{seqMapFile};

  return if ( util::Constants::EMPTY_LINE($priorRunRoot) );
  ###
  ### Define the Seq Maps
  ###
  my $currentSeqMapFile =
    join( util::Constants::SLASH, $faaFileDir, $seqMapFile );
  my $priorSeqMapFile = $this->_getPriorFile( $familyName, $mapSuffix );
  ###
  ### Is there prior sequence map?
  ###
  return if ( !-e $priorSeqMapFile );
  $this->{recompute} = util::Constants::TRUE;

  my $currentSeqMap =
    new parallel::File::OrthologMap( $currentSeqMapFile, $this->{error_mgr} );
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 1, [ 'current', 'read', $currentSeqMapFile ],
    $currentSeqMap->readFile );

  my $previousSeqMap =
    new parallel::File::OrthologMap( $priorSeqMapFile, $this->{error_mgr} );
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 1, [ 'previous', 'read', $priorSeqMapFile ],
    $previousSeqMap->readFile );
  ###
  ### Determine the status of Sequences
  ###
  my $statusSeqFile =
    join( util::Constants::SLASH, $orthoRootDirectory, $seqMapFile );
  my $statusSeqMap =
    new parallel::File::OrthologMap( $statusSeqFile, $this->{error_mgr} );
  foreach my $id ( $currentSeqMap->getIds ) {
    my $data = $currentSeqMap->getDataById($id);
    my $gi   = $data->{ $currentSeqMap->GI_COL };
    my $acc  = $data->{ $currentSeqMap->ACC_VERSION_COL };

    my $oGiData = $previousSeqMap->getDataByGi($gi);
    my $status  = $currentSeqMap->NEW_STATUS;
    if ( defined($oGiData) ) {
      $status = $currentSeqMap->UNCHANGED_STATUS;
    }
    elsif ( !util::Constants::EMPTY_LINE($acc) ) {
      my $oAccData = $previousSeqMap->getDataByAcc($acc);
      if ( defined($oAccData) ) {
        $status = $currentSeqMap->CHANGED_STATUS;
      }
    }
    $statusSeqMap->addSequence(
      $acc, $gi,
      $data->{ $currentSeqMap->ORGANISM_COL },
      $data->{ $currentSeqMap->SWISSPROT_COL }, $status
    );
  }
  foreach my $id ( $previousSeqMap->getIds ) {
    my $data = $previousSeqMap->getDataById($id);
    my $gi   = $data->{ $currentSeqMap->GI_COL };
    my $acc  = $data->{ $currentSeqMap->ACC_VERSION_COL };

    my $nGiData = $currentSeqMap->getDataByGi($gi);
    next if ( defined($nGiData) );
    $statusSeqMap->addSequence(
      $data->{ $previousSeqMap->ACC_VERSION_COL },
      $data->{ $previousSeqMap->GI_COL },
      $data->{ $currentSeqMap->ORGANISM_COL },
      $data->{ $previousSeqMap->SWISSPROT_COL },
      $previousSeqMap->OBSOLETE_STATUS
    );
  }
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 1, [ 'status', 'write', $statusSeqFile ],
    $statusSeqMap->writeFile );
  $this->{seq_map} = $statusSeqMap;
}

sub _addRunTime {
  my tool::ortholog $this = shift;
  my ($tool) = @_;

  my $etime  = time;
  my $struct = {
    tool    => $tool,
    runtime => $etime - $this->{start_time},
  };
  $this->{start_time} = $etime;
  push( @{ $this->{runtimes} }, $struct );
}

sub _printInfo {
  my tool::ortholog $this = shift;
  my ($tool) = @_;

  my $properties = $this->getProperties;
  my $errFile    = $properties->{errFile};

  $this->{error_mgr}->printHeader("Running Tool\n  tool = $tool");
  my $header = "###";
  my $emsg   = "$header\n$header  $tool\n$header\n";
  my $fh     = new FileHandle;
  $fh->open( $errFile, '>>' );
  $fh->print($emsg);
  $fh->close;
}

my @_FILES_ = ();

sub _filesWanted {
  my tool::ortholog $this = shift;
  my $file_pattern = '.+\.' . FAA_SUFFIX;

  return sub {
    my ( $dev, $ino, $mode, $nlink, $uid, $gid );

    ( ( $dev, $ino, $mode, $nlink, $uid, $gid ) = lstat($_) )
      && -f _
      && /^$file_pattern\z/s
      && push( @_FILES_, $FIND_NAME );
    }
}

sub _initializeSchema {
  my tool::ortholog $this = shift;
  my ($orthoConfigFile) = @_;

  my $properties = new util::Properties;
  $properties->loadFile($orthoConfigFile);
  my ( $dbi, $serverType, $databaseName ) =
    split( /:/, $properties->getProperty('dbConnectString') );
  my $dbLogin    = $properties->getProperty('dbLogin');
  my $dbPassword = $properties->getProperty('dbPassword');
  my $dbVendor   = $properties->getProperty('dbVendor');
  if    ( lc($dbVendor) eq 'oracle' ) { $serverType = 'OracleDB'; }
  elsif ( lc($dbVendor) eq 'mysql' )  { $serverType = 'mySQL'; }
  my $db =
    new util::Db( $serverType, $databaseName, $dbLogin, $dbPassword, $dbLogin,
    $this->{error_mgr} );
  $db->startTransaction;
  my $dbQueries = new util::DbQuery($db);
  my $truncateTables =
    [ 'similarsequences', 'ortholog', 'inparalog', 'coortholog', ];
  my $dropTables = [
    'besthit',             'bestintertaxonscore',
    'bestquerytaxonscore', 'betterhit',
    'coorthnotortholog',   'coorthologavgscore',
    'coorthologcandidate', 'coorthologtaxon',
    'coorthologtemp',      'inparalog2way',
    'inparalogavgscore',   'inparalogortholog',
    'inparalogtaxonavg',   'inparalogtemp',
    'inplgorthoinplg',     'inplgorthtaxonavg',
    'ortholog2way',        'orthologavgscore',
    'orthologtaxon',       'orthologtemp',
    'orthologuniqueid',    'uniqsimseqsqueryid',
  ];

  foreach my $table ( @{$truncateTables} ) {
    $dbQueries->createQuery(
      $table,
      "truncate table $table",
      "truncate $table"
    );
  }
  foreach my $table ( @{$dropTables} ) {
    my $ucTable = uc($table);
    my $query = "select table_name from all_tables where table_name = '$ucTable'";
    if ( lc($dbVendor) eq 'mysql' ) {
      $query = "show tables like '$ucTable'";
    }
    $dbQueries->createQuery( $table . 'EXIST',
      $query, "determine table exists $table" );
  }
  foreach my $table ( @{$dropTables} ) {
    $dbQueries->createQuery(
      $table . 'DROP',
      "drop table $table",
      "drop table $table"
    );
  }

  $dbQueries->prepareQueries;

  foreach my $table ( @{$truncateTables} ) {
    $dbQueries->executeUpdate($table);
  }
  foreach my $table ( @{$dropTables} ) {
    $dbQueries->executeQuery( $table . 'EXIST' );
    my $rowCount = 0;
    while ( my $row_ref = $dbQueries->fetchRowRef( $table . 'EXIST' ) ) {
      $rowCount++;
    }
    next if ( $rowCount == 0 );
    $dbQueries->executeUpdate( $table . 'DROP' );
  }

  $db->finalizeTransaction('$dbLogin Schema Initialization');
}

sub _createAndAdjust {
  my tool::ortholog $this = shift;
  my ($compliantFastaDir) = @_;

  my $properties = $this->getProperties;
  my $faaFileDir = $properties->{dataFile};

  chdir($faaFileDir);
  @_FILES_ = ();
  File::Find::find( { wanted => $this->_filesWanted }, util::Constants::DOT );
  chdir($compliantFastaDir);

  my $faaSuffix = FAA_SUFFIX;
  foreach my $faaFile (@_FILES_) {
    my $id = basename($faaFile);
    $id      =~ s/\.$faaSuffix$//;
    $faaFile =~ s/^\.\///;
    $faaFile = join( util::Constants::SLASH, $faaFileDir, $faaFile );
    $this->{error_mgr}->printMsg("faaFile = $faaFile");
    $this->executeSimpleTool( 'orthomclAdjustFasta', "$id $faaFile 4" );
  }
}

sub _createNewFasta {
  my tool::ortholog $this = shift;
  ###
  ### Create the new fasta file from the good protein
  ### file with only changed or new sequences
  ###
  my $goodProteinsFasta = GOOD_PROTEINS_FASTA;
  my $newQueryFasta     = NEW_QUERY_FASTA;

  my $gfh = new FileHandle;
  $gfh->open( $goodProteinsFasta, '<' );
  my $gFasta = new Bio::SeqIO( -fh => $gfh, -format => FASTA_SUFFIX );
  my $nfh = new FileHandle;
  $nfh->open( $newQueryFasta, '>' );
  my $nFasta = new Bio::SeqIO( -fh => $nfh, -format => FASTA_SUFFIX );
  my $seq_map = $this->{seq_map};
  while ( my $seq = $gFasta->next_seq ) {
    my $id = $seq->display_id;
    my ( $organism, $gi ) = split( /\|/, $id );
    my $data   = $seq_map->getDataByGi($gi);
    my $status = $data->{ $seq_map->STATUS_COL };
    ###
    ### Either the gi has changed for accession or is new accession
    ###
    next if ( $status eq $seq_map->UNCHANGED_STATUS );
    my $length = length( $seq->seq ) + 1;
    $nFasta->width($length);
    $nFasta->write_seq($seq);
    $nfh->print("\n");
  }
  $nfh->close;
  $gfh->close;

  return $newQueryFasta;
}

sub _generateFastaInput {
  my tool::ortholog $this = shift;
  my ($familyName) = @_;

  my $properties = $this->getProperties;
  my $tools      = $this->{tools};
  my $cmds       = $tools->cmds;

  my $goodProteinsDbFasta = GOOD_PROTEINS_DB_FASTA;
  my $goodProteinsFasta   = GOOD_PROTEINS_FASTA;

  my $fastaSuffix = $properties->{fastaSuffix};
  ###
  ### Check to see if need to compute fasta file
  ###
  my $params = util::Constants::EMPTY_STR;
  return ( $goodProteinsFasta, $goodProteinsFasta, $params )
    if ( !$this->{recompute} );
  ###
  ### Set recompute blast parameters
  ###
  $params = '-e 1e-5';
  ###
  ### Compute the blast against all previous sequences
  ### and changed or new sequences
  ###
  $this->executeSimpleTool(
    $cmds->COPY_FILE( $goodProteinsFasta, $goodProteinsDbFasta ) );
  my $priorGoodProteinFasta = $this->_getPriorFile( $familyName, $fastaSuffix );
  my $pgfh = new FileHandle;
  $pgfh->open( $priorGoodProteinFasta, '<' );
  my $pgFasta = new Bio::SeqIO( -fh => $pgfh, -format => "fasta" );
  my $gfh = new FileHandle;
  $gfh->open( $goodProteinsDbFasta, '>>' );
  my $gFasta = new Bio::SeqIO( -fh => $gfh, -format => FASTA_SUFFIX );
  my $seq_map = $this->{seq_map};

  while ( my $seq = $pgFasta->next_seq ) {
    my $id = $seq->display_id;
    my ( $organism, $gi ) = split( /\|/, $id );
    my $data   = $seq_map->getDataByGi($gi);
    my $status = $data->{ $seq_map->STATUS_COL };
    ###
    ### Either the gi has changed for accession (not defined)
    ### or gi is obsolete (defined and obsolete)
    ###
    next if ( $status ne $seq_map->OBSOLETE_STATUS );
    my $length = length( $seq->seq ) + 1;
    $gFasta->width($length);
    $gFasta->write_seq($seq);
    $gfh->print("\n");
  }
  $pgfh->close;
  $gfh->close;

  my $newQueryFasta = $this->_createNewFasta;

  return ( $goodProteinsDbFasta, $newQueryFasta, $params );
}

sub _computeOutputs {
  my tool::ortholog $this = shift;

  my $properties = $this->getProperties;
  my $seq_map    = $this->{seq_map};
  my $tools      = $this->{tools};
  my $cmds       = $tools->cmds;

  my $groupsFile   = $properties->{groupsFile};
  my $changeSuffix = $properties->{changeSuffix};
  my $deleteSuffix = $properties->{deleteSuffix};

  my $groups =
    new parallel::File::OrthologGroup( $groupsFile, $this->{error_mgr} );
  $groups->readFile;

  return $groups if ( !$this->{recompute} );
  ###
  ### Recompute groupsFile (backup generated file)
  ### Compute obsoletes and changes
  ###
  my $groupsDeleteFile =
    join( util::Constants::DOT, $groupsFile, $deleteSuffix );
  my $dfh = new FileHandle;
  $dfh->open( $groupsDeleteFile, '>' );

  my $groupsChangeFile =
    join( util::Constants::DOT, $groupsFile, $changeSuffix );
  my $cfh = new FileHandle;
  $cfh->open( $groupsChangeFile, '>' );

  my $groupsRerunFile = join( util::Constants::DOT, $groupsFile, RERUN_SUFFIX );
  $this->executeSimpleTool(
    'mv',
    "$groupsFile $groupsRerunFile",
    'moving groups file to backup'
  );
  my $fgroups =
    new parallel::File::OrthologGroup( $groupsFile, $this->{error_mgr} );
  foreach my $group_id ( $groups->getGroupIds ) {

    foreach my $item ( $groups->getGroupData($group_id) ) {
      my $gi     = $item->{ $groups->GI_COL };
      my $data   = $seq_map->getDataByGi($gi);
      my $status = $data->{ $seq_map->STATUS_COL };
      if ( $status eq $seq_map->OBSOLETE_STATUS ) {
        $dfh->print("$gi\n");
        next;
      }
      elsif ( $status ne $seq_map->UNCHANGED_STATUS ) {
        $cfh->print("$gi\n");
      }
      $fgroups->addItem(
        $group_id,
        $item->{ $groups->ORGANISM_COL },
        $item->{ $groups->GI_COL }
      );
    }
  }
  $fgroups->writeFile;

  return $fgroups;
}

sub _printRunTimes {
  my tool::ortholog $this = shift;

  my %cols = ( tool => 'Tool', runtime => 'Run Time' );
  my $table = new util::Table( $this->{error_mgr}, %cols );
  $table->setColumnJustification( 'tool',    $table->LEFT_JUSTIFY );
  $table->setColumnJustification( 'runtime', $table->RIGHT_JUSTIFY );
  $table->setColumnOrder( 'tool', 'runtime' );
  $table->setData( @{ $this->{runtimes} } );
  $table->setInHeader(util::Constants::TRUE);
  $table->generateTable("Tool Run Times");
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $utils, $error_mgr, $tools ) = @_;
  my tool::ortholog $this =
    $that->SUPER::new( 'ortholog', ORTHOLOG_PROPERTIES, $utils, $error_mgr,
    $tools );

  $this->{recompute}     = util::Constants::FALSE;
  $this->{restart_steps} = RESTART_STEPS;
  $this->{runtimes}      = [];
  $this->{seq_map}       = undef;
  $this->{start_time}    = undef;

  return $this;
}

sub run {
  my tool::ortholog $this = shift;

  $this->{runtimes}   = [];
  $this->{start_time} = time;

  my $properties   = $this->getProperties;
  my $restartPoint = undef;
  my $tools        = $this->{tools};
  my $cmds         = $tools->cmds;

  my $blastOutFile         = BLAST_OUT_FILE;
  my $goodProteinsDb       = GOOD_PROTEINS_DB;
  my $goodProteinsFasta    = GOOD_PROTEINS_FASTA;
  my $mclInputFile         = MCLINPUT_FILE;
  my $mclOutputFile        = MCLOUTPUT_FILE;
  my $newQueryFasta        = NEW_QUERY_FASTA;
  my $orthomclPairsLog     = ORTHOMCL_PAIRS_LOG;
  my $poorProteinsFasta    = POOR_PROTEINS_FASTA;
  my $similarSequencesFile = SIMILAR_SEQUENCES_FILE;

  my $changeSuffix       = $properties->{changeSuffix};
  my $deleteSuffix       = $properties->{deleteSuffix};
  my $faaFileDir         = $properties->{dataFile};
  my $fastaSuffix        = $properties->{fastaSuffix};
  my $groupsFile         = $properties->{groupsFile};
  my $mapSuffix          = $properties->{mapSuffix};
  my $mclTool            = $properties->{toolName};
  my $orthoConfigFile    = $properties->{orthomclConfigFile};
  my $orthoRootDirectory = $properties->{workspaceRoot};
  my $orthologSuffix     = $properties->{orthologSuffix};
  my $restartStep        = $properties->{restartStep};
  my $runVersion         = $properties->{runVersion};
  my $seqMapFile         = $properties->{seqMapFile};

  my $familyName = basename($orthoRootDirectory);
  ###
  ### Determine restart step
  ###
  if ( util::Constants::EMPTY_LINE($restartStep)
    || util::Constants::EMPTY_LINE($runVersion) )
  {
    $restartStep = DETERMINE_SEQ_STATUS_STEP;
  }
  chdir($orthoRootDirectory);
  my $restartNum = $this->{restart_steps}->{$restartStep};
  $this->{error_mgr}->printMsg("restartNum = $restartNum");
  ###
  ### Determine Sequence Status
  ###
  $restartPoint = DETERMINE_SEQ_STATUS_STEP;
  if ( $restartNum <= $this->{restart_steps}->{$restartPoint} ) {
    $this->_printInfo($restartPoint);
    $this->_determineSequenceStatus( $familyName, $orthoRootDirectory );
    $this->_addRunTime($restartPoint);
  }
  ###
  ### Special run directories created
  ###
  my $compliantFastaDir = $cmds->createDirectory(
    join( util::Constants::SLASH, $orthoRootDirectory, 'compliantFasta' ),
    "creating compliant fasta directory" );
  my $blastComputeDir = $cmds->createDirectory(
    join( util::Constants::SLASH, $orthoRootDirectory, 'blastCompute' ),
    "creating blast compute directory" );
  ###
  ### Adjust and create the fasta files
  ###
  $restartPoint = CREATE_AND_ADJUST_STEP;
  if ( $restartNum <= $this->{restart_steps}->{$restartPoint} ) {
    $this->_printInfo($restartPoint);
    $this->_createAndAdjust($compliantFastaDir);
    $this->_addRunTime($restartPoint);
  }
  ###
  ### filter the fasta files and create goodProteins
  ### and poorProteins fasta files
  ### Move the good and poor proteins fasta file to the blast
  ### compute directory
  ###
  $restartPoint = GENERATE_GOOD_PROTEIN_STEP;
  if ( $restartNum <= $this->{restart_steps}->{$restartPoint} ) {
    $this->_printInfo($restartPoint);
    chdir($compliantFastaDir);
    $this->executeSimpleTool( 'orthomclFilterFasta',
      "$compliantFastaDir 10 20" );
    $this->executeSimpleTool(
      'mv',
      "$goodProteinsFasta $blastComputeDir",
      'moving good proteins'
    );
    $this->executeSimpleTool(
      'mv',
      "$poorProteinsFasta $blastComputeDir",
      'moving poor proteins'
    );
    $this->_addRunTime($restartPoint);
  }
  ###
  ### Ready the goodProteins.fasta for blast and run blastall
  ### and post-processes
  ###
  $restartPoint = RUN_BLASTALL_STEP;
  if ( $restartNum <= $this->{restart_steps}->{$restartPoint} ) {
    $this->_printInfo($restartPoint);
    chdir($blastComputeDir);
    my ( $fastaDbInput, $fastaQueryInput, $params ) =
      $this->_generateFastaInput($familyName);
    $this->executeSimpleTool( 'formatdb',
      "-i $fastaDbInput -n $goodProteinsDb" );
    $this->executeSimpleTool( 'blastall',
"-p blastp $params -m 8 -a 2 -i $fastaQueryInput -d $goodProteinsDb -o $blastOutFile"
    );
    $this->_addRunTime($restartPoint);
  }
  ###
  ### Either perform new (first increment computation) or
  ### update computation
  ###
  if ( $this->{recompute} ) {
    $restartPoint = RUN_RECOMPUTE_STEP;
    if ( $restartNum <= $this->{restart_steps}->{$restartPoint} ) {
      chdir($orthoRootDirectory);
      unlink($groupsFile);
      $newQueryFasta =
        join( util::Constants::SLASH, $blastComputeDir, $newQueryFasta );
      my $priorGroupFile = $this->_getPriorFile($familyName);
      my $blastOut =
        join( util::Constants::SLASH, $blastComputeDir, $blastOutFile );

      $this->executeSimpleTool( 'updateOrtho.pl',
"-out $groupsFile -fasta $newQueryFasta -prior $priorGroupFile -blast $blastOut"
      );
      $this->_addRunTime($restartPoint);
    }
  }
  else {
    ###
    ### New run (that is, first increment)
    ###
    $restartPoint = ORTHOMCL_BLAST_PARSER_STEP;
    if ( $restartNum <= $this->{restart_steps}->{$restartPoint} ) {
      $this->_printInfo($restartPoint);
      chdir($blastComputeDir);
      unlink($similarSequencesFile);
      $this->executeSimpleTool( 'orthomclBlastParser',
        "$blastOutFile $compliantFastaDir",
        undef, undef, $similarSequencesFile );
      $this->_addRunTime($restartPoint);
    }

    $restartPoint = INITIALIZE_SCHEMA_STEP;
    if ( $restartNum <= $this->{restart_steps}->{$restartPoint} ) {
      $this->_printInfo($restartPoint);
      chdir($blastComputeDir);
      $this->_initializeSchema($orthoConfigFile);
      $this->_addRunTime($restartPoint);
    }

    $restartPoint = ORTHOMCL_LOAD_BLAST_STEP;
    if ( $restartNum <= $this->{restart_steps}->{$restartPoint} ) {
      $this->_printInfo($restartPoint);
      chdir($blastComputeDir);
      $this->executeSimpleTool( 'orthomclLoadBlast',
        "$orthoConfigFile $similarSequencesFile" );
      $this->_addRunTime($restartPoint);
    }

    $restartPoint = ORTHOMCL_PAIRS_STEP;
    if ( $restartNum <= $this->{restart_steps}->{$restartPoint} ) {
      $this->_printInfo($restartPoint);
      chdir($orthoRootDirectory);
      $this->executeSimpleTool( 'orthomclPairs',
        "$orthoConfigFile $orthomclPairsLog cleanup=no" );
      $this->_addRunTime($restartPoint);
    }

    $restartPoint = ORTHOMCL_DUMP_PAIRS_STEP;
    if ( $restartNum <= $this->{restart_steps}->{$restartPoint} ) {
      $this->_printInfo($restartPoint);
      chdir($orthoRootDirectory);
      $this->executeSimpleTool( 'orthomclDumpPairsFiles', $orthoConfigFile );
      $this->_addRunTime($restartPoint);
    }

    $restartPoint = MCL_TOOL_STEP;
    if ( $restartNum <= $this->{restart_steps}->{$restartPoint} ) {
      $this->_printInfo($restartPoint);
      chdir($orthoRootDirectory);
      $this->executeSimpleTool( $mclTool,
        "$mclInputFile --abc -I 1.5 -o $mclOutputFile" );
      $this->_addRunTime($restartPoint);
    }

    $restartPoint = ORTHOMCL_MCL_TO_GROUP_STEP;
    if ( $restartNum <= $this->{restart_steps}->{$restartPoint} ) {
      $this->_printInfo($restartPoint);
      chdir($orthoRootDirectory);
      unlink($groupsFile);
      $this->executeSimpleTool( 'orthomclMclToGroups', "groupId 1000", undef,
        $mclOutputFile, $groupsFile );
      $this->_addRunTime($restartPoint);
    }
  }

  $restartPoint = GROUPS_PARSER_STEP;
  if ( $restartNum <= $this->{restart_steps}->{$restartPoint} ) {
    $this->_printInfo($restartPoint);
    chdir($orthoRootDirectory);

    $seqMapFile = join( util::Constants::SLASH, $faaFileDir, $seqMapFile );
    my $groupsMapFile = join( util::Constants::DOT, $groupsFile, $mapSuffix );
    $this->executeSimpleTool(
      'cp',
      "$seqMapFile $groupsMapFile",
      'copying group protein file'
    );

    my $groupsFastaFile =
      join( util::Constants::DOT, $groupsFile, $fastaSuffix );
    $goodProteinsFasta =
      join( util::Constants::SLASH, $blastComputeDir, $goodProteinsFasta );
    $this->executeSimpleTool(
      'cp',
      "$goodProteinsFasta $groupsFastaFile",
      'copying group protein file'
    );

    my $groupsDeleteFile =
      join( util::Constants::DOT, $groupsFile, $deleteSuffix );
    unlink($groupsDeleteFile);

    my $groupsChangeFile =
      join( util::Constants::DOT, $groupsFile, $changeSuffix );
    unlink($groupsChangeFile);

    my $groups = $this->_computeOutputs;

    my $groupsOrthologFile =
      join( util::Constants::DOT, $groupsFile, $orthologSuffix );
    unlink($groupsOrthologFile);
    $groups->writeLinearFile($groupsOrthologFile);

    $this->executeSimpleTool( $cmds->TOUCH_CMD($groupsDeleteFile) );
    $this->executeSimpleTool( $cmds->TOUCH_CMD($groupsChangeFile) );

    my $orthologOutput =
      new parallel::File::OutputFiles( $properties->{outputFile},
      $this->{error_mgr} );
    $groupsFile =
      join( util::Constants::SLASH, $orthoRootDirectory, $groupsFile );
    $orthologOutput->addOutputFile( $familyName, $groupsFile );

    my $status = $orthologOutput->writeFile;
    $tools->setStatus( $tools->FAILED ) if ($status);
    $this->_addRunTime($restartPoint);
  }

  $this->_printRunTimes;
}

################################################################################

1;

__END__

=head1 NAME

ortholog.pm

=head1 DESCRIPTION

This class defines the runner for ortholog.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::ortholog(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
