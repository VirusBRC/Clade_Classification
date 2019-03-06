package ncbi::Utils;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use Cwd 'chdir';
use File::Find ();
use FileHandle;
use Getopt::Std;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;
use util::Table;
use util::TableData;

use ncbi::ErrMsgs;

use vars qw(
  $opt_A
  $opt_G
  $opt_M
  $opt_P
  $opt_R
  $opt_T
  $opt_o
  $opt_t
  $opt_p
);
getopts("A:G:M:P:R:T:o:t:p:");

use fields qw(
  data_directory
  error_mgr
  file_pattern
  log_directory
  log_file
  monthly
  nc_mmdd
  nc_yyyy
  properties
  report_log
  report_str
  run_directory
  special_props
  tools
  utils
);

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
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::UTILS_CAT; }
###
### Special Property Value
###
sub ALL_VAL     { return 'all'; }
sub NO_FILE     { return '__NO_FILE__'; }
sub NO_VAL      { return 'no'; }
sub PENDING_VAL { return 'pending'; }
sub YES_VAL     { return 'yes'; }
###
### Special Properties
###
sub SPECIAL_PROPERTIES {
  return {
    accsFile => {
      option   => 'A',
      patterns => undef,
      default  => NO_FILE,
    },
    g2a => {
      option   => 'G',
      patterns => undef,
      default  => NO_VAL,
    },
    monthly => {
      option   => 'M',
      patterns => undef,
      default  => undef,
    },
    reportLog => {
      option   => 'R',
      patterns => undef,
      default  => undef,
    },
    databaseName => {
      option   => 'T',
      patterns => undef,
      default  => undef,
    },
    todayDayDate => {
      option => 't',
      patterns =>
        [ [ '^(\d\d\d\d)(\d\d)(\d\d)$', [ 'year', 'month', 'day', ], ], ],
      default => undef,
    },
    output => {
      option   => 'o',
      patterns => undef,
      default  => ALL_VAL,
    },
    process => {
      option   => 'p',
      patterns => undef,
      default  => ALL_VAL,
    },
  };
}

sub PROPERTY_COL { return 'Property'; }
sub OPTION_COL   { return 'Option'; }
sub VALUE_COL    { return 'Value'; }

sub MSG_COLS { return ( PROPERTY_COL, OPTION_COL, VALUE_COL ); }
###
### Processing Class Types
###
sub DOWNLOAD_CLASS_TYPE { return 'Download'; }
sub LINK_CLASS_TYPE     { return 'Link'; }
sub PROCESS_CLASS_TYPE  { return 'Process'; }
###
### Genbank File Suffix
###
sub GENBANK_RECORD_SUFFIX { return 'gbk'; }
###
### Processing Result File
###
sub OUTPUT_TYPE { return 'output'; }
sub SEQS_TYPE   { return 'seqs'; }

sub SEQ_OUT {
  return join( util::Constants::DOT, SEQS_TYPE, OUTPUT_TYPE );
}

################################################################################
#
#				Private Methods
#
################################################################################

my @_FILES_ = ();

sub _filesWanted {
  my ncbi::Utils $this = shift;

  my $file_pattern = $this->{file_pattern};

  return sub {
    my ( $dev, $ino, $mode, $nlink, $uid, $gid );

    ( ( $dev, $ino, $mode, $nlink, $uid, $gid ) = lstat($_) )
      && -f _
      && /^$file_pattern\z/s
      && push( @_FILES_, $FIND_NAME );
    }
}

