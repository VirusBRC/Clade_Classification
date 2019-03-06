package parallel::File::DataDups;
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
  data_dups_file
  data_dups
  error_mgr
  id_type
);

################################################################################
#
#			            Public Methods
#
################################################################################

sub new {
  my parallel::File::DataDups $this = shift;
  my ( $data_dups_file, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{data_dups_file} = $data_dups_file;
  $this->{data_dups}      = {};
  $this->{error_mgr}      = $error_mgr;
  $this->{id_type}        = 'NUMERIC';

  return $this;
}

sub setChar {
  my parallel::File::DataDups $this = shift;
  $this->{id_type} = 'CHAR';
}

sub readFile {
  my parallel::File::DataDups $this = shift;

  $this->{data_dups} = {};
  my $dataDupsFile = $this->{data_dups_file};
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($dataDupsFile) );
  my $dataDups = $this->{data_dups};
  my $fh       = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $dataDupsFile, '<' ) );
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    my @ids = split( /\t/, $line );
    my $id = shift(@ids);
    $dataDups->{$id} = {};
    foreach my $dup_id (@ids) {
      $dataDups->{$id}->{$dup_id} = util::Constants::EMPTY_STR;
    }
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub _numericSort { $a <=> $b; }

sub writeFile {
  my parallel::File::DataDups $this = shift;

  my $dataDups     = $this->{data_dups};
  my $dataDupsFile = $this->{data_dups_file};
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($dataDupsFile) );
  my $fh = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $dataDupsFile, '>' ) );
  foreach my $id ( keys %{ $this->{data_dups} } ) {
    my @ids = keys %{ $dataDups->{$id} };
    if ( $this->{id_type} eq 'CHAR' ) { @ids = sort @ids; }
    else { @ids = sort parallel::File::DataDups::_numericSort @ids; }
    unshift( @ids, $id );
    $fh->print( join( util::Constants::TAB, @ids ) . "\n" );
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub createDataDup {
  my parallel::File::DataDups $this = shift;
  my ($id) = @_;

  my $dataDups = $this->{data_dups};
  my $data     = $dataDups->{$id};
  return if ( defined($data) );
  $this->{data_dups}->{$id} = {};
}

sub addDataDup {
  my parallel::File::DataDups $this = shift;
  my ( $id, $dup_id ) = @_;

  my $dataDups = $this->{data_dups};
  my $data     = $dataDups->{$id};
  return if ( !defined($data) );
  $this->{data_dups}->{$id}->{$dup_id} = util::Constants::EMPTY_STR;
}

sub idInDataDups {
  my parallel::File::DataDups $this = shift;
  my ($id) = @_;

  my $dataDups = $this->{data_dups};
  return ( defined( $dataDups->{$id} ) )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

sub getIds {
  my parallel::File::DataDups $this = shift;

  return keys %{ $this->{data_dups} };
}

sub getDupIds {
  my parallel::File::DataDups $this = shift;
  my ($id) = @_;

  my @ids     = ();
  my $dup_ids = $this->{data_dups}->{$id};
  return @ids if ( !defined($dup_ids) );
  return keys %{$dup_ids};

}

################################################################################

1;

__END__

=head1 NAME

DataDups.pm

=head1 DESCRIPTION

This class is the container for data duplicates.

=head1 METHODS


=cut
