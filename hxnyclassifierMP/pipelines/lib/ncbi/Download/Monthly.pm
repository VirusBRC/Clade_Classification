package ncbi::Download::Monthly;
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

use base 'ncbi::Download';

use fields qw(
  current_release
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
sub ERR_CAT { return ncbi::ErrMsgs::DOWNLOAD_CAT; }

################################################################################
#
#				    Private Methods
#
################################################################################

sub _getReleases {
  my ncbi::Download::Monthly $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $utils      = $this->{utils};

  my $properties             = $ncbi_utils->getProperties;
  my $gbReleaseNumberFile    = $properties->{gbReleaseNumberFile};
  my $newGbReleaseNumberFile = basename($gbReleaseNumberFile);

  $this->{current_release} = 0;
  my $fh = $utils->openFile( $gbReleaseNumberFile, '<', util::Constants::TRUE );
  if ( defined($fh) ) {
    $this->{current_release} = int(
      $ncbi_utils->getValue(
        $fh, "Getting current GB release from $gbReleaseNumberFile"
      )
    );
  }
  $this->{new_release} = -1;
  return if ( !-e $newGbReleaseNumberFile );
  $this->{new_release} = int(
    $ncbi_utils->getValue(
      $utils->openFile( $newGbReleaseNumberFile, '<' ),
      "Getting new GB release from $newGbReleaseNumberFile"
    )
  );
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ( $that, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  my ncbi::Download::Monthly $this =
    $that->SUPER::new( 'monthly', $error_mgr, $tools, $utils, $ncbi_utils );

  $this->{current_release} = undef;
  $this->{new_release}     = undef;

  return $this;
}

sub downloadFiles {
  my ncbi::Download::Monthly $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $utils      = $this->{utils};

  my $properties             = $ncbi_utils->getProperties;
  my $monthlyFilePattern     = $properties->{monthlyFilePattern};
  my $monthlyFileSubstitutor = $properties->{monthlyFileSubstitutor};
  my $monthlyFiles           = $properties->{monthlyFiles};
  ###
  ### Check Release
  ###
  $this->_getReleases;
  if ( $this->{new_release} <= $this->{current_release} ) {
    $this->{data_ready_msg} =
        "!!!Current GB Release ("
      . $this->{current_release}
      . ") IS A LEAST AS RECENT AS New GB Release ("
      . $this->{new_release}
      . ")\nGB Release NOT READY for Monthly Processing!!!";
    return;
  }
  ###
  ### Get the Files
  ###
  foreach my $html_file ( sort keys %{$monthlyFiles} ) {
    $this->print("Getting $html_file files");
    my $data    = $monthlyFiles->{$html_file};
    my $files   = $data->{files};
    my $url     = $data->{url};
    my $pattern = $monthlyFilePattern;
    $pattern =~ s/$monthlyFileSubstitutor/$files/;
    my $status = $this->runWget($url);
    return if ($status);
    $ncbi_utils->runCmd( "mv index.html $html_file",
      "renaming index $html_file" );
    my $fh = $utils->openFile( $html_file, '<' );

    while ( !$fh->eof ) {
      my $line = $fh->getline;
      chomp($line);
      next if ( $line !~ /$pattern/ );
      my $ftp = $1;
      $ftp =~ /($files)$/;
      my $file = $1;
      $this->print("  $file:  $ftp");
      my $status = $this->getFile( $file, $ftp );
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

sub postDownload {
  my ncbi::Download::Monthly $this = shift;

  my $ncbi_utils  = $this->{ncbi_utils};
  my $utils       = $this->{utils};
  my $new_release = $this->{new_release};

  my $properties          = $ncbi_utils->getProperties;
  my $gbReleaseNumberFile = $properties->{gbReleaseNumberFile};

  my $fh = $utils->openFile( $gbReleaseNumberFile, '>' );
  $fh->print("$new_release\n");
  $fh->close;
}

################################################################################
1;

__END__

=head1 NAME

Monthly.pm

=head1 SYNOPSIS

  use ncbi::Download::Monthly;

=head1 DESCRIPTION

This class defines a standard mechanism for downloading monthly files from ncbi
for flu.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Download::Monthly(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
