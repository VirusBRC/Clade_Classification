package parallel::File::OrthologGroup;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use fields qw(
  error_mgr
  gi_map
  groups
  groups_file
  organism_map
);

################################################################################
#
#			            Constants Methods
#
################################################################################
###
### Struct
###
sub GROUP_ID_COL  { return 'group_id'; }
sub MEMBERS_COL   { return 'members'; }
sub GIS_COL       { return 'gis'; }
sub ORGANISMS_COL { return 'organisms'; }

sub GI_COL       { return 'gi'; }
sub ORGANISM_COL { return 'organism'; }

################################################################################
#
#			            Private Methods
#
################################################################################

sub _getGroup {
  my parallel::File::OrthologGroup $this = shift;
  my ($group_id) = @_;

  my $groups = $this->{groups};
  return $groups->{$group_id} if ( defined( $groups->{$group_id} ) );
  my $group = {
    &GROUP_ID_COL  => $group_id,
    &MEMBERS_COL   => [],
    &GIS_COL       => {},
    &ORGANISMS_COL => {},
  };
  $groups->{$group_id} = $group;
  return $group;
}

sub _getStruct {
  my parallel::File::OrthologGroup $this = shift;
  my ( $organism, $gi ) = @_;
  my $struct = {
    &GI_COL       => $gi,
    &ORGANISM_COL => $organism,
  };
  return $struct;
}

sub _generateGroup {
  my parallel::File::OrthologGroup $this = shift;
  my ($line) = @_;

  my ( $group_id, $items_str ) = split( /:\s+/, $line );
  my $group = $this->_getGroup($group_id);
  my @items = split( /\s+/, $items_str );
  foreach my $item (@items) {
    my ( $organism, $gi ) = split( /\|/, $item );
    my $struct = $this->_getStruct( $organism, $gi );
    push( @{ $group->{&MEMBERS_COL} }, $struct );
    $group->{&GIS_COL}->{$gi} = $struct;
    my $organisms = $group->{&ORGANISMS_COL};
    if ( !defined( $organisms->{$organism} ) ) {
      $organisms->{$organism} = [];
    }
    push( @{ $organisms->{$organism} }, $struct );
  }
  return $group;
}

################################################################################
#
#			            Public Methods
#
################################################################################

sub new {
  my parallel::File::OrthologGroup $this = shift;
  my ( $groups_file, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr}    = $error_mgr;
  $this->{gi_map}       = {};
  $this->{groups_file}  = $groups_file;
  $this->{groups}       = {};
  $this->{organism_map} = {};

  return $this;
}

sub getGroupsFile {
  my parallel::File::OrthologGroup $this = shift;
  return $this->{groups_file};
}

