package parallel::File::OutputFiles;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;

use fields qw(
  error_mgr
  output_file
  output_files
  completed
);

################################################################################
#
#			            Class Constants
#
################################################################################
###
### File Statuses
###
sub COMPLETED_LINE  { return 'COMPLETED'; }
sub FILE_EXISTS     { return 'EXISTS'; }
sub FILE_NOT_EXISTS { return 'NOT EXISTS'; }

################################################################################
#
#			            Public Methods
#
################################################################################

sub new {
  my parallel::File::OutputFiles $this = shift;
  my ( $file, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr}    = $error_mgr;
  $this->{output_file}  = $file;
  $this->{output_files} = {};
  $this->{completed}    = util::Constants::FALSE;

  return $this;
}

sub getOutputFilesFile {
  my parallel::File::OutputFiles $this = shift;
  return $this->{output_file};
}

sub getCompleted {
  my parallel::File::OutputFiles $this = shift;
  return $this->{completed};
}

sub readFile {
  my parallel::File::OutputFiles $this = shift;

  $this->{output_files} = {};
  my $outputFilesFile = $this->{output_file};
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($outputFilesFile) );
  my $outputFiles = $this->{output_files};
  my $fh          = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $outputFilesFile, '<' ) );
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    if ( $line eq COMPLETED_LINE ) {
      $this->{completed} = util::Constants::TRUE;
      last;
    }
    my ( $prefix, $file, $status ) = split( /\t/, $line );
    next
      if ( util::Constants::EMPTY_LINE($prefix)
      || util::Constants::EMPTY_LINE($file)
      || util::Constants::EMPTY_LINE($status)
      || ( $status ne FILE_EXISTS && $status ne FILE_NOT_EXISTS ) );
    $outputFiles->{$prefix} = {
      file   => $file,
      status => $status,
    };
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub writeFile {
  my parallel::File::OutputFiles $this = shift;
  my ($completed) = @_;

  $completed =
    ( !util::Constants::EMPTY_LINE($completed) && $completed )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  my $outputFiles     = $this->{output_files};
  my $outputFilesFile = $this->{output_file};
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($outputFilesFile) );
  my $fh = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $outputFilesFile, '>' ) );

  foreach my $prefix ( sort keys %{$outputFiles} ) {
    my $data = $outputFiles->{$prefix};
    $fh->print(
      join( util::Constants::TAB, $prefix, $data->{file}, $data->{status} )
        . "\n" );
  }
  if ($completed) {
    $this->{completed} = util::Constants::TRUE;
    $fh->print( COMPLETED_LINE . "\n" );
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub writeOutputFile {
  my parallel::File::OutputFiles $this = shift;
  my ( $pidInfo, $completed ) = @_;

  my $prefix      = $pidInfo->getFilePrefix;
  my $file        = $pidInfo->getOutputFile;
  my $outputFiles = $this->{output_files};
  return util::Constants::FALSE if ( !defined($prefix) );
  my $outputFilesFile = $this->{output_file};
  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE($outputFilesFile) );
  my $fh = new FileHandle;
  return util::Constants::TRUE if ( !$fh->open( $outputFilesFile, '>>' ) );
  my $fileStatus = FILE_EXISTS;
  if ( !-e $file || -z $file ) { $fileStatus = FILE_NOT_EXISTS; }
  $fh->print(
    join( util::Constants::TAB, $prefix, $file, $fileStatus ) . "\n" );
  $outputFiles->{$prefix} = {
    file   => $file,
    status => $fileStatus,
  };

  if ($completed) {
    $this->{completed} = util::Constants::TRUE;
    $fh->print( COMPLETED_LINE . "\n" );
  }
  $fh->close;
  return util::Constants::FALSE;
}

sub addOutputFile {
  my parallel::File::OutputFiles $this = shift;
  my ( $prefix, $file ) = @_;

  my $outputFiles = $this->{output_files};
  $outputFiles->{$prefix} = {
    file   => $file,
    status => ( -e $file ) ? FILE_EXISTS : FILE_NOT_EXISTS,
  };
}

sub getPrefixes {
  my parallel::File::OutputFiles $this = shift;

  return sort keys %{ $this->{output_files} };
}

sub getOutputFile {
  my parallel::File::OutputFiles $this = shift;
  my ($prefix) = @_;

  my $file_data = $this->{output_files}->{$prefix};
  return undef if ( !defined($file_data) );
  return $file_data->{file};
}

sub getOutputFileStatus {
  my parallel::File::OutputFiles $this = shift;
  my ($prefix) = @_;

  my $file_data = $this->{output_files}->{$prefix};
  return undef if ( !defined($file_data) );
  return $file_data->{status};
}

################################################################################

1;

__END__

=head1 NAME

OutputFiles.pm

=head1 DESCRIPTION

This class is the container for output files generated.

=head1 METHODS


=cut
