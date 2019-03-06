package ncbi::Genotype;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use File::Basename;
use Cwd 'chdir';
use Pod::Usage;

use ncbi::ErrMsgs;
use ncbi::GenbankFile;
use ncbi::Loader;

use util::Constants;
use util::PathSpecifics;

use fields qw(
  data
  error_mgr
  gb_file
  na_seq_ids
  ncbi_utils
  run_dir
  tools
  utils
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Queries
###
sub UPDATE_QUERY { return 'updateQuery'; }
###
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::GENOTYPE_CAT; }

################################################################################
#
#				   Private Methods
#
################################################################################

sub _getNaSeqIds {
  my ncbi::Genotype $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $utils      = $this->{utils};
  my $properties = $ncbi_utils->getProperties;

  my $naSidFile = $properties->{naSidFile};

  my $file = join( util::Constants::SLASH,
    $ncbi_utils->getDataDirectory,
    $naSidFile->{file}
  );
  return if ( !-s $file );
  my $fh = $utils->openFile( $file, '<' );
  my $separator = $naSidFile->{separator};
  while ( !$fh->eof ) {
    my $line = $fh->getline;
    chomp($line);
    my @row = split( /$separator/, $line );
    my $struct = {};
    foreach my $index ( 0 .. $#{ $naSidFile->{cols} } ) {
      $struct->{ $naSidFile->{cols}->[$index] } = $row[$index];
    }
    $this->{na_seq_ids}->{ $struct->{gb_accession} } =
      $struct->{na_sequence_id};
  }
  $fh->close;
}

sub _parseResults {
  my ncbi::Genotype $this = shift;
  my ($struct) = @_;

  my @results = ();

  my $ncbi_utils = $this->{ncbi_utils};
  my $utils      = $this->{utils};
  my $properties = $ncbi_utils->getProperties;

  my $resultFileOrd = $properties->{resultFileOrd};
  my $viprGenotype  = $properties->{viprGenotype};

  my $data_comps = $viprGenotype->{data_comps};
  my $version    = $viprGenotype->{version};

  my $file = $struct->{gt_file};
  return @results if ( !-s $file );
  my $fh = $utils->openFile( $file, '<' );
  my $lineCnt = 0;
  while ( !$fh->eof ) {
    $lineCnt++;
    my $line = $fh->getline;
    chomp($line);
    $line = strip_whitespace($line);
    my @line = split( '\t', $line );
    next if ( $lineCnt <= 1 || util::Constants::EMPTY_LINE( $line[0] ) );
    $this->{error_mgr}->printMsg("LINE:$line");
    my $rstruct = { %{$struct} };
    push( @results, $rstruct );

    foreach my $comp ( keys %{$data_comps} ) {
      $rstruct->{$comp} = $line[ $data_comps->{$comp} ];
    }
    $rstruct->{bi}       =~ s/BI=//g;
    $rstruct->{genotype} =~ s/genotype=//g;
    $rstruct->{comments} =~ s/\'//g;
    $rstruct->{version} = $version;
  }

  return @results;
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::Genotype $this = shift;
  my ( $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr}  = $error_mgr;
  $this->{ncbi_utils} = $ncbi_utils;
  $this->{tools}      = $tools;
  $this->{utils}      = $utils;

  $this->{run_dir} = join( util::Constants::SLASH,
    $ncbi_utils->getDataDirectory,
    $ncbi_utils->getProperties->{datasetName}
  );

  $this->{gb_file} =
    new ncbi::GenbankFile( $error_mgr, $tools, $utils, $ncbi_utils );

  return $this;
}

sub process {
  my ncbi::Genotype $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $tools      = $this->{tools};

  if ( $properties->{generate} ) { $this->generateLoad; }
  if ( $properties->{load} )     { $this->processToDb; }

  $ncbi_utils->printReport;
  $tools->setStatus( $tools->SUCCEEDED );
  $tools->saveStatus(
    join( util::Constants::SLASH, $this->{run_dir}, $properties->{statusFile} )
  );
}

