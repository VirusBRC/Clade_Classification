package ncbi::Download;
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
  a_log
  data_ready
  data_ready_msg
  dataset
  download_files
  error_mgr
  genbank_release
  ncbi_utils
  release_file
  release_label
  repeat_lock_file
  timestamp_file
  tools
  type
  utils
  wget_log_file
  wget_status_file
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
#				Private Methods
#
################################################################################

sub _setData {
  my ncbi::Download $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $type       = $this->{type};
  ###
  ### Dataset Name, etc
  ###
  $this->{dataset}         = "influenza_" . $this->{type};
  $this->{genbank_release} = join( util::Constants::DOT,
    $ncbi_utils->getNcYyyy, $ncbi_utils->getNcMmdd, $this->{type} );
  $this->{release_label} = join( util::Constants::UNDERSCORE,
    $ncbi_utils->getNcYyyy, $ncbi_utils->getNcMmdd, $this->{type} );
  ###
  ### Files For Download
  ###
  my $DD = $ncbi_utils->getCmd("date +'%Y%m%d'");
  $this->{a_log} =
    join( util::Constants::SLASH, $ncbi_utils->getLogDirectory, "wget.log" );
  $this->{release_file} =
    join( util::Constants::SLASH, $ncbi_utils->getLogDirectory, "release" );
  $this->{repeat_lock_file} =
    join( util::Constants::SLASH, $ncbi_utils->getRunDirectory,
    ".repeat_lock" );
  $this->{timestamp_file} =
    join( util::Constants::SLASH, $ncbi_utils->getLogDirectory, "timestamp" );
  $this->{wget_log_file} =
    join( util::Constants::SLASH, $ncbi_utils->getLogDirectory, "$DD.wget" );
  $this->{wget_status_file} =
    join( util::Constants::SLASH, $ncbi_utils->getLogDirectory, "wget.status" );
}

