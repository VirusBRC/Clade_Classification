package tool::Aggregate::fomaSNP;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'chdir';
use Pod::Usage;

use util::Constants;

use tool::ErrMsgs;

use parallel::File::OutputFiles;

use base 'tool::Aggregate';

use fields qw(
  files
);

################################################################################
#
#                           Static Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return tool::ErrMsgs::AGGREGATOR_CAT; }
###
### FomaSNP Specific Properties
###
sub AGGREGATEFILETYPES_PROP { return 'aggregateFileTypes'; }

sub FOMASNP_PROPERTIES { return [ AGGREGATEFILETYPES_PROP, ]; }

################################################################################
#
#                           Private Methods
#
################################################################################

sub _initializeResult {
  my tool::Aggregate::fomaSNP $this = shift;
  my ($type) = @_;

  my $data          = $this->{files}->{$type};
  my $tools         = $this->{tools};
  my $cmds          = $tools->cmds;
  my $workspaceRoot = $this->getProperties->{workspaceRoot};
  ###
  ### set the file
  ###
  my $file = join( util::Constants::SLASH, $workspaceRoot, $data->{file} );
  if ( -e $file ) {
    my $num_files = unlink($file);
    my $status    = ( $num_files != 1 );
    $this->{error_mgr}->registerError( ERR_CAT, 2, [ $file, ], $status );
    $tools->setStatus( $tools->FAILED ) if ($status);
    return $status if ($status);
  }
  my $msgs = { cmd => $cmds->TOUCH_CMD($file), };
  my $status =
    $cmds->executeCommand( $msgs, $msgs->{cmd}, "creating file = $file" );
  $this->{error_mgr}->registerError( ERR_CAT, 10, [ 'file', $file, ], $status );
  $tools->setStatus( $tools->FAILED ) if ($status);
  return $status if ($status);
  $data->{file} = $file;
  ###
  ### Optionally set the directory
  ###
  return if ( $data->{operation} ne 'tar' );
  my $dir = join( util::Constants::SLASH, $workspaceRoot, $data->{dir} );
  if ( -e $dir ) {
    my $msgs = { cmd => $cmds->RM_DIR($dir) };
    my $status =
      $cmds->executeCommand( $msgs, $msgs->{cmd}, "removing directory = $dir" );
    $this->{error_mgr}->registerError( ERR_CAT, 2, [ $dir, ], $status );
    $tools->setStatus( $tools->FAILED ) if ($status);
    return $status if ($status);
  }
  $msgs = { cmd => $cmds->MK_DIR($dir), };
  $cmds->executeCommand( $msgs, $msgs->{cmd}, "creating directory = $dir" );
  $this->{error_mgr}->registerError( ERR_CAT, 10, [ 'dir', $dir, ], $status );
  $tools->setStatus( $tools->FAILED ) if ($status);
  return $status if ($status);
  $data->{dir} = $dir;
  return util::Constants::FALSE;
}

sub _addData {
  my tool::Aggregate::fomaSNP $this = shift;
  my ( $type, $output ) = @_;

  my $status = util::Constants::FALSE;

  my $data  = $this->{files}->{$type};
  my $tools = $this->{tools};
  my $cmds  = $tools->cmds;

  my $file = $output->getOutputFile($type);
  $this->{error_mgr}->printMsg("Processing File ($type) = $file");
  $this->{error_mgr}->printMsg("  Skipping file since it does NOT EXIST")
    if ( util::Constants::EMPTY_LINE($file) || !-e $file );
  return $status if ( util::Constants::EMPTY_LINE($file) || !-e $file );
  if ( $data->{operation} eq 'append' ) {
    my $msgs = { cmd => $cmds->APPEND_FILE( $file, $data->{file} ) };
    $status = $cmds->executeCommand( $msgs, $msgs->{cmd}, 'appending content' );
    $this->{error_mgr}
      ->registerError( ERR_CAT, 13, [ $data->{file}, $file, ], $status );
  }
  elsif ( $data->{operation} eq 'tar' ) {
    my $msgs = { cmd => $cmds->COPY_FILE( $file, $data->{dir} ) };
    $status = $cmds->executeCommand( $msgs, $msgs->{cmd}, 'copying file' );
    $this->{error_mgr}
      ->registerError( ERR_CAT, 12, [ $data->{dir}, $file, ], $status );
  }
  $tools->setStatus( $tools->FAILED ) if ($status);
  return $status;
}

