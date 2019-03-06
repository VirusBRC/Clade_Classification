package parallel::Component::Move::rate4site;
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
use util::DbQuery;
use util::Statistics;

use parallel::File::Rate4Site;

use base 'parallel::Component::Move';

use fields qw(
  counter
  db_queries
  insert_cols
  queries
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### rate4site Specific Properties from the Controller Configuration
###
sub PDBFILEPATTERN_PROP    { return 'pdbFilePattern'; }
sub RESULTFILEPATTERN_PROP { return 'resultFilePattern'; }

sub R4S_PROPERTIES { return [ PDBFILEPATTERN_PROP, RESULTFILEPATTERN_PROP, ]; }
###
### PDB Queries
###
sub RATE4SITE_DELETE_QUERY { return 'rate4site delete query'; }
sub RATE4SITE_INSERT_QUERY { return 'rate4site insert query'; }
sub RATE4SITE_QUERY        { return 'rate4site query'; }
sub SEQUENCE_NO_QUERY      { return 'sequence id query'; }

sub R4S_QUERIES {
  return {
    &SEQUENCE_NO_QUERY => {
      ord   => [ 'seq_no', ],
      query => "
select brcwarehouse.pdb_other_file_id_sq.nextval 
from   dual
",
    },

    &RATE4SITE_QUERY => {
      ord =>
        [ 'pdbaccession', 'file_type', 'file_name', 'description', 'file_id', ],
      query => "
select pdbaccession,
       file_type,
       file_name,
       description,
       file_id
from   brcwarehouse.pdb_other_files 
",
    },

    &RATE4SITE_INSERT_QUERY => {
      ord =>
        [ 'pdbaccession', 'file_type', 'file_name', 'description', 'file_id', ],
      query => "
insert into brcwarehouse.pdb_other_files
       (pdbaccession,
        file_type,
        file_name,
        description,
        file_id)
values (?, ?, ?, ?, ?)
",
    },

    &RATE4SITE_DELETE_QUERY => {
      ord   => [ 'pdbaccession', ],
      query => "
delete from brcwarehouse.pdb_other_files
where  pdbaccession = ?
",
    },
  };
}
###
### Insert Structures
###
sub R4S_FILE      { return 'rate4site'; }
sub R4S_FULL_FILE { return 'rate4site full sequence only'; }

sub R4S_INSERT_COLS {
  return {
    &R4S_FILE => {
      pdbaccession => undef,
      file_type    => R4S_FILE,
      file_name    => undef,
      description  => 'Sequence conservation computed using all sequences',
      file_id      => undef,
    },

    &R4S_FULL_FILE => {
      pdbaccession => undef,
      file_type    => R4S_FULL_FILE,
      file_name    => undef,
      description => 'Sequence conservation computed using full sequences only',
      file_id     => undef,
    },
  };
}
###
### Counting Statistic
###
sub CURRENT_TAG { return 'current'; }
sub NEW_TAG     { return 'new'; }

sub IN_COPIED_VAL   { 'IN COPIED'; }
sub IN_DELETED_VAL  { 'IN DELETE'; }
sub IN_KEPT_VAL     { 'IN KEPT'; }
sub IN_REPLACED_VAL { 'IN REPLACED'; }
sub NOT_IN_VAL      { 'NOT IN'; }

sub R4S_TAGS {
  return (
    CURRENT_TAG, [ IN_REPLACED_VAL, IN_KEPT_VAL, IN_DELETED_VAL, NOT_IN_VAL, ],
    NEW_TAG, [ IN_COPIED_VAL, NOT_IN_VAL, ],
  );
}

################################################################################
#
#                           Private Methods
#
################################################################################

sub _openSession {
  my parallel::Component::Move::rate4site $this = shift;

  my $tools = $this->{tools};
  $tools->openSession;
  my $db = $tools->getSession;
  $db->startTransaction;
  $this->{db_queries} = new util::DbQuery($db);

  my $db_queries = $this->{db_queries};
  my $queries    = $this->{queries};
  foreach my $query ( keys %{$queries} ) {
    my $query_data = $queries->{$query};
    $this->{error_mgr}->printMsg( "Preparing Query\n" . "  query = $query" );
    $db_queries->createQuery( $query, $query_data->{query}, $query );
    $db_queries->prepareQuery($query);
  }
}

sub _containsNulls {
  my parallel::Component::Move::rate4site $this = shift;
  my ($file) = @_;

  my $fh = new FileHandle;
  $fh->open( $file, '<' );
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    if ( $line =~ /null/i ) {
      $fh->close;
      return util::Constants::TRUE;
    }
  }
  $fh->close;

  return util::Constants::FALSE;
}

