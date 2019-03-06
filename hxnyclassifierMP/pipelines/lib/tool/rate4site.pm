package tool::rate4site;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'chdir';
use File::Basename;
use Pod::Usage;

use util::Constants;

use parallel::File::DataFiles;
use parallel::File::Rate4Site;

use base 'tool::Tool';

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Run Tool Properties
###
sub LOG4JFILE_PROP { return 'log4jFile'; }
sub R4S_PROPERTIES { return [ LOG4JFILE_PROP, ]; }

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $utils, $error_mgr, $tools ) = @_;
  my tool::rate4site $this =
    $that->SUPER::new( 'rate4site', R4S_PROPERTIES, $utils, $error_mgr,
    $tools );
  return $this;
}

sub run {
  my tool::rate4site $this = shift;

  my $properties = $this->getProperties;
  my $tools      = $this->{tools};
  my $cmds       = $tools->cmds;

  chdir( $properties->{workspaceRoot} );

  my $msgs = {
    cmd => $cmds->COPY_FILE(
      $properties->{log4jFile}, $properties->{workspaceRoot}
    ),
  };
  my $status =
    $cmds->executeCommand( $msgs, $msgs->{cmd}, 'copying log4j properties ' );
  $tools->setStatus( $tools->FAILED ) if ($status);
  return if ($status);

  my $r4sOutput =
    new parallel::File::Rate4Site( $properties->{outputFile},
    $this->{error_mgr} );

  my $stdFile       = $properties->{stdFile};
  my $stdFilePrefix = $stdFile;
  $stdFilePrefix =~ s/\.std$//;
  my $errFile       = $properties->{errFile};
  my $errFilePrefix = $errFile;
  $errFilePrefix =~ s/\.err$//;
  my $toolOptionReplacements = $properties->{toolOptionReplacements};
  my $r4sData =
    new parallel::File::DataFiles( $properties->{dataFile},
    $this->{error_mgr} );
  $status = $r4sData->readFile;
  $tools->setStatus( $tools->FAILED ) if ($status);
  return if ($status);

  foreach my $pdb ( $r4sData->getPrefixes ) {
    my $pdbFile     = $r4sData->getDataFile($pdb);
    my $pdbFileName = basename($pdbFile);
    $msgs =
      { cmd => $cmds->COPY_FILE( $pdbFile, $properties->{workspaceRoot} ), };
    $status =
      $cmds->executeCommand( $msgs, $msgs->{cmd}, 'copying pdb ($pdb) file' );
    $tools->setStatus( $tools->FAILED ) if ($status);
    return if ($status);
    my $replacementVals = {};
    foreach my $pattern ( keys %{$toolOptionReplacements} ) {
      my $property = $toolOptionReplacements->{$pattern};
      my $val      = undef;
      if   ( $property eq 'dataFile' ) { $val = $pdbFileName; }
      else                             { $val = $properties->{$property}; }
      $replacementVals->{$pattern} = $val;
    }
    $properties->{stdFile} =
      join( util::Constants::DOT, $stdFilePrefix, $pdb, 'std' );
    $properties->{errFile} =
      join( util::Constants::DOT, $errFilePrefix, $pdb, 'err' );
    my $status =
      $this->executeToolWithVals( util::Constants::EMPTY_STR,
      $replacementVals );
    $tools->setStatus( $tools->FAILED ) if ($status);
    my $file = join( util::Constants::SLASH,
      $properties->{workspaceRoot},
      join( util::Constants::DOT, $pdbFileName, 'r4s' )
    );
    my $full_file = join( util::Constants::SLASH,
      $properties->{workspaceRoot},
      join( util::Constants::DOT, $pdbFileName, 'fullLengthOnly', 'r4s' )
    );
    if ( -e $properties->{stdFile} && !-z $properties->{stdFile} ) {
      $msgs->{cmd} = $cmds->APPEND_FILE( $properties->{stdFile}, $stdFile );
      $cmds->executeCommand( $msgs, $msgs->{cmd}, 'appending standard output' );
    }
    if ( -e $properties->{errFile} && !-z $properties->{errFile} ) {
      $msgs->{cmd} = $cmds->APPEND_FILE( $properties->{errFile}, $errFile );
      $cmds->executeCommand( $msgs, $msgs->{cmd}, 'appending error output' );
    }
    else {
      ###
      ### Only write to output file if there were no errors
      ###
      $r4sOutput->addRate4Site( $pdb, $file, $full_file );
    }
  }
  $status = $r4sOutput->writeFile;
  $tools->setStatus( $tools->FAILED ) if ($status);
}

################################################################################

1;

__END__

=head1 NAME

rate4site.pm

=head1 DESCRIPTION

This class defines the runner for rate4site.

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::rate4site(controller, error_mgr, tools)>

This is the constructor for the class.

=cut