################################################################################
#
#                           Public Methods
#
################################################################################

sub new($$$$) {
  my ( $that, $utils, $error_mgr, $tools ) = @_;
  my tool::Aggregate::fomaSNP $this =
    $that->SUPER::new( 'fomaSNP', FOMASNP_PROPERTIES, $utils, $error_mgr,
    $tools );

  my $properties = $this->getProperties;
  $this->{files} = { %{ $properties->{aggregateFileTypes} } };

  return $this;
}

sub initializeAggregator {
  my tool::Aggregate::fomaSNP $this = shift;

  foreach my $type ( keys %{ $this->{files} } ) {
    my $status = $this->_initializeResult($type);
    return $status if ($status);
  }
  return $this->initializeOutputFile( $this->getOutputFile );
}

sub postProcess {
  my tool::Aggregate::fomaSNP $this = shift;

  my $tools         = $this->{tools};
  my $cmds          = $tools->cmds;
  my $workspaceRoot = $this->getProperties->{workspaceRoot};

  my $output =
    new parallel::File::OutputFiles( $this->getOutputFile, $this->{error_mgr} );

  foreach my $type ( keys %{ $this->{files} } ) {
    my $data = $this->{files}->{$type};
    $output->addOutputFile( $type, $data->{file} );
    next if ( $data->{operation} ne 'tar' );
    chdir( $data->{dir} );
    my $msgs = { cmd => 'tar czf ' . $data->{file} . ' *.' . $type };
    my $status =
      $cmds->executeCommand( $msgs, $msgs->{cmd}, 'tar gzipping files' );
    $this->{error_mgr}
      ->registerError( ERR_CAT, 14, [ $data->{dir}, $type, ], $status );
    $tools->setStatus( $tools->FAILED ) if ($status);
    chdir($workspaceRoot);
    return if ($status);
    $msgs->{cmd} = $cmds->RM_DIR( $data->{dir} );
    $status =
      $cmds->executeCommand( $msgs, $msgs->{cmd}, 'removing directory' );
    $this->{error_mgr}
      ->registerError( ERR_CAT, 16, [ $data->{dir}, $type, ], $status );
    $tools->setStatus( $tools->FAILED ) if ($status);
    return if ($status);
  }
  my $status = $output->writeFile(util::Constants::TRUE);
  $this->{error_mgr}
    ->registerError( ERR_CAT, 11, [ $this->getOutputFile ], $status );
  $tools->setStatus( $tools->FAILED ) if ($status);
}

sub aggregateFile {
  my tool::Aggregate::fomaSNP $this = shift;
  my ($dataFile) = @_;

  my $tools = $this->{tools};

  my $output = new parallel::File::OutputFiles( $dataFile, $this->{error_mgr} );
  if ( -e $dataFile && !-z $dataFile ) {
    my $status = $output->readFile;
    $this->{error_mgr}->registerError( ERR_CAT, 15, [ $dataFile, ], $status );
    $tools->setStatus( $tools->FAILED ) if ($status);
    return $status if ($status);
  }
  foreach my $type ( keys %{ $this->{files} } ) {
    my $status = $this->_addData( $type, $output );
    return $status if ($status);
  }
  return util::Constants::FALSE;
}

################################################################################

1;

__END__

=head1 NAME

fomaSNP.pm

=head1 DESCRIPTION

This concrete class class defines the aggregator for fomaSNP

=head1 STATIC CONSTANTS


=head1 METHODS

The following methods are exported by this class.

=head2 B<new tool::Aggregate::fomaSNP(utils, error_mgr, tools)>

This is the constructor for the class.

=cut
