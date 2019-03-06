package ncbi::InfluenzaNa;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;

use ncbi::ErrMsgs;

use fields qw(
  error_mgr
  flu_accs
  flu_file
  ncbi_utils
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
sub ERR_CAT { return ncbi::ErrMsgs::INFLUENZANA_CAT; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _getFluAccessions {
  my ncbi::InfluenzaNa $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};

  my $file = join( util::Constants::SLASH,
    $ncbi_utils->getDataDirectory,
    $this->{flu_file}
  );
  my $fh = new FileHandle;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 1,
    [ $ncbi_utils->getDataDirectory, $this->{flu_file}, ],
    !$fh->open( $file, '<' )
  );
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    next if ( util::Constants::EMPTY_LINE($line) );
    my @comps = split( /\t/, $line );
    $this->{flu_accs}->{ $comps[0] } = util::Constants::EMPTY_STR;
  }
  $fh->close;
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::InfluenzaNa $this = shift;
  my ( $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  $this = fields::new($this) unless ref($this);

  my $properties = $ncbi_utils->getProperties;
  $this->{error_mgr}  = $error_mgr;
  $this->{flu_accs}   = {};
  $this->{flu_file}   = $properties->{influenzaSequenceFile};
  $this->{ncbi_utils} = $ncbi_utils;
  $this->{tools}      = $tools;
  $this->{utils}      = $utils;

  $this->_getFluAccessions;

  return $this;
}

sub accDefined {
  my ncbi::InfluenzaNa $this = shift;
  my ($acc) = @_;

  my $flu_accs = $this->{flu_accs};
  return ( !util::Constants::EMPTY_LINE($acc) && defined( $flu_accs->{$acc} ) )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

################################################################################
1;

__END__

=head1 NAME

InfluenzaNa.pm

=head1 SYNOPSIS

  use ncbi::InfluenzaNa;

=head1 DESCRIPTION

This class defines a standard mechanism for reading the influenza na file

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::InfluenzaNa(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
