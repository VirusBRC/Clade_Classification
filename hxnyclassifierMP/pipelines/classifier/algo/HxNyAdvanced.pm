package algo::HxNyAdvanced;
use strict;
use warnings;

use algo::Algo;

#=========Inheriting Algo=============#
our @ISA = qw(algo::Algo);

sub getClassification {
  my $self = shift;
  my ( $treeFile, $accession ) = @_;

  my $nodelook = $self->Nodelook;
  my $lookup   = {};

  print "sequence file AND query :: $treeFile, $accession\n";
  my ( $X, $Sister ) = $self->Advance( $treeFile, $accession );

  print "X :: " . join( '', @{$X} ) . "\n";
  print "Sister :: " . join( '', @{$Sister} ) . "\n";

  foreach ( @{$X} ) {
    chomp $_;
    if ( $_ =~ m/^[A-Za-z]+(\d+)$/ ) {
      $_ =~ s/\s//g;
      my $type = $self->getLookup($_);
      if ( defined($type) ) {
        $type =~ s/\s//g;
        $lookup->{$_} = $type;
      }
    }
  }
  foreach ( @{$Sister} ) {
    chomp $_;
    if ( $_ =~ m/^[A-Za-z]+(\d+)$/ ) {
      $_ =~ s/\s//g;
      my $type = $self->getLookup($_);
      if ( defined($type) ) {
        $type =~ s/\s//g;
        $lookup->{$_} = $type;
      }
    }
  }
  my $confirm = undef;
  my $final   = undef;

  print "  Lookup:\n";
  foreach my $acc ( sort keys %{$lookup} ) {
    print "    $acc = " . $lookup->{$acc} . "\n";
  }

  my ( $needconfirmation, $Provision ) =
    $self->Classification( $X, $lookup, $nodelook, $accession );
  if ($needconfirmation) {

    print "Need Confirmation\n";

    $confirm = $self->Find_value( $Sister, $lookup, $nodelook );
    $final = $self->Final( $Provision, $confirm, $nodelook );

  }
  else {
    $confirm = ' no need for sister confirmation ';
    $final   = $Provision;
  }
  unless ( defined($final) ) { $final = 'ND'; }
  print "Provision, confirm, final ::: $Provision\t$confirm\t$final\n";

  return $final;
}