sub _reportDataReady {
  my ncbi::Download $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $msg        = "\n\n" . $this->{data_ready_msg} . "\n\n";
  $ncbi_utils->addReport($msg);
  $ncbi_utils->printReport;
  $this->print($msg);
  $this->{error_mgr}->exitProgram( ERR_CAT, 5, [], !$this->{data_ready} );
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::Download $this = shift;
  my ( $type, $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{data_ready}     = util::Constants::FALSE;
  $this->{data_ready_msg} = "!!!Downloaded Files NOT READY for Processing!!!";
  $this->{download_files} = {};
  $this->{error_mgr}      = $error_mgr;
  $this->{ncbi_utils}     = $ncbi_utils;
  $this->{tools}          = $tools;
  $this->{type}           = $type;
  $this->{utils}          = $utils;

  $this->_setData;

  return $this;
}

sub downloadFiles {
  my ncbi::Download $this = shift;
  ########################
  ### Abstract Mehthod ###
  ########################
  $this->{error_mgr}
    ->printDebug("Abstract Method ncbi::Download::downloadFiles");
}

sub postDownload {
  my ncbi::Download $this = shift;
  ###############################
  ### Re-Implementable Method ###
  ###############################
  ###
  ### NO-OP
  ###
}

sub download {
  my ncbi::Download $this = shift;

  $this->{data_ready}     = util::Constants::FALSE;
  $this->{download_files} = {};

  my $a_log            = $this->{a_log};
  my $ncbi_utils       = $this->{ncbi_utils};
  my $utils            = $this->{utils};
  my $wget_log_file    = $this->{wget_log_file};
  my $wget_status_file = $this->{wget_status_file};

  my $properties = $ncbi_utils->getProperties;
  my $dataDir    = $ncbi_utils->getDataDirectory;

  chdir($dataDir);
  ###
  ### First process files used by both
  ###
  $this->print("\nINFO downloading files ...");
  $ncbi_utils->runCmd( "/bin/rm $a_log", "removing $a_log" ) if ( -f $a_log );
  foreach my $file ( sort keys %{ $properties->{downloadFiles} } ) {
    next
      if ( $file eq 'gene2accession.gz'
      && lc( $properties->{g2a} ) ne $ncbi_utils->YES_VAL );
    $this->getFile( $file, $properties->{downloadFiles}->{$file} );
  }
  ###
  ### Finally download specific files
  ### and report status
  ###
  $this->downloadFiles;
  $this->_reportDataReady;
  ###
  ### Check Downloaded Files
  ###
  $ncbi_utils->runCmd( "cat $a_log >> $wget_log_file",
    "cating $a_log to $wget_log_file" );
  ###
  ### Test Downloaded Files
  ###
  my $fh = $utils->openFile($wget_status_file);
  foreach my $file ( sort keys %{ $this->{download_files} } ) {
    my $status = $this->{download_files}->{$file};
    $fh->print("$file $status\n");
    if ($status) {
      $this->print("$file did not download successfully");
      next;
    }
    $this->print("test $file");
    my $cmd = undef;
    if ( $file =~ /\.gz$/ ) {
      $cmd = "gunzip -t";
    }
    elsif ( $file =~ /\.tar$/ ) {
      $cmd = "tar -tf";
    }
    next if ( !defined($cmd) );
    $ncbi_utils->runCmd( "$cmd $file", "testing $file" );
  }
  $fh->close;
  ###
  ### Post Process download
  ###
  $this->postDownload;

  $this->print("done");
}

sub recordTimestamp {
  my ncbi::Download $this = shift;

  my $ncbi_utils     = $this->{ncbi_utils};
  my $timestamp_file = $this->{timestamp_file};
  my $a_log          = $this->{a_log};
  my $release_label  = $this->{release_label};
  my $utils          = $this->{utils};

  my $dataDir = $ncbi_utils->getDataDirectory;

  chdir($dataDir);
  $this->print("\nINFO recording timestamp ...");
  foreach my $f ( "$timestamp_file.wget", "$timestamp_file.wget_new" ) {
    $ncbi_utils->runCmd( "/bin/rm $f", "removing $f" ) if ( -f $f );
    $ncbi_utils->runCmd( "touch $f", "touching $f" );
  }
  my $last_downloads = {};
  my $fh = $utils->openFile( $timestamp_file, '<', util::Constants::TRUE );
  if ( defined($fh) ) {
    while ( !$fh->eof ) {
      my $line = $fh->getline;
      chomp($line);
      next if ( $line != / download / );
      my @row       = split( / +/, $line, -1 );
      my $file      = $row[0];
      my $timestamp = join( ' ', $row[2], $row[3] );
      $last_downloads->{$file} = $timestamp;
    }
    $fh->close;
  }
  $fh = $utils->openFile( $a_log, '<' );
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    next if ( $line !~ /saved/ || $line =~ /\/\.listing/ );
    $line =~ /^(\S+ +\S+).+($dataDir\/[a-zA-Z0-9\/\.\-_]+).+$/;
    ###$line =~ /^(\S+ +\S+).+`(.+)'.+$/;    ### for formating'`
    my $timestamp = $1;
    my $file      = $2;
    $file = basename($file);
    my $stat_line =
      $ncbi_utils->getCmd("stat -c '%n %s %y download $release_label' $file");
    my @stat_row = split( / +/, $stat_line );
    my $current = join( ' ', $stat_row[2], $stat_row[3] );
    $ncbi_utils->runCmd(
      'echo "' . $stat_line . '" >> ' . "$timestamp_file.wget",
      "catting stat for $file" );
    my $last = $last_downloads->{$file};

    if ( !defined($last) ) {
      $last = "0000-00-00 00:00:00.000000000";
    }
    $ncbi_utils->runCmd(
      'echo -e "'
        . "$file $last $current "
        . $ncbi_utils->getCmd("date +'%Y-%m-%d %H:%M:%S'") . '" >> '
        . "$timestamp_file.wget_new",
      "stating $file"
    ) if ( $current gt $last );
  }
  $fh->close;
  if ( -f "$timestamp_file.wget" ) {
    $ncbi_utils->runCmd(
      'stat -c "%n %y" ' . "$timestamp_file.wget >> $timestamp_file",
      "stating $timestamp_file.wget" );
    $ncbi_utils->runCmd( "cat $timestamp_file.wget >> $timestamp_file",
      "catting $timestamp_file.wget" );
  }
  if ( -f "$timestamp_file.wget_new" ) {
    $ncbi_utils->runCmd(
      'stat -c "%n %y" '
        . "$timestamp_file.wget_new >> $timestamp_file.new_download",
      "stating $timestamp_file.wget_new"
    );
    $ncbi_utils->runCmd(
      "cat $timestamp_file.wget_new >> $timestamp_file.new_download",
      "catting $timestamp_file.wget_new" );
  }
  $this->print("done");
}

