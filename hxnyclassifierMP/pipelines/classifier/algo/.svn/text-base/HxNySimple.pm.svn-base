package algo::HxNySimple;
use strict;
use warnings;

use algo::Algo;

#=========Inheriting Algo=============#
our @ISA = qw(algo::Algo);

sub getClassification {
  my $self = shift;
  my ( $treeFile, $accession ) = @_;

  my $tree_acc = $self->extract( $treeFile, $accession );
  if ( defined($tree_acc) ) {
    my $type = $self->getLookup($tree_acc);
    if ( defined($type) ) {
      return $type;
    }
    else {
      return "Other";
    }
  }
  else {
    return "ND";
  }
}

sub extract {
  my $self = shift;
  my ( $tree_file, $seq_accession ) = @_;

  my @accession = ();
  open IN, "$tree_file" or die "cannot open file:$!";
  while (<IN>) {
    chomp $_;
    $_ = uc $_;
    $_ =~ s/\n//g;
    $_ =~ s/s+//g;
    $_ =~ s/\(/ ( /g;
    $_ =~ s/\)/ ) /g;
    $_ =~ s/\:/ : /g;
    $_ =~ s/,/ , /g;
    $_ =~ s/\_/ _  /g;
    my @array = ();
    @array = split( /\s+/, $_ );
    push( @accession, @array );
  }

  my $length = @accession;
  my @new    = ();
  for ( my $i = 0 ; $i < $length ; ++$i ) {
    my @array = ();
    if ( $accession[$i] =~ m/\(/ ) {
      if ( $accession[ $i + 1 ] =~ m/^[a-zA-Z]+(\d+)$/ ) {
        push( @array, " $accession[$i+1] " );
        do {
          ++$i;
          if ( $accession[ $i + 1 ] =~ m/\(/ ) {
            @array = ();
          }
          elsif ( $accession[ $i + 1 ] =~ m/^[a-zA-Z]+(\d+)$/ ) {
            push( @array, " $accession[$i+1] " );
          }
        } until ( $accession[$i] =~ m/\)/ );
        push( @new, @array );
        push( @new, "," );
      }
    }
  }
  my $join = join( ' ', @new );
  my @split = split( ",", $join );

  foreach my $row (@split) {
    chomp $row;
    $row =~ s/^\s+//g;
    my @sep = split( " ", $row );
    if ( $sep[0] =~ m/$seq_accession/ ) {
      return $sep[1];
    }
    elsif ( $sep[1] =~ m/$seq_accession/ ) {
      return $sep[0];
    }
  }
  return undef;
}

1;

__END__

=head1 NAME
Tree:Parse

=head1 DESCRIPTION

The following module determines the classification of the query accession using
the tree file.  This new tree (tree_file) is parsed to find sister accessions.
Parsed accessions are searched in the lookup file, based upon their presence and
classification values are assigned.

=head1 Subroutines

getClassification: Determines the accession clade.

extract: Parses sister accessions and determine the accession's sister.

=head1 Author

=cut
