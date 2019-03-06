package ncbi::MsdCombined;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use Cwd 'chdir';
use Pod::Usage;

use ncbi::ErrMsgs;

use util::Constants;

use fields qw(
  error_mgr
  ncbi_utils
  run_dir
  tools
  utils
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::MSDCOMBINED_CAT; }

################################################################################
#
#				   Private Methods
#
################################################################################

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::MsdCombined $this = shift;
  my ( $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr}  = $error_mgr;
  $this->{ncbi_utils} = $ncbi_utils;
  $this->{tools}      = $tools;
  $this->{utils}      = $utils;

  $this->{run_dir} = join( util::Constants::SLASH,
    $ncbi_utils->getDataDirectory,
    $ncbi_utils->getProperties->{datasetName}
  );

  return $this;
}

sub process {
  my ncbi::MsdCombined $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $tools      = $this->{tools};
  my $utils      = $this->{utils};
  my $cmds       = $tools->cmds;

  $cmds->createDirectory( $this->{run_dir}, 'Creating msd_combined directory',
    util::Constants::TRUE );
  chdir( $this->{run_dir} );
  ###
  ### Get the data.
  ###
  my $data = {};
  foreach my $run_type ( keys %{ $properties->{runTypes} } ) {
    my $run_dir =
      join( util::Constants::SLASH, $ncbi_utils->getDataDirectory, $run_type );
    my $sourceFile    = $properties->{sourceFile};
    my $rawFile       = $properties->{rawFile};
    my $fileSeparator = $properties->{fileSeparator};
    next if ( !-s $ncbi_utils->getSeqsOut( $run_dir, $sourceFile ) );
    $properties->{seqsOrd} = $properties->{runTypes}->{$run_type};
    foreach my $struct (
      $ncbi_utils->readResults(
        $run_dir, $sourceFile, $rawFile, $fileSeparator
      )
      )
    {
      $data->{ $struct->{gb_accession} } = $struct->{na_sequence_id};
    }
  }
  ###
  ### write the combined results
  ###
  my $file =
    join( util::Constants::SLASH, $this->{run_dir}, $properties->{naSidFile} );
  my $fh = $utils->openFile($file);
  foreach my $gb_accession ( keys %{$data} ) {
    my $na_sequence_id = $data->{$gb_accession};
    $fh->print(
      join( util::Constants::SPACE,
        $gb_accession, $na_sequence_id, $gb_accession )
        . util::Constants::NEWLINE
    );
  }
  $fh->close;
  $ncbi_utils->addReport(
    "Combined na_sids = " . ( scalar keys %{$data} ) . "\n" );
  ###
  ### Make sure file exists!
  ###
  my $msgs = { cmd => $cmds->TOUCH_CMD($file), };
  $cmds->executeCommand( $msgs, $msgs->{cmd}, 'touch na_sid file' );
  ###
  ### Save status file
  ###
  $ncbi_utils->printReport;
  $tools->setStatus( $tools->SUCCEEDED );
  $tools->saveStatus(
    join( util::Constants::SLASH, $this->{run_dir}, $properties->{statusFile} )
  );
}

################################################################################
1;

__END__

=head1 NAME

MsdCombined.pm

=head1 SYNOPSIS

  use ncbi::MsdCombined;

=head1 DESCRIPTION

Generate the na_sid file for msd processing.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::MsdCombined(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
