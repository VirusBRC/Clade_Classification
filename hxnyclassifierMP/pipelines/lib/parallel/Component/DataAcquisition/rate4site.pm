package parallel::Component::DataAcquisition::rate4site;
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

use util::Constants;

use parallel::Query;

use base 'parallel::Component::DataAcquisition';

################################################################################
#
#			            Static Class Constants
#
################################################################################
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
### Rate4Site Specific Properties the Controller Configuration
###
sub ORGANISMNAMES_PROP         { return 'organismNames'; }
sub PDBFILEPATTERN_PROP        { return 'pdbFilePattern'; }
sub PDBFILERECORDPATTERNS_PROP { return 'pdbFileRecordPatterns'; }
sub PDBFILEROOT_PROP           { return 'pdbFileRoot'; }

sub R4S_PROPERTIES {
  return [
    PDBFILEPATTERN_PROP,        PDBFILEROOT_PROP,
    PDBFILERECORDPATTERNS_PROP, ORGANISMNAMES_PROP,
  ];
}
###
### Query Specific Properties from its Configuration
###
sub MAXELEMENTS_PROP     { return 'maxElements'; }
sub QUERYPARAMSUBS_PROP  { return 'queryParamSubs'; }
sub QUERYPARAMS_PROP     { return 'queryParams'; }
sub QUERYRESULTSORD_PROP { return 'queryResultsOrd'; }
sub QUERY_PROP           { return 'query'; }

sub QUERY_PROPERTIES {
  return [
    MAXELEMENTS_PROP,     QUERYPARAMSUBS_PROP, QUERYPARAMS_PROP,
    QUERYRESULTSORD_PROP, QUERY_PROP,
  ];
}
###
### Group Information
###
sub GROUP_COLS { return ( 'orgName', 'subType', 'host', 'segmentName' ); }
sub GROUP_SEPARATOR { return util::Constants::DOT; }
###
### Fasta Suffix
###
sub TXT_SUFFIX { return 'txt'; }

################################################################################
#
#                           Private Methods
#
################################################################################

my @_FILES_ = ();

sub _filesWanted {
  my parallel::Component::DataAcquisition::rate4site $this = shift;

  my $file_pattern = $this->getProperties->{&PDBFILEPATTERN_PROP};

  return sub {
    my ( $dev, $ino, $mode, $nlink, $uid, $gid );

    ( ( $dev, $ino, $mode, $nlink, $uid, $gid ) = lstat($_) )
      && -f _
      && /^$file_pattern\z/s
      && push( @_FILES_, $FIND_NAME );
    }
}

sub _getPdbId {
  my parallel::Component::DataAcquisition::rate4site $this = shift;
  my ($pdb_file) = @_;

  my $fh = new FileHandle;
  $this->setErrorStatus(
    $this->ERR_CAT, 1,
    [ 'pdb file', $pdb_file ],
    !$fh->open( $pdb_file, '<' )
  );
  return undef if ( $this->getErrorStatus );
  my $file = util::Constants::EMPTY_STR;
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    $file .= $line;
  }
  $fh->close;
  my $struct =
    $this->{utils}->getAllPatternInfo( $file,
    $this->getProperties->{&PDBFILERECORDPATTERNS_PROP} );
  my $pdb_id = $struct->{pdb_id};
  $this->setErrorStatus( $this->ERR_CAT, 9, [$pdb_file],
    util::Constants::EMPTY_LINE($pdb_id) );
  return $pdb_id;

}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::DataAcquisition::rate4site $this =
    $that->SUPER::new( R4S_PROPERTIES, 'rate4site', $controller, $utils,
    $error_mgr, $tools );

  return $this;
}