sub _setSpecialProperties {
  my ncbi::Utils $this = shift;

  $this->{special_props} = {};

  my $properties = $this->getProperties;
  my $tools      = $this->{tools};
  my $utils      = $this->{utils};

  my $specialProperties = SPECIAL_PROPERTIES;
  foreach my $property ( sort keys %{$specialProperties} ) {
    my $option   = $specialProperties->{$property}->{option};
    my $default  = $specialProperties->{$property}->{default};
    my $patterns = $specialProperties->{$property}->{patterns};
    my $value    = undef;
    my $eval_str = '$value = $opt_' . $option;
    eval $eval_str;
    my $status = $@;
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 3,
      [ $property, '$opt_' . $option, ],
      defined($status) && $status
    );
    if ( util::Constants::EMPTY_LINE($value) ) { $value = $default; }

    if ( !util::Constants::EMPTY_LINE($value) ) {
      $properties->{$property} = $value;
      $tools->setProperty( $property, $value );
    }
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 1,
      [ $property, ],
      util::Constants::EMPTY_LINE( $properties->{$property} )
    );
    next if ( !defined($patterns) );
    ###
    ### The properties with sub-structure
    ###
    $this->{special_props}->{$property} =
      $utils->getAllPatternInfo( $properties->{$property}, $patterns );
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 2,
      [ $property, $properties->{$property}, ],
      scalar keys %{ $this->{special_props}->{$property} } == 0
    );
  }
}

sub _setDirectoriesAndFiles {
  my ncbi::Utils $this = shift;

  my $properties = $this->getProperties;
  my $tools      = $this->{tools};

  $this->{run_directory} = join( util::Constants::SLASH,
    $properties->{workspaceRoot},
    $properties->{todayDayDate}
  );

  if ( lc( $properties->{monthly} ) eq YES_VAL ) {
    $this->{monthly} = util::Constants::TRUE;
    $this->{run_directory} .= util::Constants::DOT . 'monthly';
  }
  $this->{data_directory} =
    join( util::Constants::SLASH, $this->{run_directory}, 'data' );
  $this->{log_directory} =
    join( util::Constants::SLASH, $this->{run_directory}, 'log' );
  ###
  ### Create these directories as necessary but do not overwrite
  ###
  $tools->cmds->createDirectory( $this->{data_directory},
    'Creating data directory as necessary' );
  $tools->cmds->createDirectory( $this->{log_directory},
    'Creating log directory as necessary' );

  $this->{report_log} = getPath( $properties->{reportLog} );

  $this->{log_file} = join( util::Constants::SLASH,
    $this->{log_directory},
    join( util::Constants::DOT,
      $tools->scriptName,          $properties->{ $tools->LOG_INFIX_PROP },
      'P',                         $properties->{process},
      'O',                         $properties->{output},
      $properties->{todayDayDate}, 'log'
    )
  );
}

sub _setDates {
  my ncbi::Utils $this = shift;

  my $date = $this->getSpecialValue('todayDayDate');
  $this->{nc_mmdd} = $date->{month} . $date->{day};
  $this->{nc_yyyy} = $date->{year};
}