sub generateLoad {
  my ncbi::Genotype $this = shift;

  $this->{data}       = {};
  $this->{na_seq_ids} = {};

  my $data       = $this->{data};
  my $cmds       = $this->{tools}->cmds;
  my $gb_file    = $this->{gb_file};
  my $na_seq_ids = $this->{na_seq_ids};
  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $tools      = $this->{tools};
  my $utils      = $this->{utils};

  my $organismTypes = $properties->{organismTypes};
  my $viprGenotype  = $properties->{viprGenotype};

  my $tool        = $viprGenotype->{tool};
  my $result_acc  = $viprGenotype->{result_acc};
  my $result_file = $viprGenotype->{result_file};

  $this->_getNaSeqIds;
  if ( scalar keys %{ $this->{na_seq_ids} } == 0 ) {
    $ncbi_utils->addReport("Genotype:  no sequences found\n");
    return;
  }

  $this->{error_mgr}->printHeader("Getting Sequences");
  $tools->cmds->createDirectory( $this->{run_dir},
    'Creating genotype directory',
    util::Constants::TRUE );
  chdir( $this->{run_dir} );

  my $accessions = [];
  my $foundSeqs  = util::Constants::FALSE;
  my $file = $ncbi_utils->getFile( 'loadSeqFile', $ncbi_utils->getNcMmdd );
  $gb_file->open($file);
  while ( !$gb_file->eof ) {
    $gb_file->nextRecord;
    my $accession = $gb_file->getStruct->{gb_accession};
    next if ( util::Constants::EMPTY_LINE($accession) );
    ###
    ### determine if file meets criteria
    ###
    next
      if (
      !$utils->foundPattern(
        $gb_file->getStruct->{source_organism},
        $organismTypes
      )
      );
    push( @{$accessions}, $accession );
    $foundSeqs = util::Constants::TRUE;
    $ncbi_utils->writeGenbankFile( $gb_file, $this->{run_dir} );
  }
  $gb_file->close;

  $ncbi_utils->addReport("Genotype:  no sequences found\n") if ( !$foundSeqs );

  return if ( !$foundSeqs );

  my $toolDir  = dirname($tool);
  my $toolName =
    join( util::Constants::SLASH, util::Constants::DOT, basename($tool) );
  $this->{error_mgr}->printMsg("Generation Tool Directory = $toolDir");
  chdir($toolDir);
  ###
  ### Run genotyping
  ###
  my $success = 0;
  my $error   = 0;
  foreach my $accession ( @{$accessions} ) {
    my $gbFile = join( util::Constants::DOT,
      $accession, $ncbi_utils->GENBANK_RECORD_SUFFIX );
    my $stdOut = join( util::Constants::SLASH,
      $this->{run_dir}, join( util::Constants::DOT, $accession, 'std' ) );
    my $errOut = join( util::Constants::SLASH,
      $this->{run_dir}, join( util::Constants::DOT, $accession, 'err' ) );
    my $gtFile = join( util::Constants::SLASH, $this->{run_dir}, $result_file );
    $gtFile =~ s/$result_acc/$accession/;
    my $msgs = {
      cmd => join( util::Constants::SPACE,
        $toolName, '-d',    $this->{run_dir}, '-i', $gbFile,
        '>',       $stdOut, '2>',             $errOut
      ),
    };
    my $status =
      $cmds->executeCommand( $msgs, $msgs->{cmd}, 'executing genotyping' );
    $ncbi_utils->addReport("Genotype ($accession):  failed genotyping\n")
      if ($status);
    $error++ if ($status);
    $this->{error_mgr}->printMsg(
      "Status ($status) gtFile (" . ( -e $gtFile ) . ") = $gtFile" );
    next if ($status);
    next if ( !-e $gtFile );
    ###
    ### Record generated results
    ###
    $success++;
    $data->{$accession} = {
      gb_accession   => $accession,
      na_sequence_id => $na_seq_ids->{$accession},
      gt_file        => $gtFile,
    };
  }
  $ncbi_utils->addReport(
    "Genotype generation:  success $success, error $error\n");
  chdir( $this->{run_dir} );
  $ncbi_utils->saveResults( $this->{data}, $this->{run_dir} );
}

sub processToDb {
  my ncbi::Genotype $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $tools      = $this->{tools};

  if ( !-s $ncbi_utils->getSeqsOut( $this->{run_dir} ) ) {
    $ncbi_utils->addReport("Genotype:  no sequences found\n");
    return;
  }

  $tools->startTransaction(util::Constants::TRUE);
  my $loader =
    new ncbi::Loader( 'Genotype', undef, [UPDATE_QUERY], $this->{error_mgr},
    $this->{tools}, $this->{utils}, $this->{ncbi_utils} );

  $this->{error_mgr}->printHeader("Update Genotypes");
  my $errorCount  = 0;
  my $queryStatus = util::Constants::FALSE;
OUTTER_LOOP:
  foreach my $struct ( $ncbi_utils->readResults( $this->{run_dir} ) ) {
    foreach my $rstruct ( $this->_parseResults($struct) ) {
      foreach my $queryName (UPDATE_QUERY) {
        my $status = $loader->executeUpdate( $queryName, $rstruct );
        $errorCount++ if ($status);
        $queryStatus = $status ? $status : $queryStatus;
        next OUTTER_LOOP if ($status);
      }
    }
  }
  ###
  ### Error(s) in  Run
  ###
  my $db = $this->{tools}->getSession;
  if ($queryStatus) {
    $ncbi_utils->addReport( "Genotype (ERRORS ENCOUNTERED):  inserts executed "
        . ( $db->getCommitCount - $errorCount )
        . ", insert errors $errorCount\n" );
    $ncbi_utils->printReport;
    $tools->rollbackTransaction;
    $tools->setStatus( $tools->FAILED );
    $tools->saveStatus(
      join( util::Constants::SLASH,
        $this->{run_dir}, $properties->{statusFile}
      )
    );
    $this->{error_mgr}->exitProgram( ERR_CAT, 1, [], util::Constants::TRUE );
  }
  ###
  ### Successful Run
  ###
  $ncbi_utils->addReport( "Genotype:  success "
      . ( $db->getCommitCount - $errorCount )
      . ", error $errorCount\n" );
  $tools->finalizeTransaction;
}

################################################################################
1;

__END__

=head1 NAME

Genotype.pm

=head1 SYNOPSIS

  use ncbi::Genotype;

=head1 DESCRIPTION

The Nonflu virus genotype processor.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::Genotype(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
