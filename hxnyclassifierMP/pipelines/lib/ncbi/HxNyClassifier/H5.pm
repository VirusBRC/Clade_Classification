package ncbi::HxNyClassifier::H5;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;
use Pod::Usage;

use base 'ncbi::HxNyClassifier';

use fields qw(
  post_mapping
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### File types
###
sub POST_LOOKUP_TYPE { return 'post.lookup'; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _readPostProcessingMapping {
  my ncbi::HxNyClassifier::H5 $this = shift;

  return if ( scalar keys %{ $this->{post_mapping} } > 0 );

  my $utils = $this->{utils};
  my $fh = $utils->openFile( $this->{profile}->{&POST_LOOKUP_TYPE}, '<' );
  $this->{post_mapping} = {};
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    next if ( util::Constants::EMPTY_LINE($line) );
    my ( $clade, $post_clade ) = split( /\t/, $line );
    $this->{post_mapping}->{$clade} = $post_clade;
  }
  $fh->close;
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ( $that, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  my ncbi::HxNyClassifier::H5 $this =
    $that->SUPER::new( $error_mgr, $tools, $utils, $ncbi_utils );

  $this->{post_mapping} = {};

  return $this;
}

sub postProcessClade {
  my ncbi::HxNyClassifier::H5 $this = shift;
  my ( $struct, $clade ) = @_;

  $this->_readPostProcessingMapping;
  my $post_mapping = $this->{post_mapping};
  if ( defined( $post_mapping->{$clade} ) ) {
    $struct->{hxny_clade} = $post_mapping->{$clade};
  }
  else {
    $struct->{hxny_clade} = $clade;
  }
}

################################################################################
1;

__END__

=head1 NAME

H5.pm

=head1 SYNOPSIS

  use ncbi::HxNyClassifier::H5;

=head1 DESCRIPTION

The H5 classifier.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::HxNyClassifier::H5(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
