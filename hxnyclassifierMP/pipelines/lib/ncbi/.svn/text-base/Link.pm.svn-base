package ncbi::Link;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use Cwd 'chdir';
use File::Basename;
use FileHandle;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use ncbi::ErrMsgs;

use fields qw(
  data_ready
  data_ready_msg
  dataset
  linked_files
  error_mgr
  genbank_release
  ncbi_utils
  release_file
  release_label
  repeat_lock_file
  tools
  type
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
sub ERR_CAT { return ncbi::ErrMsgs::LINK_CAT; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _setData {
  my ncbi::Link $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $type       = $this->{type};
  ###
  ### Dataset Name, etc
  ###
  $this->{dataset}         = "data_" . $this->{type};
  $this->{genbank_release} = join( util::Constants::DOT,
    $ncbi_utils->getNcYyyy, $ncbi_utils->getNcMmdd, $this->{type} );
  $this->{release_label} = join( util::Constants::UNDERSCORE,
    $ncbi_utils->getNcYyyy, $ncbi_utils->getNcMmdd, $this->{type} );
  ###
  ### Files For Linkage
  ###
  my $DD = $ncbi_utils->getCmd("date +'%Y%m%d'");
  $this->{release_file} =
    join( util::Constants::SLASH, $ncbi_utils->getLogDirectory, "release" );
  $this->{repeat_lock_file} =
    join( util::Constants::SLASH, $ncbi_utils->getRunDirectory,
    ".repeat_lock" );
}

sub _reportDataReady {
  my ncbi::Link $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $msg        = "\n\n" . $this->{data_ready_msg} . "\n\n";
  $ncbi_utils->addReport($msg);
  $ncbi_utils->printReport;
  $this->print($msg);
  $this->{error_mgr}->exitProgram( ERR_CAT, 5, [], !$this->{data_ready} );
}

sub _getSourceDirectory {
  my ncbi::Link $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $nc_mmdd    = $ncbi_utils->getNcMmdd;
  my $nc_yyyy    = $ncbi_utils->getNcYyyy;

  my $fullDate = join(util::Constants::EMPTY_STR, $nc_yyyy, $nc_mmdd);
  if ($ncbi_utils->isMonthly) {
    $fullDate = join(util::Constants::DOT, $fullDate, 'monthly');
  }
  my $properties      = $ncbi_utils->getProperties;
  my $sourceDirectory = $properties->{sourceDirectory};

  my $subs = $sourceDirectory->{substitutor};
  my $dir  = $sourceDirectory->{dir};
  if (!util::Constants::EMPTY_LINE($subs)
      && !util::Constants::EMPTY_LINE($dir)) {
    $dir  =~ s/$subs/$fullDate/;
  }
  return $dir;
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::Link $this = shift;
  my ( $type, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{data_ready}     = util::Constants::FALSE;
  $this->{data_ready_msg} = "!!!Linked Files NOT READY for Processing!!!";
  $this->{linked_files} = {};
  $this->{error_mgr}      = $error_mgr;
  $this->{ncbi_utils}     = $ncbi_utils;
  $this->{tools}          = $tools;
  $this->{type}           = $type;
  $this->{utils}          = $utils;

  $this->_setData;

  return $this;
}

sub linkFiles {
  my ncbi::Link $this = shift;
  ########################
  ### Abstract Method ###
  ########################
  $this->{error_mgr}
    ->printDebug("Abstract Method ncbi::Link::linkFiles");
}

sub postLink {
  my ncbi::Link $this = shift;
  ###############################
  ### Re-Implementable Method ###
  ###############################
  ###
  ### NO-OP
  ###
}

sub link {
  my ncbi::Link $this = shift;

  $this->{data_ready}   = util::Constants::FALSE;
  $this->{linked_files} = {};

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $dataDir    = $ncbi_utils->getDataDirectory;

  chdir($dataDir);
  ###
  ### First process files used by both
  ###
  $this->print("\nINFO linking files ...");
  foreach my $file ( sort keys %{ $properties->{linkFiles} } ) {
    $this->getFile( $file );
  }
  ###
  ### Finally link specific files
  ### and report status
  ###
  $this->linkFiles;
  $this->_reportDataReady;
  ###
  ### Post Process link
  ###
  $this->postLink;

  $this->print("done");
}

sub recordReleaseNumber {
  my ncbi::Link $this = shift;

  my $dataset         = $this->{dataset};
  my $genbank_release = $this->{genbank_release};
  my $ncbi_utils      = $this->{ncbi_utils};
  my $release_file    = $this->{release_file};
  my $release_label   = $this->{release_label};

  $this->print("\nINFO recording release number ...");
  $ncbi_utils->runCmd(
    'echo -e "'
      . "$release_label $dataset "
      . $ncbi_utils->getCmd("date +'%Y-%m-%d %H:%M:%S'")
      . " genbank_release $genbank_release " . '" >> '
      . $release_file,
    "writing release number to $release_file"
  );
  $this->print("done");
}

sub registerJob {
  my ncbi::Link $this = shift;

  my $ncbi_utils       = $this->{ncbi_utils};
  my $release_label    = $this->{release_label};
  my $repeat_lock_file = $this->{repeat_lock_file};

  $this->print("\nINFO registering job ...");
  $ncbi_utils->runCmd(
    'echo -e "'
      . "$release_label link "
      . $ncbi_utils->getCmd("date +'%Y-%m-%d %H:%M:%S'") . ' '
      . '" >> '
      . $repeat_lock_file,
    "registering job in $repeat_lock_file"
  );
  $this->print("done");
}

sub updateReport {
  my ncbi::Link $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};

  $ncbi_utils->addReport("Files linked:\n");
  foreach my $file ( sort keys %{ $this->{linked_files} } ) {
    my $status = $this->{linked_files}->{$file};
    $ncbi_utils->addReport("$file did NOT LINKED successfully\n")
      if ($status);
    $ncbi_utils->addReport( $ncbi_utils->getCmd("ls -l $file") . "\n" )
      if ( !$status );
  }
  $ncbi_utils->printReport;
}

sub getFile {
  my ncbi::Link $this = shift;
  my ( $file ) = @_;

  my $status = $this->linkFile($file);
  $this->{linked_files}->{$file} = $status;
  return $status;
}

sub linkFile {
  my ncbi::Link $this = shift;
  my ($file) = @_;

  my $cmds = $this->{tools}->cmds;

  my $status = util::Constants::TRUE;
  my $source = $this->_getSourceDirectory;
  if (util::Constants::EMPTY_LINE($source)) {
      return $status;
  }
  my $source_file = join(util::Constants::SLASH, $source, $file);
  if ( -e $source_file ) {
    my $msgs = {};
    $msgs->{cmd} = $cmds->LINK_FILE($source_file, util::Constants::DOT);
    $status = $cmds->executeCommand( $msgs, $msgs->{cmd}, $source_file );
  }
  return $status;
}

sub print {
  my ncbi::Link $this = shift;
  my ($msg) = @_;
  print "$msg\n";
  $this->{error_mgr}->printMsg($msg);
}

sub dataReady {
  my ncbi::Link $this = shift;
  return $this->{data_ready};
}

################################################################################
1;

__END__

=head1 NAME

Link.pm

=head1 SYNOPSIS

  use ncbi::Link;

=head1 DESCRIPTION

This class defines a standard mechanism for linking files files from one
download to another.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Link(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