sub Advance {
  my $self = shift;
  my ( $tree, $query ) = @_;

  my $X      = [];
  my $Sister = [];
  my $array  = $self->clean($tree);

  # print "whole tree : " . join(', ', @{$array}) . "\n";
  # print "$query\n";
  my $len         = scalar @{$array};
  my @count_array = ();
  for ( my $i = 0 ; $i < $len ; ++$i ) {
    $array->[$i] =~ s/\s+//g;
    if ( $array->[$i] =~ m/$query/ ) {

      print "i :: $i :: $array->[$i]\n";
      if ( $array->[ $i - 1 ] =~ m/\(/ ) {
        push( @{$X}, $array->[ $i - 1 ] );
        my $count = 1;
        my $k     = $i - 1;
        do {
          ++$k;
          push( @{$X}, $array->[$k] );
          if ( $array->[$k] =~ m/\(/ ) {
            ++$count;
          }
          elsif ( $array->[$k] =~ m/\)/ ) {
            --$count;
          }

          # else{}
          print "X :: $k :: $array->[$k] ::: $count\n";
        } until ( ( $array->[$k] =~ m/\)/ ) && ( $count == 0 ) );

        print "final X :: " . join( '', @{$X} ) . "\n";
        if ( $array->[ $k + 1 ] =~ m/\,/ ) {
          my $count_nxt = 1;
          do {
            ++$k;
            push( @{$Sister}, $array->[$k] );
            if ( $array->[$k] =~ m/\(/ ) {
              ++$count_nxt;
            }
            elsif ( $array->[$k] =~ m/\)/ ) {
              --$count_nxt;
            }
            else { }

            print "knext_forward :: $k :: $array->[$k] ::: $count_nxt\n";
          } until ( ( $array->[$k] =~ m/\)/ ) && ( $count_nxt == 0 ) );
          pop( @{$Sister} );
          shift( @{$Sister} );

          print "sister_forward1 :: " . join( '', @{$Sister} ) . "\n";
        }
        elsif ( $array->[ $i - 2 ] =~ m/\,/ ) {
          my $count_nxt = 1;
          my $point     = $i - 1;
          do {
            --$point;
            push( @{$Sister}, $array->[$point] );
            if ( $array->[$point] =~ m/\)/ ) {
              ++$count_nxt;
            }
            elsif ( $array->[$point] =~ m/\(/ ) {
              --$count_nxt;
            }

            print "knext_backward1 :: $k :: $array->[$k] ::: $count_nxt\n";
          } until ( ( $array->[$point] =~ m/\(/ ) && ( $count_nxt == 0 ) );
          pop( @{$Sister} );
          @{$Sister} = reverse @{$Sister};
          pop( @{$Sister} );

          print "sister_backward1 :: " . join( '', @{$Sister} ) . "\n";
        }
      }
      elsif ( $array->[ $i + 1 ] =~ m/\)/ ) {
        my $point = $i + 1;
        push( @{$X}, $array->[ $i + 1 ] );
        my $count = 1;
        my $k     = $i + 1;
        do {
          --$k;
          push( @{$X}, $array->[$k] );
          if ( $array->[$k] =~ m/\)/ ) {
            ++$count;
          }
          elsif ( $array->[$k] =~ m/\(/ ) {
            --$count;
          }
          else { }
        } until ( ( $array->[$k] =~ m/\(/ ) && ( $count == 0 ) );
        @{$X} = reverse @{$X};

        print "final X :: " . join( '', @{$X} ) . "\n";

        if ( $array->[ $i + 2 ] =~ m/\)/ ) {
          my $count_nxt = 1;
          do {
            --$k;
            push( @{$Sister}, $array->[$k] );
            if ( $array->[$k] =~ m/\)/ ) {
              ++$count_nxt;
            }
            elsif ( $array->[$k] =~ m/\(/ ) {
              --$count_nxt;
            }
            else { }
          } until ( ( $array->[$k] =~ m/\(/ ) && ( $count_nxt == 0 ) );
          pop( @{$Sister} );
          @{$Sister} = reverse @{$Sister};
          pop( @{$Sister} );

          print "sister_backward2 :: " . join( '', @{$Sister} ) . "\n";
        }
        elsif ( $array->[ $k - 1 ] =~ m/\(/ ) {
          my $count_nxt = 1;
          do {
            ++$point;
            push( @{$Sister}, $array->[$point] );
            if ( $array->[$point] =~ m/\(/ ) {
              ++$count_nxt;
            }
            elsif ( $array->[$point] =~ m/\)/ ) {
              --$count_nxt;
            }
            else { }
          } until ( ( $array->[$point] =~ m/\)/ ) && ( $count_nxt == 0 ) );
          pop( @{$Sister} );
          shift( @{$Sister} );

          print "sister_forward2 :: " . join( '', @{$Sister} ) . "\n";
        }
      }
    }    # end if($array->[$i]=~m/$query/)
  }

  return ( $X, $Sister );
}

sub clean {
  my $self = shift;
  my ($file) = @_;

  my $array = [];
  open IN, "$file" or die "cannot open file:$!";
  while (<IN>) {
    chomp $_;
    my @arr1 = ();
    $_ =~ s/:/ /g;
    $_ =~ s/,/ , /g;
    $_ =~ s/(\d)+\.+(\d+)+([eE][-+]?(\d+))?//g;
    $_ =~ s/(\d)[eE][-+]?\d+//g;
    $_ =~ s/\)/ \) /g;
    $_ =~ s/\(/ \( /g;
    @arr1 = split( " ", $_ );
    push( @{$array}, @arr1 );
  }
  return $array;
}