sub readFile {
  my parallel::File::OrthologGroup $this = shift;

  $this->{gi_map}       = {};
  $this->{groups}       = {};
  $this->{organism_map} = {};

  my $gi_map       = $this->{gi_map};
  my $groups       = $this->{groups};
  my $organism_map = $this->{organism_map};

  my $groupsFile = $this->getGroupsFile;
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($groupsFile)
    || !-e $groupsFile
    || -z $groupsFile );
  my $fh = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $groupsFile, '<' ) );

  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    next if ( util::Constants::EMPTY_LINE($line) );
    my $group    = $this->_generateGroup($line);
    my $group_id = $group->{&GROUP_ID_COL};
    foreach my $gi ( keys %{ $group->{&GIS_COL} } ) {
      $gi_map->{$gi} = $group->{&GIS_COL}->{$gi};
    }
    foreach my $organism ( keys %{ $group->{&ORGANISMS_COL} } ) {
      if ( !defined( $organism_map->{$organism} ) ) {
        $organism_map->{$organism} = [];
      }
      push(
        @{ $organism_map->{$organism} },
        @{ $group->{&ORGANISMS_COL}->{$organism} }
      );
    }
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub writeFile {
  my parallel::File::OrthologGroup $this = shift;

  my $groupsFile = $this->getGroupsFile;
  my $groups     = $this->{groups};
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($groupsFile) );
  my $fh = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $groupsFile, '>' ) );
  $fh->autoflush(util::Constants::TRUE);
  foreach my $group_id ( sort keys %{$groups} ) {
    my $group = $groups->{$group_id};
    my @items = ();
    foreach my $struct ( @{ $group->{&MEMBERS_COL} } ) {
      push(
        @items,
        join( util::Constants::PIPE,
          $struct->{&ORGANISM_COL},
          $struct->{&GI_COL}
        )
      );
    }
    my $line = join( util::Constants::COLON . util::Constants::SPACE,
      $group_id, join( util::Constants::SPACE, @items ) );
    $fh->print("$line\n");
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub writeLinearFile {
  my parallel::File::OrthologGroup $this = shift;
  my ($file) = @_;

  my $groupsFile = undef;
  if ( util::Constants::EMPTY_LINE($file) ) {
    $groupsFile = $this->getGroupsFile;
  }
  else { $groupsFile = getPath($file); }

  my $groups = $this->{groups};
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($groupsFile) );
  my $fh = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $groupsFile, '>' ) );
  $fh->autoflush(util::Constants::TRUE);
  foreach my $group_id ( sort keys %{$groups} ) {
    my $group = $groups->{$group_id};
    foreach my $struct ( @{ $group->{&MEMBERS_COL} } ) {
      $fh->print(
        join( util::Constants::TAB,
          $group_id, $struct->{&ORGANISM_COL},
          $struct->{&GI_COL}
          )
          . util::Constants::NEWLINE
      );
    }
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub addItem {
  my parallel::File::OrthologGroup $this = shift;
  my ( $group_id, $organism, $gi ) = @_;

  my $gi_map       = $this->{gi_map};
  my $groups       = $this->{groups};
  my $organism_map = $this->{organism_map};

  my $group = $this->_getGroup($group_id);
  my $struct = $this->_getStruct( $organism, $gi );
  push( @{ $group->{&MEMBERS_COL} }, $struct );
  $group->{&GIS_COL}->{$gi} = $struct;
  my $organisms = $group->{&ORGANISMS_COL};
  if ( !defined( $organisms->{$organism} ) ) {
    $organisms->{$organism} = [];
  }
  push( @{ $organisms->{$organism} }, $struct );

  $gi_map->{$gi} = $struct;
  if ( !defined( $organism_map->{$organism} ) ) {
    $organism_map->{$organism} = [];
  }
  push(
    @{ $organism_map->{$organism} },
    @{ $group->{&ORGANISMS_COL}->{$organism} }
  );
}

sub getGroupIds {
  my parallel::File::OrthologGroup $this = shift;

  return sort keys %{ $this->{groups} };
}

sub getGis {
  my parallel::File::OrthologGroup $this = shift;

  return sort keys %{ $this->{gi_map} };
}

sub getOrganisms {
  my parallel::File::OrthologGroup $this = shift;

  return sort keys %{ $this->{organism_map} };
}

sub getGroupData {
  my parallel::File::OrthologGroup $this = shift;
  my ($group_id) = @_;

  my $group = $this->{groups}->{$group_id};
  return () if ( !defined($group) );
  return return @{ $group->{&MEMBERS_COL} };
}

sub getGiData {
  my parallel::File::OrthologGroup $this = shift;
  my ($gi) = @_;

  my $gi_map = $this->{gi_map};
  return $gi_map->{$gi};
}

sub getOrganismData {
  my parallel::File::OrthologGroup $this = shift;
  my ($organism) = @_;

  my $data = $this->{organism_map}->{$organism};
  return () if ( !defined($data) );
  return return @{$data};
}

################################################################################

1;

__END__

=head1 NAME

OrthologGroup.pm

=head1 DESCRIPTION

This class is the container for otholog group data.

=head1 METHODS


=cut
