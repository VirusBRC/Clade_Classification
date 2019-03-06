package ncbi::Link::Daily;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use Pod::Usage;

use util::Constants;

use ncbi::ErrMsgs;

use base 'ncbi::Link';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::LINK_CAT; }

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ( $that, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  my ncbi::Link::Daily $this =
    $that->SUPER::new( 'daily', $error_mgr, $tools, $utils, $ncbi_utils );

  return $this;
}

sub linkFiles {
  my ncbi::Link::Daily $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $nc_mmdd    = $ncbi_utils->getNcMmdd;

  my $properties      = $ncbi_utils->getProperties;
  my $dailyLinkFile   = $properties->{dailyLinkFile};
  ###
  ### Only Download if a Daily File is Specified
  ###
  my $subs = $dailyLinkFile->{substitutor};
  my $file = $dailyLinkFile->{file};
  if (!util::Constants::EMPTY_LINE($subs)
      && !util::Constants::EMPTY_LINE($file)) {
    $file =~ s/$subs/$nc_mmdd/;
    my $status = $this->getFile( $file );
    return if ($status);
  }
  ###
  ### Daily File sucessfully downloaded
  ###
  $this->{data_ready_msg} = "!!!Link Daily Files READY for Processing!!!";
  $this->{data_ready}     = util::Constants::TRUE;
}

################################################################################
1;

__END__

=head1 NAME

Daily.pm

=head1 SYNOPSIS

  use ncbi::Link::Daily;

=head1 DESCRIPTION

This class defines a standard mechanism for linking daily files from ncbi
pipelines

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Link::Daily(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