sub _printSpecialProperties {
  my ncbi::Utils $this = shift;

  my $properties = $this->getProperties;
  my $tools      = $this->{tools};

  my $specialProperties = SPECIAL_PROPERTIES;
  my @ord               = MSG_COLS;

  my %cols = ();
  foreach my $col (@ord) { $cols{$col} = $col; }
  my $table = new util::Table( $this->{error_mgr}, %cols );
  ###
  ### Set Configuration
  ###
  $table->setColumnOrder(@ord);
  $table->setRowOrder( 'sub {$a->{'
      . $tools->PROPERTY_COL
      . '} cmp $b->{'
      . $tools->PROPERTY_COL
      . '};}' );
  $table->setInHeader(util::Constants::TRUE);
  foreach my $col (@ord) {
    $table->setColumnJustification( $col, util::Table::LEFT_JUSTIFY );
  }
  my @data = ();
  foreach my $property ( sort keys %{$specialProperties} ) {
    my $struct = {
      &PROPERTY_COL => $property,
      &OPTION_COL   => $specialProperties->{$property}->{option},
      &VALUE_COL    => $properties->{$property},
    };
    push( @data, $struct );
  }
  $table->setData(@data);
  ###
  ### Generate Table
  ###
  $table->generateTable('Special Properties');
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::Utils $this = shift;
  my ( $property_names, $error_mgr, $tools, $utils ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr}     = $error_mgr;
  $this->{monthly}       = util::Constants::FALSE;
  $this->{properties}    = undef;
  $this->{report_log}    = undef;
  $this->{report_str}    = util::Constants::EMPTY_STR;
  $this->{special_props} = undef;
  $this->{tools}         = $tools;
  $this->{utils}         = $utils;
  ###
  ### Make Sure Required Parameters Are Available
  ### Otherwise, print usage message.
  ###
  if ( !defined($opt_P) ) {
    my $msg_opt;
    if ( !defined($opt_P) ) { $msg_opt = "-P config_params_module"; }
    my $message = "You must supply the $msg_opt option";
    pod2usage(
      -message => $message,
      -exitval => 2,
      -verbose => util::Constants::TRUE,
      -output  => \*STDERR
    );
  }
  my %properties = $tools->setWorkspaceProperty(
    $tools->setContextWithoutOpenLogging(
      $opt_P, @{$property_names}, $tools->getPropertySet($opt_P)
    )
  );
  $this->{properties} = {%properties};

  $this->_setSpecialProperties;
  $this->_setDirectoriesAndFiles;
  $this->_setDates;
  $tools->openLoggingWithLogFile( $this->getLogFile );
  $this->_printSpecialProperties;

  return $this;
}

sub calculateUngapped {
  my ncbi::Utils $this = shift;
  my ($seq) = @_;

  my $gap_info = {};
  (
    $gap_info->{non_gapped_start},
    $gap_info->{non_gapped_end},
    $gap_info->{sseq}
  ) = $this->{utils}->getOffsetTrailing($seq);
  $gap_info->{useq}       = [];
  $gap_info->{non2gapped} = {};
  $gap_info->{gapped2non} = {};
  $gap_info->{start}      = 0;
  $gap_info->{end}        = 0;
  my $end = 0;

  foreach
    my $cindex ( $gap_info->{non_gapped_start} .. $gap_info->{non_gapped_end} )
  {
    next if ( $gap_info->{sseq}->[$cindex] eq util::Constants::HYPHEN );
    push( @{ $gap_info->{useq} }, $gap_info->{sseq}->[$cindex] );
    $gap_info->{non2gapped}->{$end}    = $cindex;
    $gap_info->{gapped2non}->{$cindex} = $end;
    $gap_info->{end}                   = $end;
    $end++;
  }
  $gap_info->{ungapped_seq} =
    join( util::Constants::EMPTY_STR, @{ $gap_info->{useq} } );
  return $gap_info;
}

sub getValue {
  my ncbi::Utils $this = shift;
  my ( $fh, $msg ) = @_;

  my $val = undef;
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    $val = $line;
  }
  $fh->close;
  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 5, [$msg], util::Constants::EMPTY_LINE($val) );
  return $val;
}

sub getFiles {
  my ncbi::Utils $this = shift;
  my ($pattern_property) = @_;

  my $files = [];

  chdir( $this->getDataDirectory );
  my $patterns = $this->getProperties->{$pattern_property};
  foreach my $pattern ( @{$patterns} ) {
    $this->{file_pattern} = $pattern;
    @_FILES_ = ();
    File::Find::find( { wanted => $this->_filesWanted }, util::Constants::DOT );

    foreach my $file ( sort @_FILES_ ) {
      $file =~ s/^\.\///;
      $file = join( util::Constants::SLASH, $this->getDataDirectory, $file );
      push( @{$files}, $file );
    }
  }
  chdir( $this->{run_directory} );
  return $files;
}

sub getFile {
  my ncbi::Utils $this = shift;
  my ( $property, $val ) = @_;

  my $properties   = $this->getProperties->{$property};
  my $filename     = $properties->{filename};
  my $substitution = $properties->{substitution};
  $filename =~ s/$substitution/$val/;
  return join( util::Constants::SLASH, $this->getDataDirectory, $filename );
}

