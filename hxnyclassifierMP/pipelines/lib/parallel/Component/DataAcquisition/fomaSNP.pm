package parallel::Component::DataAcquisition::fomaSNP;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;
use FileHandle;

use util::Constants;
use util::Properties;

use parallel::Query;
use parallel::File::DataFiles;
use parallel::File::AccessionMap;

use base 'parallel::Component::DataAcquisition';

use fields qw(
  data_map
  exclude_groups
  exclude_hosts
  exclude_ncbi_accs
  groups
  host_mappings
  host_map
  min_num_seq
  pandemic
  pandemic_only
  pandemic_vals
  segment_pattern
  seqs_file_ord
  skip_groups
  skip_groups_only
  subtype_pattern
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### fomaSNP Specific Properties the Controller Configuration
###
sub EXCLUDEGROUPS_PROP   { return 'excludeGroups'; }
sub EXCLUDEHOSTS_PROP    { return 'excludeHosts'; }
sub EXCLUDENCBIACCS_PROP { return 'excludeNcbiAccs'; }
sub HOSTMAPPINGS_PROP    { return 'hostMappings'; }
sub HOST_PROP            { return 'host'; }
sub MINNUMSEQ_PROP       { return 'minNumSeq'; }
sub PANDEMIC_PROP        { return 'pandemic'; }
sub PANDEMICONLY_PROP    { return 'pandemicOnly'; }
sub SEGMENTPATTERN_PROP  { return 'segmentPattern'; }
sub SEGMENT_PROP         { return 'segment'; }
sub SEQSFILEORD_PROP     { return 'seqsFileOrd'; }
sub SKIPGROUPSONLY_PROP  { return 'skipGroupsOnly'; }
sub SKIPGROUPS_PROP      { return 'skipGroups'; }
sub SUBTYPEPATTERN_PROP  { return 'subtypePattern'; }
sub SUBTYPE_PROP         { return 'subtype'; }

sub FOMASNP_PROPERTIES {
  return (
    EXCLUDEGROUPS_PROP, EXCLUDEHOSTS_PROP,   EXCLUDENCBIACCS_PROP,
    HOSTMAPPINGS_PROP,  HOST_PROP,           MINNUMSEQ_PROP,
    PANDEMIC_PROP,      PANDEMICONLY_PROP,   SEGMENTPATTERN_PROP,
    SEGMENT_PROP,       SEQSFILEORD_PROP,    SKIPGROUPSONLY_PROP,
    SKIPGROUPS_PROP,    SUBTYPEPATTERN_PROP, SUBTYPE_PROP
  );
}
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
  return [
    MAXELEMENTS_PROP,     QUERYPARAMSUBS_PROP, QUERYPARAMS_PROP,
    QUERYRESULTSORD_PROP, QUERY_PROP,          QUERYPREDICATES_PROP,
  ];
}
###
### Group Information
###
sub GROUP_COLS { return ( 'subtype', 'host', 'segment' ); }
sub GROUP_SEPARATOR { return util::Constants::DOT; }
###
### Fasta Suffix
###
sub TXT_SUFFIX { return 'txt'; }
###
### Host Map File
###
sub HOST_MAP_FILE { return 'host.map.txt'; }

################################################################################
#
#                           Private Methods
#
################################################################################

