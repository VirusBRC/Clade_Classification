#!/usr/bin/perl
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  processGenbank.pl
#
# Description:  This is the generalized Genbank processor for flu
#               and non-flu data.
#
# Assumptions:
#
######################################################################

################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Carp qw(cluck);
use Cwd 'chdir';
use FileHandle;
use Getopt::Std;
use Pod::Usage;

use util::Constants;
use util::ErrMgr;
use util::Tools;

use parallel::Utils;

use ncbi::Utils;

###############################################################################
#
#				Signal Handlers
#
################################################################################

$SIG{HUP}  = 'signalHandler';
$SIG{INT}  = 'signalHandler';
$SIG{TERM} = 'signalHandler';

################################################################################
#
#				   Error and Message Management
#
################################################################################

my $error_mgr = new util::ErrMgr(ncbi::ErrMsgs::ERROR_HEADER);
my $tools     = new util::Tools( $error_mgr, [ 'parallel', 'ncbi', ] );
my $utils     = new parallel::Utils( $error_mgr, $tools );

################################################################################
#
#			    Setup std and err
#
################################################################################

STDERR->autoflush(util::Constants::TRUE);    ### Make unbuffered
STDOUT->autoflush(util::Constants::TRUE);    ### Make unbuffered
select STDOUT;

################################################################################
#
#				Parameter Setup
#
################################################################################
###
### Set Context
###
my $property_names = [];
my $ncbiUtils = new ncbi::Utils( $property_names, $error_mgr, $tools, $utils );

################################################################################
#
#				Main Program
#
################################################################################
###
### Set the run directory
###
chdir( $ncbiUtils->getRunDirectory );
###
### Get Processor
###
my $properties = $ncbiUtils->getProperties;
my $genbankObj =
  $ncbiUtils->getObject( join( '::', 'ncbi', $properties->{className} ) );
###
### Process Sequences
###
$genbankObj->process;

################################################################################
#
#				Epiplogue
#
################################################################################

$tools->closeLogging;
$tools->terminate;

################################################################################
#
#				Signal Handler
#
################################################################################

sub signalHandler {
  my $signal = shift;
  cluck $signal;
  my $print_prefix = 'ERROR(signalHandler):  ';
  eval {
    print STDOUT "\n\n", $print_prefix . "SIGNAL = $signal\n",
      $print_prefix . "NAME   = ";
    if ( $signal eq 'HUP' ) {
      print STDOUT "SIGHUP\n";
    }
    elsif ( $signal eq 'INT' ) {
      print STDOUT "SIGINT\n";
    }
    elsif ( $signal eq 'TERM' ) {
      print STDOUT "SIGTERM\n";
    }
    elsif ( $signal eq '__DIE__' ) {
      print STDOUT "__DIE__\n";
    }
    print STDOUT $print_prefix . "End-Of-signalHandler, POSIX EXIT CODE = 2\n";
    POSIX::_exit(2);
  };
}

__END__

=head1 NAME

processGenbank.pl

=head1 SYNOPSIS

   processGenbank.pl
     -P config_params_module -M (yes|no) -R reportLog -t YYYYMMDD -T databaseName

This is the generalized Genbank processor for flu and non-flu data.

=cut
