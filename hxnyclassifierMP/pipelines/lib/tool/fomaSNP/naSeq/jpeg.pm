package tool::fomaSNP::naSeq::jpeg;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;

use tool::ErrMsgs;

use base 'tool::fomaSNP::naSeq';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return tool::ErrMsgs::FOMASNP_CAT; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $utils, $error_mgr, $tools ) = @_;

  my tool::fomaSNP::naSeq::jpeg $this =
    $that->SUPER::new( $utils, $error_mgr, $tools );

  return $this;
}

sub runData {
  my tool::fomaSNP::naSeq::jpeg $this = shift;

  my $cmds        = $this->{tools}->cmds;
  my $output_file = $this->{output_file};
  ###
  ### Test whether foma data was generated or not
  ###
  my ( $input, $output, $prefix ) = $this->prepareJPegFiles;
  if ( !-e $input || -z $input ) {
    $output_file->addOutputFile( $this->JPEG_FILE, $output );
    return;
  }

  my $cmd = join( util::Constants::SPACE,
    $this->{rscript_path}, $this->{runplot_path}, $input, $prefix,
    $this->JPEG_FILE );
  my $msgs = { cmd => $cmd, };
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 7,
    [ $input, $output, ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'running RPlot' )
  );

  $output_file->addOutputFile( $this->JPEG_FILE, $output );
}

################################################################################

1;

__END__

=head1 NAME

jpeg.pm

=head1 DESCRIPTION

This class defines the jpeg runner for NA sequence fomaSNP.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::fomaSNP::naSeq::jpeg(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