sub _getStruct {
  my parallel::Component::Move::rate4site $this = shift;
  my ( $row, $query ) = @_;

  my $qdata = $this->{queries}->{$query};
  my $ord   = $qdata->{ord};

  my $struct = {};
  foreach my $index ( 0 .. $#{$ord} ) {
    $struct->{ $ord->[$index] } = $row->[$index];
  }
  return $struct;
}

sub _getParams {
  my parallel::Component::Move::rate4site $this = shift;
  my ( $struct, $query ) = @_;

  my $qdata = $this->{queries}->{$query};
  my $ord   = $qdata->{ord};

  my @params = ();
  foreach my $col ( @{$ord} ) {
    push( @params, $struct->{$col} );
  }
  return @params;
}

sub _getSeqNo {
  my parallel::Component::Move::rate4site $this = shift;

  my $db_queries = $this->{db_queries};

  $db_queries->executeQuery(SEQUENCE_NO_QUERY);
  my $seq_no = undef;
  while ( my $row_ref = $db_queries->fetchRowRef(SEQUENCE_NO_QUERY) ) {
    my $struct = $this->_getStruct( $row_ref, SEQUENCE_NO_QUERY );
    $seq_no = $struct->{seq_no};
  }
  $db_queries->finishQuery(RATE4SITE_QUERY);
  return $seq_no;
}

sub _insertR4sRow {
  my parallel::Component::Move::rate4site $this = shift;
  my ( $file_type, $pdb_id, $file ) = @_;

  my $db_queries  = $this->{db_queries};
  my $insert_cols = $this->{insert_cols};

  my $struct = { %{ $insert_cols->{$file_type} } };
  $struct->{pdbaccession} = $pdb_id;
  $struct->{file_name}    = basename($file);
  $struct->{file_id}      = $this->_getSeqNo;
  $this->{tools}->printStruct( 'insert record', $struct );
  $db_queries->executeUpdate( RATE4SITE_INSERT_QUERY,
    $this->_getParams( $struct, RATE4SITE_INSERT_QUERY ) );
}

sub _deleteR4sRows {
  my parallel::Component::Move::rate4site $this = shift;
  my ($pdb_id) = @_;

  my $db_queries = $this->{db_queries};
  $this->{error_mgr}->printMsg("Deleting from database $pdb_id");
  $db_queries->executeUpdate( RATE4SITE_DELETE_QUERY, $pdb_id );
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::Move::rate4site $this =
    $that->SUPER::new( R4S_PROPERTIES, 'rate4site', $controller, $utils,
    $error_mgr, $tools );

  $this->{db_queries}  = undef;
  $this->{insert_cols} = R4S_INSERT_COLS;
  $this->{queries}     = R4S_QUERIES;
  ###
  ### Create Counting Statistic
  ###
  $this->{counter} =
    new util::Statistics( "Pdb Files", undef, $this->{error_mgr}, R4S_TAGS );
  $this->{counter}->setShowTotal(util::Constants::TRUE);
  $this->{counter}->setCountsToZero;

  return $this;
}