sub _setList {
  my parallel::Component::DataAcquisition::fomaSNP $this = shift;
  my ( $file, $attr ) = @_;

  return if ( util::Constants::EMPTY_LINE($file) );
  my $fh = new FileHandle;
  $this->setErrorStatus(
    $this->ERR_CAT, 2,
    [ $attr, $file, ],
    !$fh->open( $file, '<' )
  );
  return if ( $this->getErrorStatus );

  while ( !$fh->eof ) {
    my $val = $fh->getline;
    chomp($val);
    next if ( util::Constants::EMPTY_LINE($val) || $val =~ /^#/ );
    $this->{$attr}->{ uc($val) } = util::Constants::EMPTY_STR;
  }
  $fh->close;

}

sub _setArray {
  my parallel::Component::DataAcquisition::fomaSNP $this = shift;
  my ( $vals, $attr ) = @_;

  return
    if ( util::Constants::EMPTY_LINE($vals)
    || ref($vals) ne $this->{tools}->serializer->ARRAY_TYPE );
  foreach my $val ( @{$vals} ) {
    $this->{$attr}->{$val} = util::Constants::EMPTY_STR;
  }
}

sub _goodNcbiGroup {
  my parallel::Component::DataAcquisition::fomaSNP $this = shift;
  my ($datum) = @_;

  my $excludeHosts    = $this->{exclude_hosts};
  my $excludeNcbiAccs = $this->{exclude_ncbi_accs};
  my $hostMappings    = $this->{host_mappings};
  my $segmentPattern  = $this->{segment_pattern};
  my $subtypePattern  = $this->{subtype_pattern};

  my $subtype = $datum->{subtype};
  my $host    = $datum->{host};
  my $segment = $datum->{segment};
  my $ncbiacc = $datum->{ncbiacc};

  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($host)
    || $this->{utils}->foundPattern( $host, $excludeHosts )
    || util::Constants::EMPTY_LINE($segment)
    || $segment !~ /$segmentPattern/
    || util::Constants::EMPTY_LINE($subtype)
    || $subtype !~ /$subtypePattern/
    || util::Constants::EMPTY_LINE($ncbiacc)
    || defined( $excludeNcbiAccs->{ uc($ncbiacc) } ) );
  ###
  ### Fix Host Name
  ### - Get rid of leading and trailing white-space
  ### - Initial cap name
  ### - Determine host mapping
  ###
  $host =~ s/^\s+//;
  $host =~ s/\s+$//;
  my $orig_host = $host;
  $host =~ s/\s/\_/g;
  $host = lc($host);
  my @host = split( util::Constants::EMPTY_STR, $host );
  $host[0] = uc( $host[0] );
  $host = join( util::Constants::EMPTY_STR, @host );
  $datum->{orig_host} = $host;

  foreach my $hostName ( keys %{$hostMappings} ) {
    my $like     = $hostMappings->{$hostName}->{like};
    my $patterns = $hostMappings->{$hostName}->{patterns};
    if ( ( $like && $this->{utils}->foundPattern( $host, $patterns ) )
      || ( !$like && !$this->{utils}->foundPattern( $host, $patterns ) ) )
    {
      $host = $hostName;
      last;
    }
  }
  $datum->{host} = $host;
  $this->{host_map}->addAccVal( $orig_host, $host );

  return util::Constants::TRUE;
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $properties, $controller, $utils, $error_mgr, $tools ) = @_;

  push( @{$properties}, FOMASNP_PROPERTIES );

  my parallel::Component::DataAcquisition::fomaSNP $this =
    $that->SUPER::new( $properties, 'fomaSNP', $controller, $utils, $error_mgr,
    $tools );

  $this->{data_map} = undef;
  $this->{groups}   = {};
  $this->{host_map} = undef;

  my $lproperties = $this->getLocalDataProperties( [] );

  $this->{min_num_seq}   = $lproperties->{&MINNUMSEQ_PROP};
  $this->{seqs_file_ord} = $lproperties->{&SEQSFILEORD_PROP};

  $this->{exclude_hosts}   = $lproperties->{&EXCLUDEHOSTS_PROP};
  $this->{host_mappings}   = $lproperties->{&HOSTMAPPINGS_PROP};
  $this->{segment_pattern} = $lproperties->{&SEGMENTPATTERN_PROP};
  $this->{subtype_pattern} = $lproperties->{&SUBTYPEPATTERN_PROP};

  $this->{pandemic}      = $lproperties->{&PANDEMIC_PROP};
  $this->{pandemic_only} = $lproperties->{&PANDEMICONLY_PROP};
  $this->{pandemic_vals} = {};
  $this->_setArray( $this->{pandemic}->{vals}, 'pandemic_vals' );

  $this->{exclude_groups}    = {};
  $this->{exclude_ncbi_accs} = {};
  $this->{skip_groups_only}  = $lproperties->{&SKIPGROUPSONLY_PROP};
  $this->{skip_groups}       = {};
  $this->_setList( $lproperties->{&EXCLUDEGROUPS_PROP},   'exclude_groups' );
  $this->_setList( $lproperties->{&EXCLUDENCBIACCS_PROP}, 'exclude_ncbi_accs' );
  $this->_setList( $lproperties->{&SKIPGROUPS_PROP},      'skip_groups' );

  return $this;
}

sub fileGroupTag {
  my parallel::Component::DataAcquisition::fomaSNP $this = shift;
  my ($datum) = @_;
  #######################
  ### Abstract Method ###
  #######################
}

