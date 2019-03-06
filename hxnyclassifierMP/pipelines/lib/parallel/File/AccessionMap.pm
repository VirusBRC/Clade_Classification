package parallel::File::AccessionMap;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;

use fields qw(
  error_mgr
  map_data
  map_file
);

################################################################################
#
#			            Public Methods
#
################################################################################

sub new {
  my parallel::File::AccessionMap $this = shift;
  my ( $map_file, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr} = $error_mgr;
  $this->{map_data}  = {};
  $this->{map_file}  = $map_file;

  return $this;
}

sub getMapFile {
  my parallel::File::AccessionMap $this = shift;
  return $this->{map_file};
}

sub readFile {
  my parallel::File::AccessionMap $this = shift;

  $this->{map_data} = {};
  my $mapFile = $this->getMapFile;
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($mapFile) || !-e $mapFile || -z $mapFile );
  my $fh = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $mapFile, '<' ) );
  my $mapData = $this->{map_data};
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    my ( $acc, $val ) = split( /\t/, $line );
    $mapData->{$acc} = $val;
  }

  $fh->close;
  return util::Constants::FALSE;
}

sub writeFile {
  my parallel::File::AccessionMap $this = shift;

  my $mapFile = $this->getMapFile;
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($mapFile) );
  my $fh = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $mapFile, '>' ) );
  $fh->autoflush(util::Constants::TRUE);
  my $mapData = $this->{map_data};
  foreach my $acc ( sort keys %{$mapData} ) {
    $fh->print(
      join( util::Constants::TAB, $acc, $mapData->{$acc} )
        . util::Constants::NEWLINE );
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub addAccVal {
  my parallel::File::AccessionMap $this = shift;
  my ( $acc, $val ) = @_;

  return if ( util::Constants::EMPTY_LINE($acc) );
  $this->{map_data}->{$acc} = $val;
}

sub getVal {
  my parallel::File::AccessionMap $this = shift;
  my ($acc) = @_;

  return $this->{map_data}->{$acc};
}

sub accDefined {
  my parallel::File::AccessionMap $this = shift;
  my ($acc) = @_;

  my $val = $this->{map_data}->{$acc}; 
  return util::Constants::EMPTY_LINE($val)
      ? util::Constants::FALSE : util::Constants::TRUE;
}

sub getAccs {
  my parallel::File::AccessionMap $this = shift;

  return sort keys %{ $this->{map_data} };
}

################################################################################

1;

__END__

=head1 NAME

AccessionMap.pm

=head1 DESCRIPTION

This class is the container NCBI accession to value map.

=head1 METHODS


=cut
