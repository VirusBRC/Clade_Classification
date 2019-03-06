package ncbi::MatPeptide;
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

use Bio::SeqIO;

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
### File types
###
sub FASTA_TYPE { return 'fasta'; }
###
### Annotation Statuses
###
sub FAILED_STATUS { return 'FAILED'; }
sub PARSED_STATUS { return 'PARSED'; }
###
### Queries
###
sub ALG_QUERY    { return 'ALGQuery'; }
sub FINAL_QUERY  { return 'finalQuery'; }
sub STATUS_QUERY { return 'statusQuery'; }
###
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::MATPEPTIDE_CAT; }

################################################################################
#
#				   Private Methods
#
################################################################################

sub _getNaSeqIds {
  my ncbi::MatPeptide $this = shift;

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

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::MatPeptide $this = shift;
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
  my ncbi::MatPeptide $this = shift;

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
  my ncbi::MatPeptide $this = shift;

  $this->{data}       = {};
  $this->{na_seq_ids} = {};

  my $cmds       = $this->{tools}->cmds;
  my $data       = $this->{data};
  my $gb_file    = $this->{gb_file};
  my $na_seq_ids = $this->{na_seq_ids};
  my $ncbi_utils = $this->{ncbi_utils};
  my $tools      = $this->{tools};
  my $utils      = $this->{utils};
  my $properties = $ncbi_utils->getProperties;

  my $algDefline            = $properties->{algDefline};
  my $algTypes              = $properties->{algTypes};
  my $clustalDir            = $properties->{clustalDir};
  my $fileTypes             = $properties->{fileTypes};
  my $msaAnnotateTool       = $properties->{msaAnnotate}->{tool};
  my $muscleDir             = $properties->{muscleDir};
  my $msaAnnotateBioPerlLib = $properties->{msaAnnotate}->{bioPerlLib};

  my $defline_separator = $algDefline->{separator};
  my $defline_tag       = $algDefline->{tag};

  $this->_getNaSeqIds;
  if ( scalar keys %{ $this->{na_seq_ids} } == 0 ) {
    $ncbi_utils->addReport("Mat Peptide:  no sequences found\n");
    return;
  }

  $this->{error_mgr}->printHeader("Getting Sequences");
  $tools->cmds->createDirectory( $this->{run_dir},
    'Creating matpeptide directory',
    util::Constants::TRUE );
  chdir( $this->{run_dir} );

  my $foundSeqs = util::Constants::FALSE;
  my $file = $ncbi_utils->getFile( 'loadSeqFile', $ncbi_utils->getNcMmdd );
  $gb_file->open($file);
  my $accessions = [];
  while ( !$gb_file->eof ) {
    $gb_file->nextRecord;
    my $accession = $gb_file->getStruct->{gb_accession};
    next if ( util::Constants::EMPTY_LINE($accession) );
    push( @{$accessions}, $accession );
    $foundSeqs = util::Constants::TRUE;
    $ncbi_utils->writeGenbankFile( $gb_file, $this->{run_dir} );
  }
  $gb_file->close;

  $ncbi_utils->addReport("Mat Peptide:  no sequences found\n")
    if ( !$foundSeqs );
  return if ( !$foundSeqs );
  ###
  ### Set the clustal directory variable
  ###
  $ENV{ $clustalDir->{variable} } = $clustalDir->{directory};
  $ENV{ $muscleDir->{variable} }  = $muscleDir->{directory};
  my $toolDir  = dirname($msaAnnotateTool);
  my $toolName = join( util::Constants::SLASH,
    util::Constants::DOT, basename($msaAnnotateTool) );
  $this->{error_mgr}->printMsg("Generation Tool Directory = $toolDir");
  chdir($toolDir);
  ###
  ### Set the BioPerl Library
  ###
  $ENV{PERL5LIB} =
    $msaAnnotateBioPerlLib . util::Constants::COLON . $ENV{PERL5LIB};
  ###
  ### Run msa_annotate
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
    my $out_files = {};
    foreach my $fileType ( keys %{$fileTypes} ) {
      $out_files->{$fileType} = join( util::Constants::SLASH,
        $this->{run_dir}, $accession . $fileTypes->{$fileType} );
    }
    my $msgs = {
      cmd => join( util::Constants::SPACE,
        $toolName, '-d',    $this->{run_dir}, '-i', $gbFile,
        '>',       $stdOut, '2>',             $errOut
      ),
    };
    my $status =
      $cmds->executeCommand( $msgs, $msgs->{cmd}, 'executing msa_annotate' );
    $ncbi_utils->addReport("Mat Peptide ($accession):  failed msa_annotate\n")
      if ($status);
    $error++ if ($status);
    ###
    ### Print Logging Info
    ###
    foreach my $file_type ( keys %{$fileTypes} ) {
      my $out_file = $out_files->{$file_type};
      $this->{error_mgr}->printMsg( "Status ($status) ${file_type}File ("
          . ( -e $out_file )
          . ") = $out_file" );
    }
    ###
    ### Determine the out file
    ###
    my $fileType = undef;
    foreach my $file_type ( keys %{$fileTypes} ) {
      my $out_file = $out_files->{$file_type};
      if ( -e $out_file ) {
        $fileType = $file_type;
        last;
      }
    }
    next if ($status);
    next if ( !defined($fileType) );
    ###
    ### Determine the alg types for running stored procedures
    ###
    my $alg_types = {};
    my $fh        = $utils->openFile( $out_files->{$fileType}, '<' );
    my $fastaSeq  = new Bio::SeqIO( -fh => $fh, -format => FASTA_TYPE );
    while ( my $seq = $fastaSeq->next_seq ) {
      my $defline = $seq->display_id;
      my @comps = split( /$defline_separator/, $defline );
      foreach my $comp (@comps) {
        if ( $comp =~ /$defline_tag(.+)$/ ) {
          my $alg_type = lc($1);
          $alg_types->{ $algTypes->{$alg_type} } = util::Constants::EMPTY_STR;
          last;
        }
      }
    }
    $fh->close;
    ###
    ### Record generated results
    ###
    $success++;
    $data->{$accession} = {
      gb_accession   => $accession,
      na_sequence_id => $na_seq_ids->{$accession},
      out_file       => $out_files->{$fileType},
      alg_types      =>
        join( util::Constants::COMMA_SEPARATOR, sort keys %{$alg_types} ),
    };
  }
  $ncbi_utils->addReport(
    "Mat Peptide generation:  success $success, error $error\n");
  chdir( $this->{run_dir} );
  $ncbi_utils->saveResults( $this->{data}, $this->{run_dir} );
}

