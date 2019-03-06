package parallel::Component::Move::interproscan;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'chdir';
use File::Basename;
use FileHandle;
use File::Find ();
use Pod::Usage;

use util::Constants;

use base 'parallel::Component::Move';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### for the convenience of &wanted calls,
### including -eval statements:
###
use vars qw(*FIND_NAME
  *FIND_DIR
  *FIND_PRUNE);
*FIND_NAME  = *File::Find::name;
*FIND_DIR   = *File::Find::dir;
*FIND_PRUNE = *File::Find::prune;
###
### interproscan Specific Properties from the Controller Configuration
###
sub DELETEFILE_PROP { return 'deleteFile'; }
sub ENDDATE_PROP    { return 'endDate'; }
sub STARTDATE_PROP  { return 'startDate'; }

sub INTERPROSCAN_PROPERTIES {
  return [ DELETEFILE_PROP, ENDDATE_PROP, STARTDATE_PROP, ];
}

################################################################################
#
#                               Private Methods
#
################################################################################

my @_FILES_ = ();

sub _filesWanted {
  my parallel::Component::Move::interproscan $this = shift;
  my $file_pattern = $this->makeFilePattern;
  return sub {
    my ( $dev, $ino, $mode, $nlink, $uid, $gid );

    ( ( $dev, $ino, $mode, $nlink, $uid, $gid ) = lstat($_) )
      && -f _
      && /^$file_pattern\z/s
      && push( @_FILES_, $FIND_NAME );
    }
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$$) {
  my ( $that, $controller, $utils, $error_mgr, $tools ) = @_;
  my parallel::Component::Move::interproscan $this =
    $that->SUPER::new( INTERPROSCAN_PROPERTIES, 'interproscan', $controller,
    $utils, $error_mgr, $tools );

  return $this;
}

sub move_data {
  my parallel::Component::Move::interproscan $this = shift;

  my $tools      = $this->{tools};
  my $cmds       = $tools->cmds;
  my $properties = $this->getProperties;
  $this->{error_mgr}->printHeader("Obtain Data files and Determine Delete Files");
  $this->generateComponents;
  my $aggregateSuffix       = $properties->{aggregateSuffix};
  my $aggregateDeleteSuffix = $properties->{aggregateDeleteSuffix};
  my $filesToProcess        = {};
  foreach my $sourceDir ( @{ $properties->{sourceDirectories} } ) {
    $sourceDir = $tools->setWorkspaceForProperty($sourceDir);
    $this->{error_mgr}->printMsg("source = $sourceDir");
    chdir($sourceDir);
    @_FILES_ = ();
    File::Find::find( { wanted => $this->_filesWanted }, util::Constants::DOT );
    foreach my $file (@_FILES_) {
      $this->{error_mgr}->printMsg("  file = $file");
      $file =~ s/^\.\///;
      $file = join( util::Constants::SLASH, $sourceDir, $file );
      my $filename = basename($file);
      if ( !defined( $filesToProcess->{$filename} ) ) {
        my $delete_file = $filename;
        $delete_file =~ s/\.$aggregateSuffix/\.$aggregateDeleteSuffix/;
        $filesToProcess->{$filename} = {
          sources     => [],
          delete_file => $delete_file,
        };
      }
      push( @{ $filesToProcess->{$filename}->{sources} }, $file );
    }
  }
  ###
  ### Continue in run directory
  ###
  chdir( $this->getWorkspaceRoot );
  ###
  ### Now copy data and delete contents
  ###
  $this->{error_mgr}->printHeader("Copying Data and Generating Delete Files");
  my $deleteFile = undef;
  if ( !util::Constants::EMPTY_LINE( $properties->{deleteFile} ) ) {
    $deleteFile = join( util::Constants::SLASH,
      $this->getWorkspaceRoot, $properties->{deleteFile} );
    unlink($deleteFile);
  }
  foreach my $filename ( sort keys %{$filesToProcess} ) {
    $this->{error_mgr}->printMsg("filename = $filename");
    my $struct = $filesToProcess->{$filename};
    my $data_file =
      join( util::Constants::SLASH, $this->getWorkspaceRoot, $filename );
    unlink($data_file);
    my $delete_file = undef;
    if ( defined($deleteFile) ) {
      $delete_file = $deleteFile;
    }
    else {
      $delete_file = join( util::Constants::SLASH,
        $this->getWorkspaceRoot, $struct->{delete_file} );
      unlink($delete_file);
    }
    my $msgs = { cmd => $cmds->TOUCH_CMD($data_file) };
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'creating data file' );
    $msgs = { cmd => $cmds->TOUCH_CMD($delete_file) };
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'creating delete file' );
    my $ofh = new FileHandle;
    $ofh->open( $delete_file, '>>' );
    $ofh->autoflush(util::Constants::TRUE);
    my $deleteIds = {};

    foreach my $source ( @{ $struct->{sources} } ) {
      $msgs->{cmd} = "cat $source >> $data_file";
      $cmds->executeCommand( $msgs, $msgs->{cmd}, 'copying data file' );
      my $deleteInFile =
        join( util::Constants::SLASH, dirname($source),
        $struct->{delete_file} );
      my $ifh = new FileHandle;
      $ifh->open( $deleteInFile, '<' );
      while ( !$ifh->eof ) {
        my $id = $ifh->getline;
        chomp($id);
        next if ( defined( $deleteIds->{$id} ) );
        $deleteIds->{$id} = util::Constants::EMPTY_STR;
        $ofh->print("$id\n");
      }
      $ifh->close;
    }
    $ofh->close;
  }
  ###
  ### Moving Files
  ###
  $this->{error_mgr}->printHeader("Moving Data to File Server");
  my $dataFiles   = $this->makeSshPattern;
  my $deleteFiles = undef;
  if ( util::Constants::EMPTY_LINE( $properties->{deleteFile} ) ) {
    $deleteFiles = $dataFiles;
    $deleteFiles =~ s/\.$aggregateSuffix/\.$aggregateDeleteSuffix/;
  }
  else {
    $deleteFiles = $properties->{deleteFile};
  }
  my $msgs                 = {};
  my $server               = $this->getDestinationServer;
  my $destinationDirectory = $this->getDestinationDirectory;

  $this->createRemoteDirectory;
  $msgs->{cmd} = "scp $dataFiles $server:$destinationDirectory";
  $cmds->executeCommand( $msgs, $msgs->{cmd}, 'moving data files' );
  $msgs->{cmd} = "scp $deleteFiles $server:$destinationDirectory";
  $cmds->executeCommand( $msgs, $msgs->{cmd}, 'moving delete files' );
}

################################################################################

1;

__END__

=head1 NAME

interproscan.pm

=head1 DESCRIPTION

This class defines the mechanism for moving interproscan data from run results.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Component::Move::interproscan(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