sub groupTag {
  my parallel::Component::DataAcquisition::fomaSNP $this = shift;
  my ($datum) = @_;

  my $subtype = $datum->{subtype};
  my $host    = $datum->{host};
  my $segment = $datum->{segment};

  return join( util::Constants::UNDERSCORE, $subtype, $host, $segment );
}

sub addEntity {
  my parallel::Component::DataAcquisition::fomaSNP $this = shift;
  my ($datum) = @_;
  #######################
  ### Abstract Method ###
  #######################
}

sub initializeFomaSnpData {
  my parallel::Component::DataAcquisition::fomaSNP $this = shift;
  #######################
  ### Abstract Method ###
  #######################
}

sub acquire_data {
  my parallel::Component::DataAcquisition::fomaSNP $this = shift;

  $this->{groups} = {};

  return if ( !$this->getRun || $this->getErrorStatus );

  $this->initializeFomaSnpData;
  return if ( $this->getErrorStatus );

  my $query = new parallel::Query( $this, $this->{error_mgr}, $this->{tools} );
  my $properties = $this->getLocalDataProperties(QUERY_PROPERTIES);
  my @data       = $this->filterData( $query->getData($properties) );
  $this->setErrorStatus( $this->ERR_CAT, 12, [ $properties->{query} ],
    $query->getErrorStatus );
  return
    if ( $this->getErrorStatus );

  my $hostMapFile =
    join( util::Constants::SLASH, $this->getWorkspaceRoot, HOST_MAP_FILE );
  $this->{host_map} =
    new parallel::File::AccessionMap( $hostMapFile, $this->{error_mgr} );

  $this->{data_map} =
    new parallel::File::DataFiles( $this->getDataFiles, $this->{error_mgr} );
  ###
  ### Generate Data Procssing Chunks
  ###
  my $pandemicVals   = $this->{pandemic_vals};
  my $pandemicOnly   = $this->{pandemic_only};
  my $skipGroups     = $this->{skip_groups};
  my $skipGroupsOnly = $this->{skip_groups_only};
  my $excludeGroups  = $this->{exclude_groups};
  foreach my $datum (@data) {
    ###
    ### Must have a defined Group
    ### and
    ### NOT be an excluded NCBI accession
    ###
    next if ( !$this->_goodNcbiGroup($datum) );
    ###
    ### Must be a skip group if processing skip groups only
    ### or
    ### NOT an exclude group
    ###
    my $groupTag = $this->groupTag($datum);
    next
      if ( ( $skipGroupsOnly && !defined( $skipGroups->{ uc($groupTag) } ) )
      || defined( $excludeGroups->{ uc($groupTag) } ) );
    ###
    ### add entity if NOT pandemic only
    ###
    $this->addEntity($datum) if ( !$pandemicOnly );
    ###
    ### Add entity as a pandemic group if it is pandemic
    ###
    my $pandemic = $datum->{pandemic};
    next
      if (
         util::Constants::EMPTY_LINE($pandemic)
      || !defined( $pandemicVals->{$pandemic} )
      || $datum->{subtype} ne $this->{pandemic}->{subtype}

      );
    $datum->{host} = $this->{pandemic}->{host};
    $this->addEntity($datum);
  }
  ###
  ### Store group Data
  ###
  $this->{error_mgr}->printHeader("Storing Group Data");
  foreach my $fileGroupTag ( keys %{ $this->{groups} } ) {
    $this->{error_mgr}->printMsg("fileGroupTag = $fileGroupTag");
    my $groupData = $this->{groups}->{$fileGroupTag};
    $groupData->{properties}->storeFile( $groupData->{pfile} );
    foreach my $map ( 'hosts', 'strains', 'refseqs' ) {
      $this->setErrorStatus(
        $this->ERR_CAT, 1,
        [ "write $map map file", $groupData->{$map}->getMapFile, ],
        $groupData->{$map}->writeFile
      );
    }
    return if ( $this->getErrorStatus );
    ###
    ### The group must have a minimum number of sequences to run
    ###
    my $numSeq = $groupData->{properties}->getProperty('count');
    next if ( $numSeq >= $this->{min_num_seq} );
    $this->{error_mgr}
      ->printMsg("  NOT RECORDING GROUP--too few sequences ($numSeq)");
    $this->{data_map}->deleteDataFile($fileGroupTag);
  }
  ###
  ### now generate data files
  ###
  $this->setErrorStatus(
    $this->ERR_CAT, 1,
    [ 'dataFiles', $this->getDataFiles, ],
    $this->{data_map}->writeFile
  );
  ###
  ### now generate host map
  ###
  $this->setErrorStatus(
    $this->ERR_CAT, 1,
    [ 'hostMap', $hostMapFile, ],
    $this->{host_map}->writeFile
  );
}

