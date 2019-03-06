package parallel::File::FamilyNames;
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
  fn_file
  fn_data
  error_mgr
);

################################################################################
#
#			            Public Methods
#
################################################################################

sub new {
  my parallel::File::FamilyNames $this = shift;
  my ( $fn_file, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr} = $error_mgr;
  $this->{fn_data}   = {};
  $this->{fn_file}   = $fn_file;

  return $this;
}

sub getFamilyNamesFile {
  my parallel::File::FamilyNames $this = shift;
  return $this->{fn_file};
}

sub readFile {
  my parallel::File::FamilyNames $this = shift;

  $this->{fn_data} = {};
  my $fnFile = $this->{fn_file};
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($fnFile) || !-e $fnFile || -z $fnFile );
  my $fnData = $this->{fn_data};
  my $fh     = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $fnFile, '<' ) );
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    my ( $id, $fn ) = split( /\t/, $line );
    $fnData->{$id} = $fn;
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub writeFile {
  my parallel::File::FamilyNames $this = shift;

  my $fnData = $this->{fn_data};
  my $fnFile = $this->{fn_file};
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($fnFile) );
  my $fh = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $fnFile, '>' ) );
  foreach my $id ( sort keys %{ $this->{fn_data} } ) {
    $fh->print( join( util::Constants::TAB, $id, $fnData->{$id} ) . "\n" );
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub addIdFamilyName {
  my parallel::File::FamilyNames $this = shift;
  my ( $id, $fn ) = @_;

  my $cfn = $this->{fn_data}->{$id};
  return if ( defined($cfn) );
  $this->{fn_data}->{$id} = $fn;
}

sub getIds {
  my parallel::File::FamilyNames $this = shift;

  return sort keys %{ $this->{fn_data} };
}

sub getFamilyName {
  my parallel::File::FamilyNames $this = shift;
  my ($id) = @_;

  return $this->{fn_data}->{$id};
}

################################################################################

1;

__END__

=head1 NAME

DataFiles.pm

=head1 DESCRIPTION

This class is the container for id mapping to family name.

=head1 METHODS


=cut