sub Classification {
  my $self = shift;
  my ( $X, $lookup, $nodelook, $query ) = @_;

  print "Start Classificiation\n";
  my $provision;
  my $len_X      = $#{$X};
  my $needsister = 1;
  my $thisx      = 0;
  print "len_X :: " . ( $len_X - 1 ) . "\n";
  for ( my $k = $len_X - 1 ; $k > 0 ; --$k ) {
    if ( $X->[$k] =~ m/^$query$/ ) {
      print "query $k \n";
      $thisx = $k;
    }
  }
  print "thisx :: $thisx\n";

  if ( $X->[ $thisx + 1 ] eq ',' && $X->[ $thisx + 2 ] =~ m/^[a-zA-Z]+(\d+)$/ )
  {
    $provision  = $lookup->{ $X->[ $thisx + 2 ] };
    $needsister = 0;
  }
  elsif ( $X->[ $thisx - 1 ] eq ','
    && $X->[ $thisx - 2 ] =~ m/^[a-zA-Z]+(\d+)$/ )
  {
    $provision  = $lookup->{ $X->[ $thisx - 2 ] };
    $needsister = 0;
  }
  else {
    $needsister = 1;
    if ( $thisx == 1 ) {
      splice( @{$X}, $len_X, 1 );
      splice( @{$X}, 0,      3 );

      print "begin :: " . join( '', @{$X} ) . "\n";
      $provision = $self->sub_find_value( $X, $lookup, $nodelook );
    }
    elsif ( $thisx == $len_X - 1 ) {
      splice( @{$X}, $len_X - 2, 3 );
      splice( @{$X}, 0,          1 );

      print "end :: " . join( '', @{$X} ) . "\n";
      $provision = $self->sub_find_value( $X, $lookup, $nodelook );
    }
    else {
      print "error in X :: " . join( '', @{$X} ) . "\n";
      $provision = 'ND';
    }
  }
  print "End Classification\n";
  return ( $needsister, $provision );
}