sub acquire_data {
  my parallel::Component::DataAcquisition::rate4site $this = shift;

  return util::Constants::FALSE if ( !$this->getRun );
  ###
  ### Determine the PDB ID grouping based on
  ### (organism, subtype, host and segment)
  ###
  my $query = new parallel::Query( $this, $this->{error_mgr}, $this->{tools} );
  my $properties = $this->getLocalDataProperties(QUERY_PROPERTIES);
  my @data       = $this->filterData( $query->getData($properties) );
  return if ( $this->getErrorStatus );
  my $pdbData = {};
  foreach my $struct (@data) {
    my @group = ();
    foreach my $col (GROUP_COLS) { push( @group, $struct->{$col} ); }
    my $group = join( GROUP_SEPARATOR, @group );
    $group =~ s/ /_/g;
    if ( !defined( $pdbData->{ $struct->{pdbId} } ) ) {
      $pdbData->{ $struct->{pdbId} } = {};
    }
    $pdbData->{ $struct->{pdbId} }->{ $struct->{spAcc} } = $group;
  }
  ###
  ### Now determine those pdb IDs that have two accessions
  ### and group them differently
  ###
  my $pdbMap = {};
  foreach my $pdbId ( keys %{$pdbData} ) {
    my $data  = $pdbData->{$pdbId};
    my @accs  = keys %{$data};
    my $group = undef;
    if ( scalar @accs == 1 ) { $group = $data->{ $accs[0] }; }
    else {
      my $groups = {};
      foreach my $acc (@accs) {
        $groups->{ $data->{$acc} } = util::Constants::EMPTY_STR;
      }
      my @groups = sort keys %{$groups};
      if ( scalar @groups == 1 ) { $group = $groups[0]; }
      else {
        $group = join( GROUP_SEPARATOR, @groups );
      }
    }
    $pdbMap->{$pdbId} = $group;
  }
  ###
  ### Determine PDB ID to file map
  ###
  my $pdbFileRoot = $this->getProperties->{&PDBFILEROOT_PROP};
  $this->setErrorStatus(
    $this->ERR_CAT, 1,
    [ 'pdb files', $pdbFileRoot, ],
    !-e $pdbFileRoot || !-d $pdbFileRoot || !chdir($pdbFileRoot)
  );
  return if ( $this->getErrorStatus );
  @_FILES_ = ();
  File::Find::find( { wanted => $this->_filesWanted }, util::Constants::DOT );
  my $groupMap = {};
  foreach my $pdb_file (@_FILES_) {
    $pdb_file =~ s/^\.\///;
    $pdb_file = join( util::Constants::SLASH, $pdbFileRoot, $pdb_file );
    my $pdb_filename = basename($pdb_file);
    my $pdb_id       = $this->_getPdbId($pdb_file);
    return if ( $this->getErrorStatus );
    next   if ( !defined( $pdbMap->{$pdb_id} ) );
    my $group = $pdbMap->{$pdb_id};
    if ( !defined( $groupMap->{$group} ) ) {
      $groupMap->{$group} = {};
    }
    $groupMap->{$group}->{$pdb_filename} = $pdb_file;
  }
  ###
  ### Now determine PDB ID groups based on database groups
  ### and existing pdb files
  ###
  my $dataFiles = new parallel::File::DataFiles( $this->getDataFiles, $this->{error_mgr} );
  foreach my $group ( sort keys %{$groupMap} ) {
    my $groupFiles = $groupMap->{$group};
    my $dataFile   = join( util::Constants::SLASH,
      $this->getWorkspaceRoot,
      join( util::Constants::DOT, $group, TXT_SUFFIX ) );
    $dataFiles->addDataFile( $group, $dataFile );
    my $fh = new FileHandle;
    $this->setErrorStatus(
      $this->ERR_CAT, 1,
      [ 'data file', $dataFile ],
      !$fh->open( $dataFile, '>' )
    );
    return if ( $this->getErrorStatus );
    $fh->autoflush(util::Constants::TRUE);
    foreach my $pdb ( sort keys %{$groupFiles} ) {
      $fh->print(
        join( util::Constants::TAB, $pdb, $groupFiles->{$pdb} )
          . util::Constants::NEWLINE );
    }
    $fh->close;
  }
  ###
  ### now generate data files
  ###
  $this->setErrorStatus( $this->ERR_CAT, 1,
    [ 'dataFiles', $this->getDataFiles, ],
    $dataFiles->writeFile );
}

################################################################################

1;

__END__

=head1 NAME

rate4site.pm

=head1 DESCRIPTION

This class defines the pdb data group acquisition component

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::DataAcquisition::rate4site(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