sub getGroup {
  my parallel::Component::DataAcquisition::fomaSNP $this = shift;
  my ( $datum, $seqLen, $alignSeqLen ) = @_;

  my $cmds         = $this->{tools}->cmds;
  my $dataMap      = $this->{data_map};
  my $fileGroupTag = $this->fileGroupTag($datum);
  my $groups       = $this->{groups};

  if ( util::Constants::EMPTY_LINE( $dataMap->getDataFile($fileGroupTag) ) ) {
    $this->{error_mgr}->printMsg("Generating group ($fileGroupTag)");
    my $groupDir =
      join( util::Constants::SLASH, $this->getWorkspaceRoot, $fileGroupTag );
    my $propertiesFile = join( util::Constants::SLASH,
      $groupDir, join( util::Constants::DOT, $fileGroupTag, 'properties' ) );
    my $seqsFile = join( util::Constants::SLASH,
      $groupDir, join( util::Constants::DOT, $fileGroupTag, 'seqs' ) );
    my $strainsFile = join( util::Constants::SLASH,
      $groupDir, join( util::Constants::DOT, $fileGroupTag, 'strains' ) );
    my $refsFile = join( util::Constants::SLASH,
      $groupDir, join( util::Constants::DOT, $fileGroupTag, 'refseqs' ) );
    my $hostsFile = join( util::Constants::SLASH,
      $groupDir, join( util::Constants::DOT, $fileGroupTag, 'hosts' ) );
    $cmds->createDirectory( $groupDir, 'create group directory',
      util::Constants::TRUE );
    $dataMap->addDataFile( $fileGroupTag, $groupDir );
    $this->{groups}->{$fileGroupTag} = {
      group_tag  => $fileGroupTag,
      dir        => $groupDir,
      pfile      => $propertiesFile,
      properties => new util::Properties,
      seqs_file  => $seqsFile,
      strains =>
        new parallel::File::AccessionMap( $strainsFile, $this->{error_mgr} ),
      refseqs =>
        new parallel::File::AccessionMap( $refsFile, $this->{error_mgr} ),
      hosts =>
        new parallel::File::AccessionMap( $hostsFile, $this->{error_mgr} ),
    };
    my $properties = $this->{groups}->{$fileGroupTag}->{properties};
    $properties->setProperty( 'file_group_tag', $fileGroupTag );
    $properties->setProperty( 'group_tag',      $this->groupTag($datum) );
    $properties->setProperty( 'host',           $datum->{host} );
    $properties->setProperty( 'segment',        $datum->{segment} );
    $properties->setProperty( 'subtype',        $datum->{subtype} );

    $properties->setProperty( 'count',       0 );
    $properties->setProperty( 'offset',      100000 );
    $properties->setProperty( 'trailing',    0 );
    $properties->setProperty( 'max_seq_len', $seqLen );
    $properties->setProperty( 'align_len',   $alignSeqLen )
      if ( !util::Constants::EMPTY_LINE($alignSeqLen) );
    $properties->setProperty( 'realign', util::Constants::FALSE );
  }
  return $this->{groups}->{$fileGroupTag};
}

sub addSeqData {
  my parallel::Component::DataAcquisition::fomaSNP $this = shift;
  my ( $groupData, $datum ) = @_;

  my $file = $groupData->{seqs_file};
  my $fh   = new FileHandle;
  $this->setErrorStatus(
    $this->ERR_CAT, 2,
    [ $groupData->{group_tag}, $file, ],
    !$fh->open( $file, '>>' )
  );
  return if ( $this->getErrorStatus );
  my @data = ();

  foreach my $col ( @{ $this->{seqs_file_ord} } ) {
    push( @data, $datum->{$col} );
  }
  $fh->print( join( util::Constants::TAB, @data ) . util::Constants::NEWLINE );
  $fh->close;
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

=head2 B<new parallel::Component::DataAcquisition::fomaSNP(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
