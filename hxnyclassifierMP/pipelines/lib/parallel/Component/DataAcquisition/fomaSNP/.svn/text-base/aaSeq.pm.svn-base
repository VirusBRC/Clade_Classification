package parallel::Component::DataAcquisition::fomaSNP::aaSeq;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'chdir';
use File::Basename;
use FileHandle;
use Pod::Usage;

use util::Constants;

use base 'parallel::Component::DataAcquisition::fomaSNP';

use fields qw(
  aa_template
  aa_template_dir
  bl2seq_cutoff
  min_seq_len
  seg_2_protein
  tmp_file
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### AA Sequence Specific Properties the Controller Configuration
###
sub AATEMPLATE_PROP   { return 'aaTemplate'; }
sub BL2SEQCUTOFF_PROP { return 'bl2seqCutoff'; }
sub MINSEQLEN_PROP    { return 'minSeqLen'; }
sub PROTEIN_PROP      { return 'protein'; }
sub SEG2PROTEIN_PROP  { return 'seg2protein'; }

sub AASEQ_PROPERTIES {
  return [
    AATEMPLATE_PROP, BL2SEQCUTOFF_PROP, MINSEQLEN_PROP,
    PROTEIN_PROP,    SEG2PROTEIN_PROP,
  ];
}

################################################################################
#
#                           Private Methods
#
################################################################################

sub _checkProteinSeq {
  my parallel::Component::DataAcquisition::fomaSNP::aaSeq $this = shift;
  my ( $datum, $protein_category ) = @_;

  my $ncbiacc = $datum->{ncbiacc};
  my $seq     = $datum->{seq};
  my $segment = $datum->{segment};
  ###
  ### The protein sequence must be at least 20 animo-acids
  ###
  my $prot_type = undef;
  if ( length($seq) < $this->{min_seq_len} ) {
    $this->{error_mgr}->printMsg("Sequence too short ($ncbiacc)");
    return ( util::Constants::FALSE, $prot_type );
  }
  ###
  ### Cannot use bl2seq
  ###
  my $status = system("which bl2seq > /dev/null");
  $this->setErrorStatus( $this->ERR_CAT, 10, [], $status );
  return ( util::Constants::TRUE, $prot_type ) if ( $this->getErrorStatus );
  ###
  ### Cannot create fasta file
  ###
  my $file = $this->{tmp_file};
  my $fh   = new FileHandle;
  $this->setErrorStatus(
    $this->ERR_CAT, 2,
    [ 'open seq file for bl2seq file', $file, ],
    !$fh->open( $file, '>' )
  );
  return ( util::Constants::TRUE, $prot_type ) if ( $this->getErrorStatus );
  $fh->print(">gb|$ncbiacc\n$seq\n");
  $fh->close;

  foreach my $protein ( @{ $this->{seg_2_protein}->{$segment} } ) {
    my $template_file = join( util::Constants::SLASH,
      $this->{aa_template_dir},
      $segment, join( util::Constants::DOT, $protein, 'fasta' )
    );
    next if ( !-s $template_file );
    my $cmd =
        'bl2seq -i ' . "$file" . ' -j '
      . $template_file
      . ' -p blastp -F F -e '
      . $this->{bl2seq_cutoff}
      . ' | grep -c " No hits found "';
    my $count = $this->{tools}->cmds->executeInline($cmd);
    $this->{error_mgr}->printMsg( "Testing protein category\n"
        . "  ncbiacc = $ncbiacc\n"
        . "  protein = $protein\n"
        . "  count   = $count" );
    if ( $count == 0 ) {
      $prot_type = $protein;
      $this->{error_mgr}->printMsg( "Changed Protein Category\n"
          . "  ncbiacc   = $ncbiacc\n"
          . "  category\n"
          . "    old     = $protein_category\n"
          . "    new     = $prot_type" );
      last;
    }
  }
  unlink($file);
  return ( util::Constants::TRUE, $prot_type );
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::DataAcquisition::fomaSNP::aaSeq $this =
    $that->SUPER::new( AASEQ_PROPERTIES, $controller, $utils, $error_mgr,
    $tools );

  my $lproperties = $this->getLocalDataProperties( [] );

  $this->{aa_template_dir} = undef;
  $this->{aa_template}     = $lproperties->{&AATEMPLATE_PROP};
  $this->{bl2seq_cutoff}   = $lproperties->{&BL2SEQCUTOFF_PROP};
  $this->{min_seq_len}     = $lproperties->{&MINSEQLEN_PROP};
  $this->{seg_2_protein}   = $lproperties->{&SEG2PROTEIN_PROP};
  $this->{tmp_file}        = undef;

  return $this;
}

sub fileGroupTag {
  my parallel::Component::DataAcquisition::fomaSNP::aaSeq $this = shift;
  my ($datum) = @_;
  ###
  ### As per Wei's suggestion
  ### This is only to used for file names
  ###
  my $groupTag = $this->groupTag($datum);
  $groupTag =~ s/'//g;    ###'

  return join( util::Constants::UNDERSCORE, $groupTag, $datum->{prot_cat} );
}

sub initializeFomaSnpData {
  my parallel::Component::DataAcquisition::fomaSNP::aaSeq $this = shift;

  my $tools       = $this->{tools};
  my $cmds        = $this->{tools}->cmds;
  my $aa_template = $this->{aa_template};

  $this->{tmp_file} = join( util::Constants::SLASH,
    $this->getWorkspaceRoot, $tools->cmds->TMP_FILE( 'bl2seq', 'fasta' ) );

  return if ( !-e $aa_template || $aa_template !~ /\.tar$/ );

  $this->{aa_template_dir} = join( util::Constants::SLASH,
    $this->getWorkspaceRoot, basename($aa_template) );
  $this->{aa_template_dir} =~ s/\.tar$//;

  chdir( $this->getWorkspaceRoot );
  my $msgs = { cmd => "tar -xf $aa_template", };
  $this->setErrorStatus(
    $this->ERR_CAT, 11,
    [ $aa_template, $this->getWorkspaceRoot ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'untaring aa_template' )
  );
}

sub filterData {
  my parallel::Component::DataAcquisition::fomaSNP::aaSeq $this = shift;
  my (@data) = @_;

  my @fData = ();
  foreach my $datum (@data) {
    my $seq         = $datum->{seq};
    my $curated_seq = $datum->{curated_seq};
    my $prot_name   = $datum->{prot_name};
    my $swiss_name  = $datum->{swiss_name};
    next
      if (
         util::Constants::EMPTY_LINE($seq)
      || util::Constants::EMPTY_LINE($curated_seq)
      || ( util::Constants::EMPTY_LINE($prot_name)
        && util::Constants::EMPTY_LINE($swiss_name) )
      ###
      ### Curated sequence must be a part of seq
      ###
      || $seq !~ /$curated_seq/
      );
    push( @fData, $datum );
  }

  return @fData;
}

sub addEntity {
  my parallel::Component::DataAcquisition::fomaSNP::aaSeq $this = shift;
  my ($datum) = @_;

  my $curated_seq = $datum->{curated_seq};
  my $ncbiacc     = $datum->{ncbiacc};
  my $prot_name   = $datum->{prot_name};
  my $seq         = $datum->{seq};
  my $swiss_name  = $datum->{swiss_name};
  ###
  ### Determine the initial prot category
  ### that will form part of the protein group tag
  ###
  my @p_names      = split( / /, $swiss_name );
  my $protCategory = $prot_name;
  my $prot2        = $p_names[0];
  if ( !util::Constants::EMPTY_LINE($prot2)
    && $protCategory ne $prot2
    && length($prot2) < 7 )
  {
    $protCategory = $prot2;
  }
  ###
  ### Determine if valid protein
  ###
  my ( $protein_valid, $prot_type ) =
    $this->_checkProteinSeq( $datum, $protCategory );
  return if ( !$protein_valid );
  ###
  ### Update prot category
  ###
  $protCategory = $prot_type if ( defined($prot_type) );
  $protCategory = uc($protCategory);
  return
    if ( util::Constants::EMPTY_LINE($protCategory)
    || length($protCategory) > 7 );
  ###
  ### Set group tag for protein and generate group data
  ###
  my $seq_len = length($curated_seq);
  $datum->{prot_cat} = $protCategory;
  my $groupData = $this->getGroup( $datum, $seq_len );
  ###
  ### Add host and strain map
  ###
  $groupData->{hosts}->addAccVal( $ncbiacc,   $datum->{orig_host} );
  $groupData->{strains}->addAccVal( $ncbiacc, $datum->{strainname} );
  ###
  ### Update the properties
  ###
  my $properties = $groupData->{properties};
  my $count      = $properties->getProperty('count');
  $count++;
  $properties->setProperty( 'count', $count );

  $properties->setProperty( 'max_seq_len', $seq_len )
    if ( $seq_len > $properties->getProperty('max_seq_len') );

  $properties->setProperty( 'prot_cat', $datum->{prot_cat} );
  ###
  ### Add the sequence data
  ###
  return if ( $groupData->{refseqs}->accDefined($ncbiacc) );
  $groupData->{refseqs}->addAccVal( $ncbiacc, $ncbiacc );
  $this->addSeqData( $groupData, $datum );
}

################################################################################

1;

__END__

=head1 NAME

aaSeq.pm

=head1 DESCRIPTION

This class defines the AA sequence acquisition for fomaSNP

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::DataAcquisition::fomaSNP::fomaSNP::aaSeq(controller, utitls, error_mgr, tools)>

This is the constructor for the class.

=cut
