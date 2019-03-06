package algo::Blast;

use strict;
use warnings;
use algo::Algo;

#=========Inheriting Algo=============#
our @ISA = qw(algo::Algo);

sub getClassification {
  my $self = shift;
  my ($sequence) = shift;

  my $length_seq      = length($sequence);
  my $lower_threshold = $self->{lower_threshold};
  my $upper_threshold = $self->{upper_threshold};

  my $sequenceFile = "sequenceFile_BLAST.tmp";
  open( SEQUENCEFILE, ">$sequenceFile" );
  print SEQUENCEFILE "$sequence";
  close(SEQUENCEFILE);

  my $blastCmd = $self->{blastall};
  $blastCmd =~ s/<INPUTFILE>/$sequenceFile/;
  my $blastResult = `$blastCmd`;
  print $blastResult if ( $self->{blastout} );

  my %counts   = ();
  my %comp     = ();
  my %acc_type = ();
  foreach my $row ( split( /[\n\r]/, $blastResult ) ) {
    my ( $n, $accession, $percid, $cov ) = split( /\t/, $row );
    $percid =~ s/^\s+//;
    $percid =~ s/\s+$//;
    my $type = $self->getLookup($accession);
    if ( $percid && $cov ) {
      my $struct = {
        percid => $percid,
        cov    => $cov,
      };
      if ( !defined( $comp{$accession} ) ) {
        $comp{$accession} = [];
      }
      push( @{ $comp{$accession} }, $struct );
    }
    if ( !defined( $acc_type{$accession} ) ) {
      $acc_type{$accession} = $type;
    }
    $counts{$type}++;
  }
  my %add       = ();
  my @per_value = ();
  my @types     = keys %counts;
  my $count     = scalar @types;

  print '%counts   = (' . join( '::', %counts ) . ")\n";
  print '%comp     = ' . "\n";
  foreach my $accession ( keys %comp ) {
    print "  $accession = \n";
    foreach my $data ( @{ $comp{$accession} } ) {
      print "    " . join( ', ', %{$data} ) . "\n";
    }
  }
  print '%acc_type = (' . join( ', ', %acc_type ) . ")\n";
  print '@types    = (' . join( '::', @types ) . ")\n";
  print '$count    = ' . $count . "\n";

  #===========Case:1=================#

  if ( $count == 1 ) {    #Case:1 Count==1
    my $type = $types[0];
    print "type = $type\n";
    foreach my $accession ( keys %comp ) {
      my $sum = $self->avg( $length_seq, $comp{$accession} );
      print "$accession sum = $sum\n";
      $add{$accession} = $sum;
      push( @per_value, $sum );
    }
    my $string = join( ", ", @per_value );
    print "string = $string\n";
    my $check = 0;
    foreach my $accession ( keys %add ) {
      if ( $add{$accession} >= $lower_threshold ) {
        ++$check;
      }
    }
    print "check = $check\n";
    if ( $check >= 3 ) {
      print '$check >= 3' . "\n";
      return ( $type, $string );
    }
    else {
      print 'else' . "\n";
      return ( "Other", $string );
    }
  }

  #============Case2:================#

  elsif ( $count == 2 ) {    #Case:2 Count==2
    my @array_type = ();
    foreach my $accession ( keys %acc_type ) {
      my $class_value = $acc_type{$accession};
      push( @array_type, $class_value );
    }
    print '@array_type = (' . join( ', ', @array_type ) . ")\n";
    my %seen = ();
    my @dup  = ();
    @dup = map { 1 == $seen{$_}++ ? $_ : () } @array_type;
    print '%seen = (' . join( ', ', %seen ) . ")\n";
    print '@dup  = (' . join( ', ', @dup ) . ")\n";
    my $final_value = shift(@dup);
    my %filtered    = ();
    print "final_value = $final_value\n";

    foreach my $accession ( keys %acc_type ) {
      my $class_value = $acc_type{$accession};
      if ( $class_value =~ m/^$final_value$/ ) {
        $filtered{$accession} = $final_value;
      }
    }
    print '%filtered = (' . join( ', ', %filtered ) . ")\n";
    my %add_sum   = ();
    my @per_value = ();
    foreach my $accession ( keys %filtered ) {
      my $sum = $self->avg( $length_seq, $comp{$accession} );
      print "$accession sum = $sum\n";
      $add_sum{$accession} = $sum;
      push( @per_value, $sum );
      push( @per_value, "," );
    }
    my $string = join( ", ", @per_value );
    my $check = 0;
    foreach my $accession ( keys %add_sum ) {
      if ( $add_sum{$accession} >= $upper_threshold ) {
        ++$check;
      }
    }
    if ( $check >= 2 ) {
      print '$check >= 2' . "\n";
      return ( $final_value, $string );
    }
    else {
      print 'else' . "\n";
      return ( "Other", $string );
    }
  }

  #=============Case3:==============#

  elsif ( $count == 3 ) {    #Case:3 Count==3
    return ( "Other", "Case3: values differ" );
  }
}

#============Calculate avg statisitics====#

sub avg {
  my $self = shift;
  my ( $length_seq, $array ) = @_;

  my $sum = 0;
  foreach my $comp ( @{$array} ) {
    my $value = $comp->{percid} * $comp->{cov} / $length_seq;
    print "value = ("
      . join( ', ', $value, $comp->{percid}, $comp->{cov} ) . ")\n";
    $sum += $value;
  }
  return $sum;
}

1;

__END__

=head1 NAME
algo::Classification

=head1 DESCRIPTION

The following module uses the blast out results from blast-all and provides a
classification value to every accession.  The decision for classification value
is made from the consistency of classification values for an accession and the
supplied Upper and Lower Threshold values.  Note, this module inhertes
properties from the algo::Algo package.

=head1 Author
Hrishikesh Lokhande
LANL
10/7/2013
=cut

