package ncbi::Link::Monthly;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use File::Basename;
use FileHandle;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use ncbi::ErrMsgs;

use base 'ncbi::Link';

use fields qw(
  new_release
);

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
#				    Private Methods
#
################################################################################

sub _getRelease {
  my ncbi::Link::Monthly $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $utils      = $this->{utils};

  my $properties             = $ncbi_utils->getProperties;
  my $gbReleaseNumberFile    = $properties->{gbReleaseNumberFile};

  $this->{new_release} = 0;
  my $fh = $utils->openFile( $gbReleaseNumberFile, '<', util::Constants::TRUE );
  if ( defined($fh) ) {
    $this->{new_release} = int(
      $ncbi_utils->getValue(
        $fh, "Getting new GB release from $gbReleaseNumberFile"
      )
    );
  }
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ( $that, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  my ncbi::Link::Monthly $this =
    $that->SUPER::new( 'monthly', $error_mgr, $tools, $utils, $ncbi_utils );

  $this->{new_release} = undef;

  return $this;
}

sub linkFiles {
  my ncbi::Link::Monthly $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $utils      = $this->{utils};

  my $properties             = $ncbi_utils->getProperties;
  my $monthlyFilePattern     = $properties->{monthlyFilePattern};
  my $monthlyFileSubstitutor = $properties->{monthlyFileSubstitutor};
  my $monthlyFiles           = $properties->{monthlyFiles};
  my $dataDir                = $ncbi_utils->getDataDirectory;

  $this->_getRelease;
  ###
  ### Get the Files
  ###
  foreach my $html_file ( sort keys %{$monthlyFiles} ) {
    $this->print("Getting $html_file files");
    my $files  = $monthlyFiles->{$html_file};
    my $status = $this->getFile( $html_file );
    return if ($status);
    my $fh = $utils->openFile( $html_file, '<' );
    my $pattern = $monthlyFilePattern;
    $pattern =~ s/$monthlyFileSubstitutor/$files/;
    while ( !$fh->eof ) {
      my $line = $fh->getline;
      chomp($line);
      next if ( $line !~ /$pattern/ );
      my $ftp = $1;
      $ftp =~ /($files)$/;
      my $file = $1;
      $this->print("  $file");
      my $status = $this->getFile( $file );
      return if ($status);
    }
    $fh->close;
  }
  $this->{data_ready_msg} =
      "!!!New GB Release ("
    . $this->{new_release}
    . ") Ready For Monthly Processing!!!";
  $this->{data_ready} = util::Constants::TRUE;
}

################################################################################
1;

__END__

=head1 NAME

Monthly.pm

=head1 SYNOPSIS

  use ncbi::Link::Monthly;

=head1 DESCRIPTION

This class defines a standard mechanism for downloading monthly files from ncbi
for flu.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Link::Monthly(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