sub processToDb {
  my ncbi::MatPeptide $this = shift;

  chdir( $this->{run_dir} );

  my $cmds       = $this->{tools}->cmds;
  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $tools      = $this->{tools};

  my $parseMatPeptideTool = $properties->{parseMatPeptideTool};
  my $bhbStagingDatabase  = $properties->{bhbStagingDatabase};
  my $msaAnnotateType     = $properties->{algTypes}->{msa};
  my $msaAnnotateVersion  = $properties->{msaAnnotate}->{version};

  if ( !-s $ncbi_utils->getSeqsOut( $this->{run_dir} ) ) {
    $ncbi_utils->addReport("Mat Peptide:  no sequences found\n");
    return;
  }
  ###
  ### Load data into BHB_STAGING.DAILY_MAT_PEPTIDE
  ###
  my $errorCount  = 0;
  my $msgs        = {};
  my $numSeqs     = 0;
  my $queryStatus = util::Constants::FALSE;
  my $toolDir     = dirname($parseMatPeptideTool);
  my $toolName    = join( util::Constants::SLASH,
    util::Constants::DOT, basename($parseMatPeptideTool) );
  $this->{error_mgr}->printMsg("Load Tool Directory = $toolDir");
  chdir($toolDir);

  my $loader = undef;
  foreach my $struct ( $ncbi_utils->readResults( $this->{run_dir} ) ) {
    $numSeqs++;
    my $accession = $struct->{gb_accession};
    my $file      = $struct->{out_file};
    my $nasid     = $struct->{na_sequence_id};
    my $algTypes  = [ split( /, /, $struct->{alg_types} ) ];
    my $stdOut    = join( util::Constants::SLASH,
      $this->{run_dir}, join( util::Constants::DOT, $accession, 'db', 'std' ) );
    my $errOut = join( util::Constants::SLASH,
      $this->{run_dir}, join( util::Constants::DOT, $accession, 'db', 'err' ) );
    $msgs->{cmd} = join( util::Constants::SPACE,
      $toolName, '-s',                            $properties->{databaseName},
      '-u',      $bhbStagingDatabase->{userName}, '-p',
      $bhbStagingDatabase->{password}, '-f',             $file,
      '-o',                            'database',       '-i',
      $nasid,                          '-v',             $msaAnnotateVersion,
      '-m',                            $msaAnnotateType, '>',
      $stdOut,                         '2>',             $errOut
    );
    my $status =
      $cmds->executeCommand( $msgs, $msgs->{cmd},
      'executing parse matpeptide' );
    $ncbi_utils->addReport(
      "Mat Peptide ($accession):  ERROR parse matpeptide\n")
      if ($status);
    $errorCount++ if ($status);
    $queryStatus = $status ? $status : $queryStatus;
    next if ($status);
    ###
    ### Perform Annotation
    ###
    foreach my $alg_type ( @{$algTypes} ) {
      $struct->{alg_type} = $alg_type;
      $this->{tools}->startTransaction(util::Constants::TRUE);
      $loader = new ncbi::Loader( 'Matpeptide annotation',
        undef, [ALG_QUERY], $this->{error_mgr}, $this->{tools}, $this->{utils},
        $this->{ncbi_utils} );
      $status = $loader->executeUpdate( ALG_QUERY, $struct );
      $queryStatus = $status ? $status : $queryStatus;
      $errorCount++ if ($status);
      if ($status) { $this->{tools}->rollbackTransaction; }
      else { $this->{tools}->finalizeTransaction; }
      $struct->{status} = $status ? FAILED_STATUS : PARSED_STATUS;
      ###
      ### Set Status
      ###
      $this->{tools}->openSessionExplicit(
        $bhbStagingDatabase->{serverType}, $properties->{databaseName},
        $bhbStagingDatabase->{userName},   $bhbStagingDatabase->{password},
        $bhbStagingDatabase->{schemaOwner}
      );
      $this->{tools}->startTransaction;
      $loader = new ncbi::Loader( 'Matpeptide annotation',
        undef, [STATUS_QUERY], $this->{error_mgr}, $this->{tools},
        $this->{utils}, $this->{ncbi_utils} );
      $status = $loader->executeUpdate( STATUS_QUERY, $struct );
      if ($status) { $this->{tools}->rollbackTransaction; }
      else { $this->{tools}->finalizeTransaction; }
    }
  }
  ###
  ### Set Annotation
  ###
  if ( !$queryStatus ) {
    $this->{tools}->startTransaction(util::Constants::TRUE);
    $loader = new ncbi::Loader( 'Matpeptide annotation',
      undef, [FINAL_QUERY], $this->{error_mgr}, $this->{tools}, $this->{utils},
      $this->{ncbi_utils} );
    my $struct = { gb_accession => 'all accs', na_sequence_id => 'all ids', };
    my $status = $loader->executeUpdate( FINAL_QUERY, $struct );
    if ($status) { $this->{tools}->rollbackTransaction; }
    else { $this->{tools}->finalizeTransaction; }
  }
  chdir( $this->{run_dir} );
  ###
  ### Error(s) in  Run
  ###
  if ($queryStatus) {
    $ncbi_utils->addReport(
          "Mat Peptide (ERRORS ENCOUNTERED):  sequences processed "
        . ( $numSeqs - $errorCount )
        . ", errors encountered $errorCount\n" );
    $ncbi_utils->printReport;
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
  $ncbi_utils->addReport("Mat Peptide:  sequences processed $numSeqs\n");
}

################################################################################
1;

__END__

=head1 NAME

MatPeptide.pm

=head1 SYNOPSIS

  use ncbi::MatPeptide;

=head1 DESCRIPTION

The Nonflu virus matpeptide processor.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::MatPeptide(error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