sub Find_value {
  my $self = shift;
  my ( $X, $hash_def, $nodelook ) = @_;

  print "Start Find_value\n";
  print "  Branch = " . join( '', @{$X} ) . "\n";
  my $value  = undef;
  my @values = ();
  print "  Assign Clades to Nodes in Branch\n";
  for ( my $i = 0 ; $i <= $#{$X} ; $i++ ) {
    if ( $X->[$i] =~ m/^[a-zA-Z]+(\d+)$/ ) {
      if ( defined( $hash_def->{ $X->[$i] } ) ) {
        $values[$i] = $hash_def->{ $X->[$i] };
        $value = $values[$i];
      }
      else {
        print "error :: $X->[$i] not defined\n";
        $value = 'ND';
        print "Find_value return :: $value\n";
        return $value;
      }
    }
    else { $values[$i] = $X->[$i]; }
  }
  print "  value = $value\n";
  print "  Branch Decorated with Clades = " . join( '', @values ) . "\n";
  my $cycle = 0;
  my $pair;
  print "  Cycling through the Branch\n";
  do {
    $cycle++;
    print "    Cycle = $cycle\n";
    $pair = 1;
    for ( my $i = 1 ; $i < $#values ; $i++ ) {
      if ( $values[ $i - 1 ] eq '('
        && $values[ $i + 1 ] eq ','
        && $values[ $i + 3 ] eq ')'
        && $values[$i] =~ m/^[a-zA-Z0-9.-]+/
        && $values[ $i + 2 ] =~ m/^[a-zA-Z0-9.-]+/ )
      {
        print "      Pair($pair) :: index = $i, "
          . $values[$i] . ", "
          . $values[ $i + 2 ] . "\n";
        $value = $nodelook->{ $values[$i] }->{ $values[ $i + 2 ] };
        print "      value = $value\n";
        unless ( defined($value) ) {
          print
            "error ::: no node lookup sister ::: $values[$i] , $values[$i+2]\n";
          $value = 'ND';
          print "Find_value return :: $value\n";
          return $value;
        }
        splice( @values, $i - 1, 4 );
        $values[ $i - 1 ] = $value;
        $pair++;

        print "      Sister Array :: " . join( '', @values ) . "\n\n";
      }
    }
  } until ( $#values <= 1 || $pair == 1 );

  print "Find_value return :: $value\n";
  return $value;
}

sub sub_find_value {
  my $self = shift;
  my ( $X, $hash_def, $nodelook ) = @_;

  print "Start sub_find_value\n";
  print "  Branch = " . join( '', @{$X} ) . "\n";
  my $value  = undef;
  my @values = ();
  print "  Assign Clades to Nodes in Branch\n";
  for ( my $i = 0 ; $i <= $#{$X} ; $i++ ) {
    if ( $X->[$i] =~ m/^[a-zA-Z]+(\d+)$/ ) {
      if ( defined( $hash_def->{ $X->[$i] } ) ) {
        $values[$i] = $hash_def->{ $X->[$i] };
        $value = $values[$i];
      }
      else {
        print "error :: $X->[$i] not defined\n";
        $value = 'ND';
        print "sub_find_value return :: $value\n";
        return $value;
      }
    }
    else { $values[$i] = $X->[$i]; }
  }
  print "  value = $value\n";
  print "  Branch Decorated with Clades = " . join( '', @values ) . "\n";
  my $cycle = 0;
  my $pair;
  print "  Cycling through the Branch\n";
  do {
    $cycle++;
    print "    Cycle = $cycle\n";
    $pair = 1;
    for ( my $i = 1 ; $i < $#values ; $i++ ) {
      if ( $values[ $i - 1 ] eq '('
        && $values[ $i + 1 ] eq ','
        && $values[ $i + 3 ] eq ')'
        && $values[$i] =~ m/^[a-zA-Z0-9.-]+/
        && $values[ $i + 2 ] =~ m/^[a-zA-Z0-9.-]+/ )
      {
        print "      Pair($pair) :: index = $i, "
          . $values[$i] . ", "
          . $values[ $i + 2 ] . "\n";
        $value = $nodelook->{ $values[$i] }->{ $values[ $i + 2 ] };
        print "      value = $value\n";
        unless ( defined($value) ) {
          print "error ::: no node lookup X ::: $values[$i] , $values[$i+2]\n";
          $value = 'ND';
          print "sub_find_value return :: $value\n";
          return $value;
        }
        splice( @values, $i - 1, 4 );
        $values[ $i - 1 ] = $value;
        $pair++;

        print "      Sister Array :: " . join( '', @values ) . "\n\n";
      }
    }
  } until ( $#values <= 1 || $pair == 1 );

  print "sub_find_value return :: $value\n";
  return $value;
}

sub Final {
  my $self = shift;
  my ( $Provisional, $Confirmation, $nodelook ) = @_;
  my $finaldef = $nodelook->{$Provisional}->{$Confirmation};
  print
"Final :: provision = $Provisional, confirm = $Confirmation, final = $finaldef\n";
  return $finaldef;
}

sub Nodelook {
  my $self = shift;

  my $node_lookup = $self->{node_lookup};
  open IN, "$node_lookup" or die "cannot open file:$!";
  my $nodelook = {};
  while (<IN>) {
    chomp;
    my @split2;
    unless ($_) { next; }

    # print "node : $_\n";
    @split2 = split( "\t", $_ );
    $split2[0] =~ s/\s+//g;
    $split2[1] =~ s/\s+//g;
    $split2[2] =~ s/\s+//g;
    $nodelook->{ $split2[0] }->{ $split2[1] } = $split2[2];
    $nodelook->{ $split2[1] }->{ $split2[0] } = $split2[2];
  }
  close IN;
  return $nodelook;
}

1;