sub resetFile {
  my ncbi::Utils $this = shift;
  my ( $file, $msg ) = @_;

  my $cmds = $this->{tools}->cmds;
  my $msgs = {};
  if ( -e $file ) {
    $msgs->{cmd} = $cmds->RM_FILE($file);
    $this->{error_mgr}->exitProgram(
      ERR_CAT, 4,
      [ 'delete', $msg, $file, ],
      $cmds->executeCommand( $msgs, $msgs->{cmd}, $file )
    );
  }
  $msgs->{cmd} = $cmds->TOUCH_CMD($file);
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 4,
    [ 'touch', $msg, $file ],
    $cmds->executeCommand( $msgs, $msgs->{cmd}, $file )
  );

}

sub runCmd {
  my ncbi::Utils $this = shift;
  my ( $cmd, $msg, $return_status ) = @_;

  $return_status =
    ( !util::Constants::EMPTY_LINE($return_status) && $return_status )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  $this->{error_mgr}->printMsg("runCmd:  $cmd");
  my $msgs = { cmd => $cmd, };
  my $status = $this->{tools}->cmds->executeCommand( $msgs, $cmd, $msg );
  return if ( !$status && !$return_status );
  return $status if ($return_status);
  $this->{error_mgr}->exitProgram( ERR_CAT, 6, [ $cmd, $msg ], $status );
}

sub getCmd {
  my ncbi::Utils $this = shift;
  my ($cmd) = @_;
  $this->{error_mgr}->printMsg("getCmd:  $cmd");
  my $result = `$cmd`;
  my $status = $?;
  if ( !$status ) {
    chomp($result);
    return $result;
  }
  $this->{error_mgr}->exitProgram( ERR_CAT, 7, [$cmd], $status );
}

sub getSpecialValue {
  my ncbi::Utils $this = shift;
  my ($property) = @_;

  return $this->{special_props}->{$property};
}

sub getRunDirectory {
  my ncbi::Utils $this = shift;
  return $this->{run_directory};
}

sub getDataDirectory {
  my ncbi::Utils $this = shift;
  return $this->{data_directory};
}

sub getLogDirectory {
  my ncbi::Utils $this = shift;
  return $this->{log_directory};
}

sub getLogFile {
  my ncbi::Utils $this = shift;
  return $this->{log_file};
}

sub isMonthly {
  my ncbi::Utils $this = shift;
  return $this->{monthly};
}

sub getProperties {
  my ncbi::Utils $this = shift;
  return $this->{properties};
}

sub getNcYyyy {
  my ncbi::Utils $this = shift;
  return $this->{nc_yyyy};
}

sub getNcMmdd {
  my ncbi::Utils $this = shift;
  return $this->{nc_mmdd};
}

sub addReport {
  my ncbi::Utils $this = shift;
  my ($msg) = @_;
  $this->{report_str} .= $msg;
}

sub printReport {
  my ncbi::Utils $this = shift;

  my $file       = $this->{report_log};
  my $report_str = $this->{report_str};
  my $utils      = $this->{utils};
  return
    if ( util::Constants::EMPTY_LINE($report_str)
    || util::Constants::EMPTY_LINE($file) );
  my $fh = $utils->openFile( $file, '>>' );
  $fh->autoflush(util::Constants::TRUE);
  $fh->print($report_str);
  $fh->close;
  $this->{report_str} = util::Constants::EMPTY_STR;
}

sub getObject {
  my ncbi::Utils $this = shift;
  my ($class) = @_;

  my $object     = undef;
  my @eval_array = (
    'use  ' . $class . ';',
    '$object = new ' 
      . $class
      . '($this->{error_mgr}, $this->{tools}, $this->{utils}, $this);'
  );
  my $eval_str = join( util::Constants::NEWLINE, @eval_array );
  eval $eval_str;
  my $status = $@;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 8,
    [ $class, $status ],
    ( defined($status) && $status ) || !defined($object) || !ref($object)
  );
  return $object;
}

