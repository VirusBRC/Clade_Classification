package newik::newicktree;

use newik::cnode;
use newik::lnode;
use strict;
use warnings;

sub ERROR_CLASSIFICATION   { return 'ERROR'; }
sub LIKE_CLASSIFICATION    { return '-like'; }
sub SPACE_CLASSIFICATION   { return ' '; }
sub UNKNOWN_CLASSIFICATION { return 'Unknown'; }

sub BFALSE { return 0; }
sub BTRUE  { return 1; }
sub INDENT { return '  '; }

sub new {
  my $class = shift;
  my $self  = {@_};
  bless( $self, $class );
  $self->_init;

  return $self;
}

sub _init {
  my $self = shift;

  $self->{indent} = 0;
  $self->{fh}     = undef;
  $self->{lnode}  = {};
  $self->{b}      = 0;

  my $file = $self->{file};
  open( FILE, "<$file" ) or die "Cannot open newick file $file $!";
  my $str = "";
  while (<FILE>) {
    $str .= trim($_);
  }

  close FILE;
  my @data = split( //, "$str" );
  $self->{root} = $self->_parse(@data);
}

sub _parse {
  my $self = shift;
  my (@data) = @_;
  ###
  ### $i == 0 (first open paren)
  ###
  my $cnode = $self->_getCTypeNode();
  my $root  = $cnode;

  my @stack = ();
  my $i     = 1;
  do {
    if ( $data[$i] eq ')' ) {
      $i++;
      $cnode = pop(@stack);
    }
    elsif ( $data[$i] eq '(' ) {
      $self->{b}++;
      my $newCNode = $self->_getCTypeNode($cnode);
      $cnode->addNode($newCNode);
      push( @stack, $cnode );
      $cnode = $newCNode;
      $i++;
    }
    elsif ( $data[$i] eq ',' ) {
      $i++;
      while ( $data[$i] =~ /\s/ ) {
        $i++;
      }
    }
    elsif ( $data[$i] eq ':' ) {
      $i++;
      while ( !( $data[$i] eq ')' || $data[$i] eq ',' ) ) {
        $i++;
      }
    }
    else {
      my @str = ();
      while ( !( $data[$i] eq ')' || $data[$i] eq ',' ) ) {
        push( @str, $data[ $i++ ] );
      }
      my $s = join( '', @str );
      my @split = split( /:/, $s );
      my $accession = $split[0];
      my $leafNode = $self->_getlTypeNode( $accession, $cnode );
      $self->{lnode}->{$accession} = $leafNode;
      $cnode->addNode($leafNode);
    }
  } while ( $data[$i] ne ';' );

  return $root;
}

sub _getCTypeNode {
  my $self = shift;
  my ($parent) = @_;

  my $cnode = new newik::cnode(
    name   => 'c' . $self->{b},
    type   => 'cnode',
    parent => $parent
  );
  return $cnode;
}

sub _getlTypeNode {
  my $self = shift;
  my ( $name, $parent ) = @_;

  my $class = $self->getLookup($name);
  my $node  = new newik::lnode(
    name   => $name,
    type   => 'lnode',
    parent => $parent,
    class  => $class
  );

  return $node;
}

sub trim {
  my ($str) = @_;

  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  return $str;
}

sub getLnode {
  my $self = shift;
  return $self->{lnode};
}

sub getLNodeByName {
  my $self = shift;
  my ($accession) = @_;
  return $self->{lnode}->{$accession};
}

sub getRoot {
  my $self = shift;
  return $self->{root};
}

sub getLookup {
  my $self = shift;
  my ($accession) = @_;
  return $self->{lookup}->{$accession};
}

sub getClassification {
  my $self = shift;
  my ($accession) = @_;

  my $lnode = $self->getLNodeByName($accession);
  my $cnode = $lnode->{parent};

  return $self->getCluster( $cnode, $accession );
}

sub getCluster {
  my $self = shift;
  my ( $cnode, $accession ) = @_;

  my $cnodes = $cnode->{cnode};
  my $lnodes = $cnode->{lnode};

  my %types = ();
  foreach my $name ( keys %{$lnodes} ) {
    my $node = $lnodes->{$name};
    unless ( $node->{name} eq $accession ) {
      my $classification = $node->{class};
      $classification =
        ( defined($classification) ) ? $classification : SPACE_CLASSIFICATION;
      $types{$classification}++;
    }
  }

  foreach my $name ( keys %{$cnodes} ) {
    my $node = $cnodes->{$name};
    my $cl = $self->getCluster( $node, $accession );
    $types{$cl}++;
  }

  my $class    = '';
  my $maxCount = 0;
  foreach my $type ( keys %types ) {
    if ( $types{$type} > $maxCount ) {
      $maxCount = $types{$type};
      $class    = $type;
    }
  }

  return $class;
}

sub print {
  my $self = shift;
  my ($msg) = @_;

  if ( !defined($msg) ) { $msg = ''; }
  $msg .= "\n";
  if ( defined( $self->{fh} ) ) { $self->{fh}->print($msg); }
  else { print $msg; }
}

sub determineH5N1Classification {
  my $self = shift;
  my ( $clCnts, $numSisters ) = @_;

  my @clns = sort keys %{$clCnts};
  $self->print( "    Classifications = (" . join( ', ', @clns ) . ")" );
  $self->print("    Num Sisters     = $numSisters");
  my $cntMsg = "    Classification counts = ";
  foreach my $index ( 0 .. $#clns ) {
    my $classification = $clns[$index];
    if ( $index > 0 ) { $cntMsg .= ", "; }
    $cntMsg .= "($classification, " . $clCnts->{$classification} . ")";
  }
  $self->print($cntMsg);
  my $classification = undef;
  if ( scalar @clns == 1 ) {
    $classification = $clns[0];
  }
  else {
    ###
    ### Check prefix
    ###
    my $class  = $clns[0];
    my $checks = BTRUE;
    foreach my $cl (@clns) {
      next if ( $cl =~ /^$class/ );
      $checks = BFALSE;
      last;
    }
    if ($checks) { $classification = $clns[0]; }
    else { $classification = UNKNOWN_CLASSIFICATION; }
  }
  $self->print("    Classification = $classification");
  return ( $classification, $numSisters );
}

sub determineH5N1BranchClassification {
  my $self = shift;
  my ($classes) = @_;

  $self->print(
    "    Branch Classifications = (" . join( ', ', @{$classes} ) . ")" );
  my $classification = undef;
  if ( scalar @{$classes} == 1 ) {
    $classification = $classes->[0];
  }
  else {
    ###
    ### Check prefix
    ###
    my $class  = undef;
    my @parts  = split( /\./, $classes->[0] );
    my $checks = BTRUE;
    foreach my $index ( reverse 0 .. $#parts ) {
      $checks = BTRUE;
      $class = join( '.', @parts[ 0 .. $index ] );
      foreach my $cl ( @{$classes} ) {
        next if ( $cl =~ /^$class/ );
        $checks = BFALSE;
        last;
      }
      last if ($checks);
    }
    if ($checks) { $classification = $class . LIKE_CLASSIFICATION; }
    else { $classification = UNKNOWN_CLASSIFICATION; }
  }
  $self->print("    Branch Classification = $classification");
  return $classification;
}

sub determineClassification {
  my $self = shift;
  my ( $classification, $bclassification ) = @_;

  my $like_classification   = LIKE_CLASSIFICATION;
  my $classification_prefix = $classification;
  $classification_prefix =~ s/$like_classification//;
  my $bclassification_prefix = $bclassification;
  $bclassification_prefix =~ s/$like_classification//;
  $self->print("(acc_branch, branch) = ($classification, $bclassification)");
  if ( $classification eq $bclassification ) {
    $self->print("classification containing accession THE SAME");
  }
  elsif ( $classification_prefix eq $bclassification_prefix ) {
    $self->print("classification containing accession THE SAME (LIKE)");
    $classification = $classification_prefix . LIKE_CLASSIFICATION;
  }
  elsif ( $classification =~ /^$bclassification/ ) {
    $self->print(
      "classification containing accession LOWER DOWN in tree (changing)");
    $classification = $bclassification . LIKE_CLASSIFICATION;
  }
  elsif ( $bclassification =~ /^$classification/ ) {
    $self->print("classification containing accession HIGHER UP in tree");
    $classification .= LIKE_CLASSIFICATION;
  }
  elsif ( $classification_prefix =~ /^$bclassification_prefix/ ) {
    $self->print(
      "classification containing accession LOWER DOWN in tree (changing) (LIKE)");
    $classification = $bclassification_prefix . LIKE_CLASSIFICATION;
  }
  elsif ( $bclassification_prefix =~ /^$classification_prefix/ ) {
    $self->print(
      "classification containing accession HIGHER UP in tree (LIKE)");
    $classification = $classification_prefix . LIKE_CLASSIFICATION;
  }
  else {
    ###
    ### Determine if there is maximal prefix between the two
    ###
    my $class  = undef;
    my @parts  = split( /\./, $classification_prefix );
    my $checks = BFALSE;
    foreach my $index ( reverse 0 .. $#parts ) {
      $class = join( '.', @parts[ 0 .. $index ] );
      next if ( $bclassification_prefix !~ /^$class/ );
      $checks = BTRUE;
      last;
    }
    if ($checks) { $classification = $class . LIKE_CLASSIFICATION; }
    else { $classification = UNKNOWN_CLASSIFICATION; }
  }
  $self->print("Determined Classification = $classification");
  return $classification;
}

sub getH5N1Classification {
  my $self = shift;
  my ( $accession, $fh ) = @_;

  $self->{fh} = $fh;

  my $lnode  = $self->getLNodeByName($accession);
  my $cnode  = $lnode->{parent};
  my $parent = $cnode->{parent};
  my $cnodes = defined($parent) ? $parent->{cnode} : undef;

  my $cnode_name = $cnode->{name};

  $self->print("CLASSIFY ACCESSION $accession");
  $self->print(
    "  Classification of branch containing accession " . $cnode_name );
  $self->{indent} = 0;
  my ( $classification, $numSisters ) =
    $self->determineH5N1Classification(
    $self->getH5N1Cluster( $cnode, $accession ) );
  my $recompute_accession_branch = BFALSE;
  if ( $classification eq UNKNOWN_CLASSIFICATION ) {
    $recompute_accession_branch = BTRUE;
    $self->print( "  Recompute classification of branch containing accession "
        . $cnode_name );
    $self->{indent} = 0;
    $classification =
      $self->determineH5N1BranchClassification(
      $self->getH5N1BranchCluster( $cnode, $accession ) );
  }
  my $complete = BFALSE;
  if ( $classification ne UNKNOWN_CLASSIFICATION && $numSisters == 1 ) {
    $complete = BTRUE;
    $self->print(
"Classification ($accession) assigned by singleton sister accession = $classification"
    );
  }
  elsif ( !defined($parent) ) {
    $complete = BTRUE;
    $self->print(
      "Classification ($accession) and no parent subtree = $classification");
  }
  if ($complete) {
    $self->{fh} = undef;
    return $classification;
  }
  ###
  ### There is a parent and the parent is composed
  ### of two non-trivial tree nodes.
  ###
  my $branch_node = undef;
  foreach my $name ( keys %{$cnodes} ) {
    next if ( $name eq $cnode_name );
    $branch_node = $cnodes->{$name};
    last;
  }
  ###
  ### There is a parent and the parent
  ### is a single accession and a non-trivial subtree
  ###
  if ( !defined($branch_node) ) {
    $branch_node = $parent;
  }
  $self->print( "  Classification of branch not containing accession "
      . $branch_node->{name} );
  $self->{indent} = 0;
  my ( $bclassification, $bNumSisters ) =
    $self->determineH5N1Classification(
    $self->getH5N1Cluster( $branch_node, $accession, $cnode_name ) );
  my $recompute_branch = BFALSE;
  if ( $bclassification eq UNKNOWN_CLASSIFICATION ) {
    $recompute_branch = BTRUE;
    $self->print(
      "  Recompute classification of branch not containing accession "
        . $branch_node->{name} );
    $self->{indent} = 0;
    $bclassification =
      $self->determineH5N1BranchClassification(
      $self->getH5N1BranchCluster( $branch_node, $accession, $cnode_name ) );
  }
  my $fclassification =
    $self->determineClassification( $classification, $bclassification );
  if ( $fclassification eq UNKNOWN_CLASSIFICATION
    && !( $recompute_accession_branch && $recompute_branch ) )
  {
    if ( !$recompute_accession_branch ) {
      $self->print( "  Recompute classification of branch containing accession "
          . $cnode->{name} );
      $self->{indent} = 0;
      $classification =
        $self->determineH5N1BranchClassification(
        $self->getH5N1BranchCluster( $cnode, $accession ) );
    }
    if ( !$recompute_branch ) {
      $self->print(
        "  Recompute classification of branch not containing accession "
          . $branch_node->{name} );
      $self->{indent} = 0;
      $bclassification =
        $self->determineH5N1BranchClassification(
        $self->getH5N1BranchCluster( $branch_node, $accession, $cnode_name ) );
    }
    $self->print("  RECOMPUTE CLASSIFICATION ON UNKNOWN");
    $fclassification =
      $self->determineClassification( $classification, $bclassification );
  }
  $self->print("Classification ($accession) = $fclassification");
  $self->{fh} = undef;
  return $fclassification;
}

sub getH5N1Cluster {
  my $self = shift;
  my ( $cnode, $accession, $skip_cnode_name ) = @_;

  my $cnodes = $cnode->{cnode};
  my $lnodes = $cnode->{lnode};

  my @leaves   = keys %{$lnodes};
  my @branches = keys %{$cnodes};

  my $istr = &INDENT x $self->{indent};
  $self->print( $istr . "(" . $self->{indent} . ") PARENT " . $cnode->{name} );
  $self->{indent}++;
  $istr = &INDENT x $self->{indent};

  my $types      = {};
  my $numSisters = 0;
  $self->print( $istr . 'LNODES = (' . join( ', ', @leaves ) . ")" )
    if ( scalar @leaves > 0 );
  foreach my $name (@leaves) {
    my $node = $lnodes->{$name};
    if ( defined($accession) && $node->{name} eq $accession ) {
      $self->print( $istr
          . 'lnode = ('
          . join( ', ', $node->{name}, "'ACCESSION'" )
          . ")" );
    }
    else {
      $numSisters++;
      my $classification = $node->{class};
      $classification =
        ( defined($classification) ) ? $classification : SPACE_CLASSIFICATION;
      $types->{$classification}++;
      $self->print( $istr
          . 'lnode = ('
          . join( ', ', $node->{name}, "'" . $classification . "'" )
          . ")" );
    }
  }

  $self->print( $istr . 'CNODES = (' . join( ', ', keys %{$cnodes} ) . ")" )
    if ( scalar @branches > 0 );
  foreach my $name (@branches) {
    my $node = $cnodes->{$name};
    if ( defined($skip_cnode_name) && $name eq $skip_cnode_name ) {
      $self->print( $istr . "  SKIPPING cnode $name" );
      next;
    }
    my ( $clTypes, $clNumSisters ) =
      $self->getH5N1Cluster( $node, $accession, $skip_cnode_name );
    $numSisters += $clNumSisters;
    foreach my $classification ( keys %{$clTypes} ) {
      $types->{$classification} += $clTypes->{$classification};
    }
  }

  $self->{indent}--;

  return ( $types, $numSisters );
}

sub getH5N1BranchCluster {
  my $self = shift;
  my ( $cnode, $accession, $skip_cnode_name ) = @_;

  my $cnodes = $cnode->{cnode};
  my $lnodes = $cnode->{lnode};

  my $cnode_name = $cnode->{name};

  my @leaves   = keys %{$lnodes};
  my @branches = keys %{$cnodes};

  my $level = $self->{indent};
  my $istr  = &INDENT x $level;
  $self->print( $istr . "($level) PARENT $cnode_name" );
  $self->{indent}++;
  $istr = &INDENT x $self->{indent};
  ###
  ### Cases:
  ### 1.  Only (2) leaves, no branches
  ### 2.  A branch and a leaf
  ### 3.  ONLY branches (2 branches)
  ###
  my $type = undef;
  if ( scalar @leaves > 0 ) {
    $self->print( $istr . 'LNODES = (' . join( ', ', @leaves ) . ")" );
    foreach my $name (@leaves) {
      my $node = $lnodes->{$name};
      if ( defined($accession) && $node->{name} eq $accession ) {
        $self->print( $istr . 'lnode(ACCESSION) = (' . $node->{name} . ")" );
      }
      else {
        my $classification = $node->{class};
        $classification =
          ( defined($classification) )
          ? $classification
          : SPACE_CLASSIFICATION;
        $type =
          ( !defined($type) || $type eq $classification )
          ? $classification
          : ERROR_CLASSIFICATION;
        $self->print( $istr
            . 'lnode = ('
            . join( ', ', $node->{name}, "'" . $classification . "'" )
            . ")" );
      }
    }
    $self->print( &INDENT x $level
        . "($level) PARENT $cnode_name accession(s) class = $type" )
      if ( defined($type) );
    $self->print( $istr . "ERROR occurred in determination of sisters" )
      if ( defined($type) && $type eq ERROR_CLASSIFICATION );
  }
  if ( scalar @branches == 0 ) {
    my $classes = [$type];
    $self->{indent}--;
    $istr = &INDENT x $self->{indent};
    $self->print( $istr
        . "($level) PARENT $cnode_name classes = ["
        . join( ', ', @{$classes} )
        . "]" );

    return $classes;
  }

  $self->print( $istr . 'CNODES = (' . join( ', ', @branches ) . ")" );
  my @branchClasses = ();
  foreach my $index ( 0 .. $#branches ) {
    my $name = $branches[$index];
    if ( defined($skip_cnode_name) && $name eq $skip_cnode_name ) {
      $self->print( $istr . "  SKIPPING cnode $name" );
      next;
    }
    my $node = $cnodes->{$name};
    $branchClasses[$index] =
      $self->getH5N1BranchCluster( $cnodes->{$name}, $accession,
      $skip_cnode_name );
  }
  if ( scalar @branchClasses == 0 ) {
    my $classes = [$type];
    $self->{indent}--;
    $istr = &INDENT x $self->{indent};
    $self->print( $istr
        . "($level) PARENT $cnode_name classes = ["
        . join( ', ', @{$classes} )
        . "]" );

    return $classes;
  }

  my $classes       = [];
  my $branchClass   = undef;
  my $branchNode    = undef;
  my $dataStr       = undef;
  my $reductionType = 'joined';
  my $typeNode      = undef;
  if ( scalar @leaves > 0 && !defined($type) ) {
    ###
    ### NO-OP since this is a situation where the leaf is the accession
    ###
  }
  elsif ( scalar @leaves > 0 ) {
    $branchClass = $branchClasses[0];
    $branchNode  = $branches[0];
    $typeNode    = 'leaf';
  }
  elsif ( scalar @{ $branchClasses[0] } == 1
    && scalar @{ $branchClasses[1] } == 1 )
  {
    my $type1 = $branchClasses[0]->[0];
    my $type2 = $branchClasses[1]->[0];
    if ( $type1 eq $type2 || $type2 =~ /^$type1/ ) {
      $branchClass = $branchClasses[1];
      $branchNode  = $branches[1];
      $type        = $branchClasses[0]->[0];
      $typeNode    = $branches[0];
    }
    else {
      $branchClass = $branchClasses[0];
      $branchNode  = $branches[0];
      $type        = $branchClasses[1]->[0];
      $typeNode    = $branches[1];
    }
  }
  elsif ( scalar @{ $branchClasses[0] } == 1 ) {
    $branchClass = $branchClasses[1];
    $branchNode  = $branches[1];
    $type        = $branchClasses[0]->[0];
    $typeNode    = $branches[0];
  }
  elsif ( scalar @{ $branchClasses[1] } == 1 ) {
    $branchClass = $branchClasses[0];
    $branchNode  = $branches[0];
    $type        = $branchClasses[1]->[0];
    $typeNode    = $branches[1];
  }
  if ( defined($branchClass) ) {
    push( @{$classes}, $type );
    my $containsType = BFALSE;
    my $prefixType   = BFALSE;
    foreach my $class ( sort @{$branchClass} ) {
      if ( $type eq $class ) { $containsType = BTRUE; }
      if ( !$containsType && $class =~ /^$type/ ) { $prefixType = BTRUE; }
    }
    $reductionType = ( $containsType || $prefixType ) ? 'reduced' : 'joined';
    push( @{$classes}, @{$branchClass} ) if ( $reductionType eq 'joined' );
    $dataStr =
      "($branchNode, $typeNode), ($containsType, $prefixType), ($type, ["
      . join( ', ', sort @{$branchClass} ) . "])";
  }
  else {
    my %cClasses = ();
    foreach my $index ( 0 .. $#branchClasses ) {
      foreach my $class ( @{ $branchClasses[$index] } ) {
        $cClasses{$class} = '';
      }
    }
    push( @{$classes}, keys %cClasses );
    $dataStr = "[" . join( ', ', @leaves, @branches ) . "]";
  }
  @{$classes} = sort @{$classes};

  $self->{indent}--;
  $istr = &INDENT x $self->{indent};
  $self->print(
    $istr . "($level) PARENT $cnode_name $reductionType = $dataStr" );
  $self->print( $istr
      . "($level) PARENT $cnode_name classes = ["
      . join( ', ', @{$classes} )
      . "]" );

  return $classes;
}

sub printTree {
  my $self = shift;
  my ( $accession, $fh ) = @_;

  $self->{fh}     = $fh;
  $self->{indent} = 0;
  $self->print("accession = $accession");
  $self->printNode( $self->{root}, $accession );
  $self->{fh} = undef;
}

sub printNode {
  my $self = shift;
  my ( $cnode, $accession ) = @_;

  my $cnodes = $cnode->{cnode};
  my $lnodes = $cnode->{lnode};

  my $istr = &INDENT x $self->{indent};
  $self->print( $istr . "(" . $self->{indent} . ") PARENT " . $cnode->{name} );

  $self->{indent}++;
  $istr = &INDENT x $self->{indent};

  foreach my $name ( keys %{$lnodes} ) {
    my $node = $lnodes->{$name};
    unless ( $node->{name} eq $accession ) {
      my $classification = $node->{class};
      $classification =
        ( defined($classification) ) ? $classification : SPACE_CLASSIFICATION;
      $self->print( $istr
          . 'lnode = ('
          . join( ', ', $node->{name}, "'" . $classification . "'" )
          . ")" );
    }
    $self->print( $istr . 'lnode(ACCESSION) = (' . $node->{name} . ")" )
      if ( $node->{name} eq $accession );
  }

  $self->print( $istr . 'CNODES = (' . join( ', ', keys %{$cnodes} ) . ")" )
    if ( scalar keys %{$cnodes} != 0 );
  foreach my $name ( keys %{$cnodes} ) {
    my $node = $cnodes->{$name};
    $self->printNode( $node, $accession );
  }

  $self->{indent}--;
}

return 1;