sub move_data {
  my parallel::Component::Move::rate4site $this = shift;

  my $tools      = $this->{tools};
  my $cmds       = $tools->cmds;
  my $counter    = $this->{counter};
  my $properties = $this->getProperties;
  ###
  ### Setup remote information
  ###
  my $server               = $this->getDestinationServer;
  my $destinationDirectory = $this->getDestinationDirectory;
  my $resultFilePattern    = $properties->{resultFilePattern};
  ###
  ### Open Database Session
  ###
  $this->_openSession;
  my $db_queries = $this->{db_queries};
  ###
  ### Get Current pdb IDS
  ###
  my $currentPdbs = {};
  $db_queries->executeQuery(RATE4SITE_QUERY);
  while ( my $row_ref = $db_queries->fetchRowRef(RATE4SITE_QUERY) ) {
    my $struct = $this->_getStruct( $row_ref, RATE4SITE_QUERY );
    if ( !defined( $currentPdbs->{ $struct->{pdbaccession} } ) ) {
      $currentPdbs->{ $struct->{pdbaccession} } = {};
    }
    $currentPdbs->{ $struct->{pdbaccession} }->{ $struct->{file_type} } =
      $struct;
  }
  $db_queries->finishQuery(RATE4SITE_QUERY);
  ###
  ### Determining Results to Copy to Shared File System
  ###
  my $msgs = {};
  $this->generateComponents;
  my $pdbFilePattern = $properties->{pdbFilePattern};
  my $newPdb         = {};
  foreach my $sourceDir ( @{ $properties->{sourceDirectories} } ) {
    my $resultFile = join( util::Constants::SLASH,
      $tools->setWorkspaceForProperty($sourceDir),
      $this->makeFile
    );
    $this->{error_mgr}
      ->printHeader( "Determining rate4site files to copy over\n"
        . "Result File = $resultFile" );
    my $r4sFiles =
      new parallel::File::Rate4Site( $resultFile, $this->{error_mgr} );
    $r4sFiles->readFile;
    foreach my $pdb ( $r4sFiles->getPdbs ) {
      my ( $r4s_file,  $r4s_status )  = $r4sFiles->getRate4SiteFile($pdb);
      my ( $r4s_ffile, $r4s_fstatus ) = $r4sFiles->getRate4SiteFullFile($pdb);
      ###
      ### Only those with both non-zero rate4site files
      ###
      next
        if ( $r4s_status eq $r4sFiles->FILE_NOT_EXISTS
        || $r4s_fstatus eq $r4sFiles->FILE_NOT_EXISTS );
      ###
      ### neither file contains nulls
      ###
      next
        if ( $this->_containsNulls($r4s_file)
        || $this->_containsNulls($r4s_ffile) );
      $pdb =~ /$pdbFilePattern/;
      my $pdb_id = uc($1);
      my $alreadyDefined =
        ( defined( $newPdb->{$pdb_id} ) )
        ? util::Constants::TRUE
        : util::Constants::FALSE;
      $newPdb->{$pdb_id} = util::Constants::EMPTY_STR;
      $counter->increment( CURRENT_TAG,
        ( defined( $currentPdbs->{$pdb_id} ) ) ? IN_REPLACED_VAL : NOT_IN_VAL,
        NEW_TAG, IN_COPIED_VAL )
        if ( !$alreadyDefined );
      ###
      ### Copy files to working directory for bulk copy to share
      ###
      $this->{error_mgr}->printMsg( "New PDB\n"
          . "  pdb_id        = $pdb_id\n"
          . "  r4s file      = $r4s_file\n"
          . "  r4s full file = $r4s_file" );
      $msgs->{cmd} = $cmds->COPY_FILE( $r4s_file, $this->getWorkspaceRoot );
      $cmds->executeCommand( $msgs, $msgs->{cmd},
        'copying r4s result to workspace' );
      $msgs->{cmd} = $cmds->COPY_FILE( $r4s_ffile, $this->getWorkspaceRoot );
      $cmds->executeCommand( $msgs, $msgs->{cmd},
        'copying r4s full result to workspace' );
      ###
      ### Determine if an insert is needed
      ###
      next if ( $alreadyDefined || defined( $currentPdbs->{$pdb_id} ) );
      ###
      ### Insert rate4site
      ###
      $this->_insertR4sRow( R4S_FILE,      $pdb_id, $r4s_file );
      $this->_insertR4sRow( R4S_FULL_FILE, $pdb_id, $r4s_ffile );
    }
  }
  ###
  ### Determine pdb IDs that will not be copied over
  ### to shared file system
  ### and process deletes as necessary (those containing nulls)
  ###
  my $missingDir = $cmds->createDirectory(
    join( util::Constants::SLASH,
      $this->getWorkspaceRoot, $cmds->TMP_FILE( 'move', 'missing' )
    ),
    'creating missing directory',
    util::Constants::TRUE
  );
  $this->{error_mgr}->printHeader("Deleting Null Pdb Files On Share");
  foreach my $pdb_id ( sort keys %{$currentPdbs} ) {
    next if ( defined( $newPdb->{$pdb_id} ) );
    $this->{error_mgr}->printMsg("Current PDB ID not in new data = $pdb_id");
    ###
    ### Determine whether current data have null's in it.  If so,
    ### delete the pdb ID from database and remove files from
    ### shared file server
    ###
    my $data     = $currentPdbs->{$pdb_id};
    my $r4s_file = $data->{&R4S_FILE}->{file_name};
    $msgs->{cmd} = "scp $server:$destinationDirectory/$r4s_file $missingDir";
    $cmds->executeCommand( $msgs, $msgs->{cmd},
      'copying missing r4s file from share' );
    my $r4s_ffile = $data->{&R4S_FULL_FILE}->{file_name};
    $msgs->{cmd} = "scp $server:$destinationDirectory/$r4s_ffile $missingDir";
    $cmds->executeCommand( $msgs, $msgs->{cmd},
      'copying missing r4s full file from share' );

    if ( !$this->_containsNulls("$missingDir/$r4s_file")
      && !$this->_containsNulls("$missingDir/$r4s_ffile") )
    {
      $this->{error_mgr}->printMsg("KEEPING PDB $pdb_id");
      $counter->increment( CURRENT_TAG, IN_KEPT_VAL, NEW_TAG, NOT_IN_VAL );
      next;
    }
    $counter->increment( CURRENT_TAG, IN_DELETED_VAL, NEW_TAG, NOT_IN_VAL );
    $this->{error_mgr}->printMsg( "Deleting PDB\n"
        . "  pdb_id        = $pdb_id\n"
        . "  r4s file      = $r4s_file\n"
        . "  r4s full file = $r4s_file" );
    $msgs->{cmd} = "ssh $server '/bin/rm -f $destinationDirectory/$r4s_file'";
    $cmds->executeCommand( $msgs, $msgs->{cmd},
      'deleting missing r4s file from share' );
    $msgs->{cmd} = "ssh $server '/bin/rm -f $destinationDirectory/$r4s_ffile'";
    $cmds->executeCommand( $msgs, $msgs->{cmd},
      'deleteing missing r4s full file from share' );
    $this->_deleteR4sRows($pdb_id);
  }
  $tools->getSession->finalizeTransaction('PBD_OUT_FILE Mainteance Complete');
  $counter->print;
  ###
  ### Now copy the results over to the shared file system
  ###
  chdir( $this->getWorkspaceRoot );
  $this->createRemoteDirectory;
  $msgs->{cmd} = "scp $resultFilePattern $server:$destinationDirectory";
  $cmds->executeCommand( $msgs, $msgs->{cmd}, 'moving result files' );

}

################################################################################

1;

__END__

=head1 NAME

rate4site.pm

=head1 DESCRIPTION

This class defines the mechanism for moving rate4site data from run results.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::Move::rate4site(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
