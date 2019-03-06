package parallel::File::DataFiles;
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
  data_file
  data_files
  error_mgr
);

################################################################################
#
#			            Public Methods
#
################################################################################

sub new {
  my parallel::File::DataFiles $this = shift;
  my ( $data_file, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{data_file}  = $data_file;
  $this->{data_files} = {};
  $this->{error_mgr}  = $error_mgr;

  return $this;
}

sub getDataFilesFile {
  my parallel::File::DataFiles $this = shift;
  return $this->{data_file};
}

sub readFile {
  my parallel::File::DataFiles $this = shift;

  $this->{data_files} = {};
  my $dataFile = $this->{data_file};
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($dataFile) );
  my $dataFiles = $this->{data_files};
  my $fh        = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $dataFile, '<' ) );
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    my ( $prefix, $file ) = split( /\t/, $line );
    $dataFiles->{$prefix} = $file;
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub writeFile {
  my parallel::File::DataFiles $this = shift;

  my $dataFiles = $this->{data_files};
  my $dataFile  = $this->{data_file};
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($dataFile) );
  my $fh = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $dataFile, '>' ) );
  foreach my $prefix ( sort keys %{ $this->{data_files} } ) {
    $fh->print(
      join( util::Constants::TAB, $prefix, $dataFiles->{$prefix} ) . "\n" );
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub addDataFile {
  my parallel::File::DataFiles $this = shift;
  my ( $prefix, $file ) = @_;

  my $dfile = $this->{data_files}->{$prefix};
  return if ( defined($dfile) );
  $this->{data_files}->{$prefix} = $file;
}

sub deleteDataFile {
  my parallel::File::DataFiles $this = shift;
  my ($prefix) = @_;

  my $data_files = $this->{data_files};
  return if ( !defined( $data_files->{$prefix} ) );
  delete( $data_files->{$prefix} );
}

sub getPrefixes {
  my parallel::File::DataFiles $this = shift;

  return sort keys %{ $this->{data_files} };
}

sub getNumPrefixes {
  my parallel::File::DataFiles $this = shift;

  my @prefixes = $this->getPrefixes;
  return scalar @prefixes;
}

sub getLastPrefixIndex {
  my parallel::File::DataFiles $this = shift;

  my @prefixes = $this->getPrefixes;
  return $#prefixes;
}

sub getNthPrefix {
  my parallel::File::DataFiles $this = shift;
  my ($index) = @_;

  my @prefixes = $this->getPrefixes;
  return undef if ( $index < 0 || $index > $#prefixes );
  return $prefixes[$index];
}

sub getDataFile {
  my parallel::File::DataFiles $this = shift;
  my ($prefix) = @_;

  return $this->{data_files}->{$prefix};
}

################################################################################

1;

__END__

=head1 NAME

DataFiles.pm

=head1 DESCRIPTION

This class is the container for data files generated.

=head1 METHODS


=cut
