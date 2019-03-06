package ncbi::Process;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use fields qw(
  error_mgr
  genbank
  ncbi_files
  ncbi_utils
  tools
  utils
);

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::Process $this = shift;
  my ( $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr}  = $error_mgr;
  $this->{genbank}    = undef;
  $this->{ncbi_files} = {};
  $this->{ncbi_utils} = $ncbi_utils;
  $this->{tools}      = $tools;
  $this->{utils}      = $utils;

  return $this;
}

sub setNcbiFile {
  my ncbi::Process $this = shift;
  my ($file) = @_;

  return if ( util::Constants::EMPTY_LINE($file) );
  $this->{ncbi_files}->{ getPath($file) } = util::Constants::EMPTY_STR;
}

sub ncbiFiles {
  my ncbi::Process $this = shift;

  return sort keys %{ $this->{ncbi_files} };
}

sub setGenbank {
  my ncbi::Process $this = shift;
  my ($genbank) = @_;

  $this->{genbank} = $genbank;
}

sub genbank {
  my ncbi::Process $this = shift;
  my ($genbank) = @_;

  return $this->{genbank};
}

sub processFiles {
  my ncbi::Process $this = shift;
  #######################
  ### Abstract Method ###
  #######################
  $this->{error_mgr}->printDebug("Abract Method:  ncbi::Process::processFiles");
}

sub processDeletes {
  my ncbi::Process $this = shift;
  ###############################
  ### Re-Implementable Method ###
  ###############################
  ###
  ### NO-OP
  ###
}

################################################################################
1;

__END__

=head1 NAME

Daily.pm

=head1 SYNOPSIS

  use ncbi::Daily;

=head1 DESCRIPTION

This class defines a standard mechanism for extracting sequence 
records from daily genbank data and processing them.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Daily(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
