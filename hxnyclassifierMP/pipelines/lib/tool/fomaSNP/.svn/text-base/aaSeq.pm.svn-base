package tool::fomaSNP::aaSeq;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;

use tool::ErrMsgs;

use base 'tool::fomaSNP';

use fields qw(
  one_2_three
  prot_type
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return tool::ErrMsgs::FOMASNP_CAT; }
###
### Run Tool Properties
###
sub ONE2THREE_PROP { return 'one2three'; }

sub AASEQ_PROPERTIES {
  return [ ONE2THREE_PROP, ];
}

################################################################################
#
#				Private Methods
#
################################################################################

sub _generateAlleleFreq {
  my tool::fomaSNP::aaSeq $this = shift;

  my $data          = $this->{fasta_data};
  my $workspaceRoot = $this->getProperties->{workspaceRoot};

  my $foma_file = $this->createFile( $this->FOMA_FILE );
  my $fomaFh    = $this->openFile($foma_file);

  my $lfoma_file = join( util::Constants::SLASH, $workspaceRoot, 'foma.table' );
  my $lfomaFh    = $this->openFile($lfoma_file);

  $this->printTab( $lfomaFh, 'Position', 'Consensus', 'FOMA', 'Detail',
    'NumberOfSequence' );

  my $seqPos = 1;
  foreach my $col ( @{ $data->{conArray} } ) {
    my @detail = ();
    while ( my ( $alphabet, $val ) = each %{$col} ) {
      next if ( !defined( $data->{symbolHash}->{$alphabet} ) );
      my $three_letter = $this->{one_2_three}->{$alphabet};
      if (util::Constants::EMPTY_LINE($three_letter)) {$three_letter = $alphabet;}
      push( @detail, "$three_letter=$val" );
    }
    my $cons1 = $col->{consensus};
    if ( $cons1 ne util::Constants::HYPHEN ) {
      $cons1 = $this->{one_2_three}->{$cons1};
    }
    my $position = $seqPos;
    if ( $cons1 eq util::Constants::HYPHEN ) {
      $position = 'N/A';
      $seqPos--;
    }
    my $details = join( util::Constants::COMMA, sort @detail );
    my @dataArray =
      ( $position, $cons1, $col->{foma}, $details, $col->{totalSeq} );
    $this->printTab( $lfomaFh, @dataArray );
    $this->printTab( $fomaFh, $this->{subtype}, $this->{host}, $this->{segment},
      $this->{prot_type}, @dataArray );
    $seqPos++;
  }
  $lfomaFh->close;
  $fomaFh->close;

  $this->{output_file}->addOutputFile( $this->FOMA_FILE, $foma_file );
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $utils, $error_mgr, $tools ) = @_;

  my tool::fomaSNP::aaSeq $this =
    $that->SUPER::new( AASEQ_PROPERTIES, $utils, $error_mgr, $tools );

  my $lproperties = $this->getLocalDataProperties;

  $this->{one_2_three} = $lproperties->{one2three};

  return $this;
}

sub createFile {
  my tool::fomaSNP::aaSeq $this = shift;
  my ($suffix) = @_;

  return join( util::Constants::SLASH,
    $this->getProperties->{workspaceRoot},
    join( util::Constants::DOT, $this->fileGroupTag, $suffix )
  );
}

sub runData {
  my tool::fomaSNP::aaSeq $this = shift;

  my $cmds        = $this->{tools}->cmds;
  my $data        = $this->getData->{seqs}->getTableInfo('seqs');
  my $groupTag    = uc( $this->groupTag );
  my $properties  = $this->getData->{properties};
  my $skip_groups = $this->{skip_groups};

  $this->{prot_type} = $properties->getProperty('prot_cat');

  my $max_seq_len = $properties->getProperty('max_seq_len');

  my $aa_file   = $this->createFile('fasta');
  my $clw_out   = $this->createFile('aln');
  my $fasta_out = $this->createFile('afa');
  ###
  ### Log tool type to use...
  ###
  if ( defined( $skip_groups->{$groupTag} ) ) {
    if ( $this->{clustalw} ) {
      $this->{error_mgr}->printMsg("Running clustalw for $groupTag");
    }
    else {
      $this->{error_mgr}->printMsg("Running muscle for $groupTag");
    }
  }
  my $fh       = $this->openFile($aa_file);
  my $aa_count = 0;
  foreach my $idata ( @{$data} ) {
    my $seq = $idata->{curated_seq};
    next if ( length($seq) / $max_seq_len <= $this->{length_cutoff} );
    $aa_count++;
    $fh->print( ">" . $idata->{ncbiacc} . "|\n$seq\n" );
  }
  $fh->close;
  if ( $aa_count < $this->{min_num_seq} ) {
    $this->{error_mgr}->printMsg(
"After cutoff number of AA sequence insufficient for meaningful snp analysis ($aa_count)\n"
    );
    return;
  }
  my $realign = 1;
  if ( $this->{run_clustalw}
    || ( defined( $skip_groups->{$groupTag} ) && $this->{clustalw} ) )
  {
    my $status = util::Constants::FALSE;
    if ( !-e $fasta_out ) {
      my $msgs =
        {   cmd => $this->{clustalw_path}
          . " -type=protein -align -output=fasta "
          . "-infile=$aa_file -outfile=$fasta_out", };
      $status =
        $cmds->executeCommand( $msgs, $msgs->{cmd}, 'running clustalw' );
      $this->{error_mgr}
        ->printMsg("Error running clustalw, will run muscle instead")
        if ($status);
    }
    if ( !$status ) {
      $realign = 0;
      $this->{error_mgr}->printMsg("Clustalw running finished\n");
      $status = $this->fasta2ClustalalW( $fasta_out, $clw_out );
      if ($status) {
        $realign = 1;
        $this->{error_mgr}->printMsg("Will run muscle instead\n");
        print "Will run muscle instead\n";
      }
      else {
        $this->{error_mgr}->printMsg("Clwout format output produced\n");
        print "Clwout format output produced\n";
      }
    }
    else {
      $this->{error_mgr}->printMsg("Will run muscle instead\n");
      print "Will run muscle instead\n";
    }
  }

  if ( $realign == 1 ) {
    my $status = util::Constants::FALSE;
    if ( !( -e $clw_out ) || !( -e $fasta_out ) ) {
      my $msgs =
        { cmd => $this->{cluster_align_path} . " $aa_file $fasta_out $clw_out",
        };
      $status =
        $cmds->executeCommand( $msgs, $msgs->{cmd}, 'executing cluster_align' );
    }
    if ($status) {
      $this->{error_mgr}->printMsg(
        "Muscle failed on this group flu protein sequences from $groupTag");
      return;
    }
  }
  ###
  ### Process the Files
  ###
  $this->clwOutStrainNameFormat($clw_out);

  my $status = $this->readFastaFile($fasta_out);
  $this->{error_mgr}->registerError( ERR_CAT, 11, [], $status );
  return if ($status);

  $this->_generateAlleleFreq;
}

################################################################################

1;

__END__

=head1 NAME

aaSeq.pm

=head1 DESCRIPTION

This class defines the runner for AA sequence fomaSNP.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::fomaSNP::aaSNP(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
