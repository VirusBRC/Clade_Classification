package ncbi::Download::Daily;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use Pod::Usage;

use util::Constants;

use ncbi::ErrMsgs;

use base 'ncbi::Download';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::DOWNLOAD_CAT; }

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ( $that, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  my ncbi::Download::Daily $this =
    $that->SUPER::new( 'daily', $error_mgr, $tools, $utils, $ncbi_utils );

  return $this;
}

sub downloadFiles {
  my ncbi::Download::Daily $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $nc_mmdd    = $ncbi_utils->getNcMmdd;

  my $properties        = $ncbi_utils->getProperties;
  my $dailyDownloadFile = $properties->{dailyDownloadFile};

  ###
  ### Only Download if a Daily File is Specified
  ###
  my $subs = $dailyDownloadFile->{substitutor};
  my $file = $dailyDownloadFile->{file};
  my $url  = $dailyDownloadFile->{url};

  if (!util::Constants::EMPTY_LINE($subs)
      && !util::Constants::EMPTY_LINE($file)
      && !util::Constants::EMPTY_LINE($url)) {
    $file =~ s/$subs/$nc_mmdd/;
    $url  =~ s/$subs/$nc_mmdd/;
    my $status = $this->getFile( $file, $url );
    return if ($status);
  }
  ###
  ### Daily File sucessfully downloaded
  ###
  $this->{data_ready_msg} = "!!!Downloaded Daily Files READY for Processing!!!";
  $this->{data_ready}     = util::Constants::TRUE;
}

################################################################################
1;

__END__

=head1 NAME

Daily.pm

=head1 SYNOPSIS

  use ncbi::Download::Daily;

=head1 DESCRIPTION

This class defines a standard mechanism for downloading daily files from ncbi
for flu.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Download::Daily(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
