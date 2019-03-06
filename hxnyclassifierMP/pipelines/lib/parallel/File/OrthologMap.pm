package parallel::File::OrthologMap;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;
use util::Table;

use fields qw(
  accs
  cols_ord
  error_mgr
  gis
  map_data
  map_file
);

################################################################################
#
#			            Constants Methods
#
################################################################################
###
### Columns
###
sub ACCESSION_COL   { return 'ACCESSION'; }
sub ACC_VERSION_COL { return 'ACC_VERSION' }
sub GI_COL          { return 'GI' }
sub ORGANISM_COL    { return 'ORGANISM'; }
sub SWISSPROT_COL   { return 'SWISSPROT'; }
sub STATUS_COL      { return 'STATUS'; }

sub COLS_ORD {
  return [
    ACCESSION_COL, ACC_VERSION_COL, GI_COL,
    ORGANISM_COL,  SWISSPROT_COL,   STATUS_COL,
  ];
}
###
### Status Values
###
sub READ_STATUS      { return 'read'; }
sub UNCHANGED_STATUS { return 'unchanged'; }
sub CHANGED_STATUS   { return 'changed'; }
sub UNKNOWN_STATUS   { return 'unknown'; }
sub OBSOLETE_STATUS  { return 'obsolete'; }
sub NEW_STATUS       { return 'new'; }

################################################################################
#
#			            Private Methods
#
################################################################################

sub _getStruct {
  my parallel::File::OrthologMap $this = shift;
  my ($line) = @_;

  my $cols_ord = $this->{cols_ord};

  my @row = split( /\t/, $line, 6 );
  my $struct = {};
  foreach my $index ( 0 .. $#{$cols_ord} ) {
    $struct->{ $cols_ord->[$index] } = $row[$index];
  }
  if ( util::Constants::EMPTY_LINE( $struct->{&STATUS_COL} ) ) {
    $struct->{&STATUS_COL} = UNKNOWN_STATUS;
  }
  return $struct;
}

################################################################################
#
#			            Public Methods
#
################################################################################

sub new {
  my parallel::File::OrthologMap $this = shift;
  my ( $map_file, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{accs}      = {};
  $this->{cols_ord}  = COLS_ORD;
  $this->{error_mgr} = $error_mgr;
  $this->{gis}       = {};
  $this->{map_data}  = {};
  $this->{map_file}  = $map_file;

  return $this;
}

sub getMapFile {
  my parallel::File::OrthologMap $this = shift;
  return $this->{map_file};
}

sub readFile {
  my parallel::File::OrthologMap $this = shift;

  $this->{map_data} = {};
  $this->{accs}     = {};
  $this->{gis}      = {};
  my $mapFile = $this->getMapFile;
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($mapFile) || !-e $mapFile || -z $mapFile );
  my $fh = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $mapFile, '<' ) );
  my $header  = ACCESSION_COL;
  my $mapData = $this->{map_data};

  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    next if ( util::Constants::EMPTY_LINE($line)
      || $line =~ /^$header/ );
    my $struct = $this->_getStruct($line);
    my $acc    = $struct->{&ACCESSION_COL};
    my $gi     = $struct->{&GI_COL};
    my $key    = join( util::Constants::PIPE, $acc, $gi );
    next if ( util::Constants::EMPTY_LINE($gi) );
    $mapData->{$key} = $struct;
    $this->{gis}->{$gi} = $struct;

    if ( !util::Constants::EMPTY_LINE($acc) ) {
      $this->{accs}->{$acc} = $struct;
    }
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub writeFile {
  my parallel::File::OrthologMap $this = shift;

  my $mapFile = $this->getMapFile;
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($mapFile) );
  my %cols = ();
  foreach my $col ( @{ $this->{cols_ord} } ) { $cols{$col} = $col; }
  eval {
    my $table = new util::Table( $this->{error_mgr}, %cols );
    $table->setColumnOrder( @{ $this->{cols_ord} } );
    $table->setData( values %{ $this->{map_data} } );
    $table->generateTabFile($mapFile);
  };
  my $status = $@;
  $status =
    ( defined($status) && $status )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  return $status;
}

sub addSequence {
  my parallel::File::OrthologMap $this = shift;
  my ( $acc_version, $gi, $organism, $swissprot, $status ) = @_;
  ###
  ### 1.  gi must always be defined
  ### 2.  accession (if defined) may not be unique
  ### 3.  gi is unique
  ###
  return if ( util::Constants::EMPTY_LINE($gi) );
  my $acc = util::Constants::EMPTY_STR;
  if ( !util::Constants::EMPTY_LINE($acc_version) ) {
    $acc = $acc_version;
    $acc =~ s/\.\d+$//;
  }
  my $data = $this->{gis}->{$gi};
  return if ( defined($data) );
  ###
  ### Add the data
  ###
  my $struct = {
    &ACCESSION_COL   => $acc,
    &ACC_VERSION_COL => $acc_version,
    &GI_COL          => $gi,
    &ORGANISM_COL    => $organism,
    &SWISSPROT_COL   => $swissprot,
    &STATUS_COL      => $status,
  };
  my $key = join( util::Constants::PIPE, $acc, $gi );
  $this->{map_data}->{$key} = $struct;
  $this->{gis}->{$gi}       = $struct;
  if ( !util::Constants::EMPTY_LINE($acc) ) { $this->{accs}->{$acc} = $struct; }
}

sub getIds {
  my parallel::File::OrthologMap $this = shift;

  return sort keys %{ $this->{map_data} };
}

sub getAccs {
  my parallel::File::OrthologMap $this = shift;

  return sort keys %{ $this->{accs} };
}

sub getGis {
  my parallel::File::OrthologMap $this = shift;

  return sort keys %{ $this->{gis} };
}

sub getDataById {
  my parallel::File::OrthologMap $this = shift;
  my ($id) = @_;

  return undef if ( util::Constants::EMPTY_LINE($id) );
  return $this->{map_data}->{$id};
}

sub getDataByAcc {
  my parallel::File::OrthologMap $this = shift;
  my ($acc) = @_;

  return undef if ( util::Constants::EMPTY_LINE($acc) );
  $acc =~ s/\.\d+$//;
  return $this->{accs}->{$acc};
}

sub getDataByGi {
  my parallel::File::OrthologMap $this = shift;
  my ($gi) = @_;

  return $this->{gis}->{$gi};
}

################################################################################

1;

__END__

=head1 NAME

OrthologMap.pm

=head1 DESCRIPTION

This class is the container ortholog sequence map information.

=head1 METHODS


=cut