sub getProcessingObject {
  my ncbi::Utils $this = shift;
  my ($class_type) = @_;

  my $className = undef;
  if   ( $this->isMonthly ) { $className = 'Monthly'; }
  else                      { $className = 'Daily'; }
  my $class = join( '::', 'ncbi', $class_type, $className );
  return $this->getObject($class);
}

sub getGenbankObject {
  my ncbi::Utils $this = shift;

  my $className = $this->getProperties->{genbankClass};
  my $class     = 'ncbi::Genbank::' . $className;
  return $this->getObject($class);
}

sub writeGenbankFile {
  my ncbi::Utils $this = shift;
  my ( $gb_file, $directory ) = @_;

  my $gb_accession = $gb_file->getStruct->{gb_accession};
  my $gbkFile      = join( util::Constants::SLASH,
    $directory,
    join( util::Constants::DOT, $gb_accession, GENBANK_RECORD_SUFFIX ) );
  my $fh = new FileHandle;
  $this->{error_mgr}->exitProgram(
    ERR_CAT, 4,
    [ 'create', $gbkFile, "creating gbk record file for $gb_accession" ],
    !$fh->open( $gbkFile, '>' )
  );
  $fh->autoflush(util::Constants::TRUE);
  $fh->print( $gb_file->getRecord );
  $fh->close;
}

sub getSeqsOut {
  my ncbi::Utils $this = shift;
  my ( $dir, $file ) = @_;

  my $seqsOutput = undef;
  if ( util::Constants::EMPTY_LINE($file) ) {
    ###
    ### Default Value
    ###
    $seqsOutput = join( util::Constants::SLASH, $dir, SEQ_OUT );
  }
  else {
    ###
    ### Explicit File
    ###
    $seqsOutput = join( util::Constants::SLASH, $dir, $file );
  }

  return $seqsOutput;
}

sub saveResults {
  my ncbi::Utils $this = shift;
  my ( $data, $dir, $dest_file ) = @_;

  my $properties = $this->getProperties;

  my $dataTable =
    new util::TableData( undef, $this->{tools}, $this->{error_mgr} );
  $dataTable->setTableData( SEQS_TYPE, $properties->{seqsOrd} );
  $dataTable->setFile( SEQS_TYPE, $this->getSeqsOut( $dir, $dest_file ) );
  foreach my $struct ( values %{$data} ) {
    $dataTable->addTableRow( SEQS_TYPE,
      $dataTable->createTableDatum( SEQS_TYPE, $struct ) );
  }
  $dataTable->writeTableInfo(SEQS_TYPE);
}

sub readResults {
  my ncbi::Utils $this = shift;
  my ( $dir, $source_file, $raw_file, $file_separator ) = @_;

  $raw_file =
    ( !util::Constants::EMPTY_LINE($raw_file) && $raw_file )
    ? util::Constants::TRUE
    : util::Constants::FALSE;

  my $properties = $this->getProperties;

  my $dataTable =
    new util::TableData( undef, $this->{tools}, $this->{error_mgr} );
  $dataTable->setTableData( SEQS_TYPE, $properties->{seqsOrd} );
  $dataTable->setFile( SEQS_TYPE, $this->getSeqsOut( $dir, $source_file ) );
  if ($raw_file) {
    $dataTable->setTableInfoRaw( SEQS_TYPE, $file_separator );
  }
  else {
    $dataTable->setTableInfo( SEQS_TYPE, $file_separator );
  }

  return @{ $dataTable->getTableInfo(SEQS_TYPE) };
}

################################################################################
1;

__END__

=head1 NAME

Utils.pm

=head1 SYNOPSIS

  use ncbi::Utils;

=head1 DESCRIPTION

This class defines a standard set of utilities for download and
processing NCBI flu data.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Utils(property_names, error_mgr, tools, utils)>

This is the constructor for the class.

=cut
