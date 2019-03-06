package parallel::File::Rate4Site;
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
  r4s_file
  r4s
  error_mgr
);

################################################################################
#
#			            Constants
#
################################################################################

sub FILE_EXISTS     { return 'EXISTS'; }
sub FILE_NOT_EXISTS { return 'NOT EXISTS'; }

################################################################################
#
#			            Public Methods
#
################################################################################

sub new {
  my parallel::File::Rate4Site $this = shift;
  my ( $r4s_file, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{r4s_file}  = $r4s_file;
  $this->{r4s}       = {};
  $this->{error_mgr} = $error_mgr;

  return $this;
}

sub getRate4SiteFilesFile {
  my parallel::File::Rate4Site $this = shift;
  return $this->{r4s_file};
}

sub readFile {
  my parallel::File::Rate4Site $this = shift;

  $this->{r4s} = {};
  my $r4sFile = $this->{r4s_file};
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($r4sFile) );
  my $r4s = $this->{r4s};
  my $fh  = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $r4sFile, '<' ) );
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    my ( $pdb, $file, $file_status, $full_file, $full_status ) =
      split( /\t/, $line );
    $r4s->{$pdb} = {
      file => {
        name   => $file,
        status => $file_status,
      },
      full => {
        name   => $full_file,
        status => $full_status,
      },
    };
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub writeFile {
  my parallel::File::Rate4Site $this = shift;

  my $r4s     = $this->{r4s};
  my $r4sFile = $this->{r4s_file};
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($r4sFile) );
  my $fh = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $r4sFile, '>' ) );
  foreach my $pdb ( keys %{ $r4s } ) {
    my $data = $r4s->{$pdb};
    $fh->print(
      join( util::Constants::TAB,
        $pdb,                    $data->{file}->{name},
        $data->{file}->{status}, $data->{full}->{name},
        $data->{full}->{status}
        )
        . "\n"
    );
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub addRate4Site {
  my parallel::File::Rate4Site $this = shift;
  my ( $pdb, $file, $full_file ) = @_;

  my $r4s = $this->{r4s};
  $r4s->{$pdb} = {
    file => {
      name   => $file,
      status => ( -e $file && !-z $file ) ? FILE_EXISTS : FILE_NOT_EXISTS,
    },
    full => {
      name   => $full_file,
      status => ( -e $full_file && !-z $full_file )
      ? FILE_EXISTS
      : FILE_NOT_EXISTS,
    },
  };
}

sub getPdbs {
  my parallel::File::Rate4Site $this = shift;

  return sort keys %{ $this->{r4s} };
}

sub getRate4SiteFile {
  my parallel::File::Rate4Site $this = shift;
  my ($pdb) = @_;

  my $struct = $this->{r4s}->{$pdb};
  return ( undef, undef ) if ( !defined($struct) );
  return ( $struct->{file}->{name}, $struct->{file}->{status} );
}

sub getRate4SiteFullFile {
  my parallel::File::Rate4Site $this = shift;
  my ($pdb) = @_;

  my $struct = $this->{r4s}->{$pdb};
  return ( undef, undef ) if ( !defined($struct) );
  return ( $struct->{full}->{name}, $struct->{full}->{status} );
}

################################################################################

1;

__END__

=head1 NAME

Rate4Site.pm

=head1 DESCRIPTION

This class is the container for data rate for site file results.

=head1 METHODS


=cut
