package tool::fomaSNP::naSeq;
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
  min_cds_size
  muscle_cutoff
  pandemic
  rscript_path
  run_na
  run_snp
  runplot_path
  seq_len
  special_snp_start
  special_snp_stop
  terminal_codons
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
sub MINCDSSIZE_PROP      { return 'minCDSsize'; }
sub MUSCLECUTOFF_PROP    { return 'muscleCutoff'; }
sub PANDEMIC_PROP        { return 'pandemic'; }
sub RSCRIPTPATH_PROP     { return 'rScriptPath'; }
sub RUNNA_PROP           { return 'runNa'; }
sub RUNPLOTPATH_PROP     { return 'runPlotPath'; }
sub RUNSNP_PROP          { return 'runSnp'; }
sub SEQLEN_PROP          { return 'seqLen'; }
sub SPECIALSNPSTART_PROP { return 'specialSnpStart'; }
sub SPECIALSNPSTOP_PROP  { return 'specialSnpStop'; }
sub TERMINALCODONS_PROP  { return 'terminalCodons'; }

sub NASEQ_PROPERTIES {
  return [
    MINCDSSIZE_PROP,     MUSCLECUTOFF_PROP, PANDEMIC_PROP,
    RSCRIPTPATH_PROP,    RUNNA_PROP,        RUNPLOTPATH_PROP,
    RUNSNP_PROP,         SEQLEN_PROP,       SPECIALSNPSTART_PROP,
    SPECIALSNPSTOP_PROP, TERMINALCODONS_PROP,
  ];
}
###
### Output Files
###
sub JPEG_FILE        { return 'jpg'; }
sub SNP_GENBANK_FILE { return 'snp.genbank'; }
sub SNP_REFSEQ_FILE  { return 'snp.refseq'; }
sub TXT_FILE         { return 'txt'; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $utils, $error_mgr, $tools ) = @_;

  my tool::fomaSNP::naSeq $this =
    $that->SUPER::new( NASEQ_PROPERTIES, $utils, $error_mgr, $tools );

  my $lproperties = $this->getLocalDataProperties;

  $this->{min_cds_size}      = $lproperties->{minCDSsize};
  $this->{muscle_cutoff}     = $lproperties->{muscleCutoff};
  $this->{pandemic}          = $lproperties->{pandemic};
  $this->{rscript_path}      = $lproperties->{rScriptPath};
  $this->{run_na}            = $lproperties->{runNa};
  $this->{run_snp}           = $lproperties->{runSnp};
  $this->{runplot_path}      = $lproperties->{runPlotPath};
  $this->{seq_len}           = $lproperties->{seqLen};
  $this->{special_snp_start} = $lproperties->{specialSnpStart};
  $this->{special_snp_stop}  = $lproperties->{specialSnpStop};
  $this->{terminal_codons}   = $lproperties->{terminalCodons};

  return $this;
}

sub createFile {
  my tool::fomaSNP::naSeq $this = shift;
  my ($suffix) = @_;

  my $host = $this->{host};
  $host =~ s/'//g;    ###'

  return join( util::Constants::SLASH,
    $this->getProperties->{workspaceRoot},
    join( util::Constants::DOT,
      join( util::Constants::UNDERSCORE,
        $this->{subtype}, $host, 'Segment' . $this->{segment}
      ),
      $suffix
    )
  );
}

sub prepareJPegFiles {
  my tool::fomaSNP::naSeq $this = shift;

  my $jpeg_file = $this->createFile(JPEG_FILE);
  my $prefix    = $jpeg_file;
  my $suffix    = JPEG_FILE;
  $prefix =~ s/\.$suffix$//;
  my $input = join( util::Constants::DOT, $prefix, TXT_FILE );
  return ( $input, $jpeg_file, $prefix );
}

################################################################################

1;

__END__

=head1 NAME

naSeq.pm

=head1 DESCRIPTION

This class defines the runner for NA sequence fomaSNP.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::fomaSNP::naSeq(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