sub recordReleaseNumber {
  my ncbi::Download $this = shift;

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
  my ncbi::Download $this = shift;

  my $ncbi_utils       = $this->{ncbi_utils};
  my $release_label    = $this->{release_label};
  my $repeat_lock_file = $this->{repeat_lock_file};
  my $timestamp_file   = $this->{timestamp_file};

  $this->print("\nINFO registering job ...");
  $ncbi_utils->runCmd(
    'echo -e "'
      . "$release_label download "
      . $ncbi_utils->getCmd("date +'%Y-%m-%d %H:%M:%S'") . ' '
      . $ncbi_utils->getCmd("wc -l $timestamp_file.wget|cut -d' ' -f1") . ' '
      . $ncbi_utils->getCmd("wc -l $timestamp_file.wget_new|cut -d' ' -f1")
      . '" >> '
      . $repeat_lock_file,
    "registering job in $repeat_lock_file"
  );
  $this->print("done");
}

sub updateReport {
  my ncbi::Download $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};

  $ncbi_utils->addReport("Files downloaded:\n");
  foreach my $file ( sort keys %{ $this->{download_files} } ) {
    my $status = $this->{download_files}->{$file};
    $ncbi_utils->addReport("$file did NOT DOWNLOAD successfully\n")
      if ($status);
    $ncbi_utils->addReport( $ncbi_utils->getCmd("ls -l $file") . "\n" )
      if ( !$status );
  }
  $ncbi_utils->printReport;
}

sub getFile {
  my ncbi::Download $this = shift;
  my ( $file, $url ) = @_;

  my $status = $this->runWget($url);
  $this->{download_files}->{$file} = $status;
  return $status;
}

sub runWget {
  my ncbi::Download $this = shift;
  my ($url) = @_;

  my $a_log      = $this->{a_log};
  my $ncbi_utils = $this->{ncbi_utils};

  my $properties = $ncbi_utils->getProperties;
  my $dataDir    = $ncbi_utils->getDataDirectory;

  my $retryLimit = $properties->{retryLimit};
  my $retrySleep = $properties->{retrySleep};
  my $passwd     = $properties->{ftpPassword};
  my $user       = $properties->{ftpUser};

  my $status = undef;
  foreach my $retryNum ( 1 .. ( $retryLimit + 1 ) ) {
    $this->print("runWget (try == $retryNum):  $url");
    $status = $ncbi_utils->runCmd(
"wget -a $a_log -P $dataDir --progress=dot:mega --http-user=$user --http-passwd=$passwd -nd -nH -N $url",
      "wgetting $url",
      util::Constants::TRUE
    );
    last if ( !$status );
    sleep($retrySleep);
  }
  return $status;
}

sub print {
  my ncbi::Download $this = shift;
  my ($msg) = @_;
  print "$msg\n";
  $this->{error_mgr}->printMsg($msg);
}

sub dataReady {
  my ncbi::Download $this = shift;
  return $this->{data_ready};
}

################################################################################
1;

__END__

=head1 NAME

Download.pm

=head1 SYNOPSIS

  use ncbi::Download;

=head1 DESCRIPTION

This class defines a standard mechanism for downloading files from ncbi
for flu.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Download(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
