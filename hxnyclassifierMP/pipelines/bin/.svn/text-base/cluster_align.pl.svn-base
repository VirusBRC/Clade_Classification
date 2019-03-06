#!/usr/bin/perl
######################################################################
#                  Copyright (c) 2011 Northrop Grumman.
#                          All rights reserved.
######################################################################

######################################################################
#
# Module:  cluster_align.pl
#
# Subroutines to pre-process MSA alignments using Ucluster.  Program is thread-safe.
#
# author: aramsey@vecna.com
#
######################################################################

################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'chdir';
use File::Basename;
use FileHandle;

use Bio::AlignIO;

################################################################################
#
#				   Constants
#
################################################################################
###
### Execution Start Time
###
my $START_TIME = time();
###
### Pathname to Executables
###
our $muscle = $ENV{MUSCLE};
our $uclust = $ENV{UCLUSTER};

################################################################################
#
#			    Parameter Initialization
#
################################################################################

my $numArgs = scalar @ARGV;
my $aa_file  = shift or die "Need the amino acid sequences file.\n";
my $fastaout = shift or die "Need the fasta output file.\n";

################################################################################
#
#				Main Program
#
################################################################################
###
### Special Variables
###
my $clw_output = undef;
if ($numArgs == 3) {
  $clw_output = shift;
} else {
  $clw_output = join( '.', $fastaout, 'clwout' );
}
my ( $root_dir, $working_dir ) = mkWkDir( dirname($fastaout) );
###
### Start Logging
###
my $logFh = new FileHandle;
my $log_file = join( '/', $root_dir, join( '.', basename($aa_file), 'log' ) );
$logFh->open( $log_file, '>' );
$logFh->autoflush(1);
$logFh->print( "[INFO]:  Start Time: - " . `date` );
$logFh->print("[INFO]:  aa_file     - $aa_file\n");
$logFh->print("[INFO]:  fastaout    - $fastaout\n");
$logFh->print("[INFO]:  root_dir    - $root_dir\n");
$logFh->print("[INFO]:  working dir - $working_dir\n");
###
### Check Executables
###
if ( !defined($muscle) || $muscle eq '' || !defined($uclust) || $uclust eq '' )
{
  $logFh->print( "[ERROR]:  Environment Missing:\n"
      . "[ERROR]:  muscle    MUSCLE    '$muscle'\n"
      . "[ERROR]:  ucluster  UCLUSTER  '$uclust'\n" );
  terminateRun(2);
}
$logFh->print( "[INFO]:  MUSCLE      - " . $muscle . "\n" );
$logFh->print( "[INFO]:  UCLUSTER    - " . $uclust . "\n" );
###
### Run Cluster Align
###
eval {
  do_uclust_muscle( $aa_file, $fastaout, $clw_output, $working_dir );
  die
"UCluster/Muscle pipeline did not generate output - will need to run Muscle directly.\n"
    unless ( -s $fastaout && -f $fastaout );
};
my $status = $@;
###
### Remove Unneeded Data
###
unlink($clw_output) if ($numArgs != 3);
system("/bin/rm -rf $working_dir");
###
### Set exit status and determine what to next, as necessary
###
my $exit_status = 0;
if ($status) {
  ###
  ### Error in ucluster/muscle pipeline, must run muscle directly
  ###
  chdir($root_dir);
  my $muscle_cmd = "$muscle -quiet -in $aa_file -out $fastaout";
  $logFh->print(
    "[ERROR]:  Must run muscle directly:\n" . "[ERROR]:    $muscle_cmd\n" );
  $logFh->print("[INFO]:  muscle (-quiet -in $aa_file -out $fastaout)\n");
  system(`$muscle_cmd`);
  $status = $?;
  if ($status) {
    $exit_status = 2;
    $logFh->print(
      "[ERROR]:  Direct muscle failed:\n" . "[ERROR]:    $muscle_cmd\n" );
  }
}
terminateRun($exit_status);

################################################################################
#
#				   SUBROUTINES
#
################################################################################

sub terminateRun {
  my ($exit_status) = @_;
  my $etime = time();
  $logFh->print("[INFO]:  Exit Status: - $exit_status\n");
  $logFh->print( "[INFO]:  End Time:    - " . `date` );
  $logFh->print(
    "[INFO]:  Run Time:    - " . ( $etime - $START_TIME ) . " seconds\n" );
  $logFh->close();
  exit($exit_status);
}

sub mkWkDir {
  my ($root_dir) = @_;
  ###
  ### Determine the absolute path for the root_dir
  ###
  chdir('.');
  my $current_focus = $ENV{PWD};
  $current_focus =~ s/\/\.$//;
  if ( $root_dir eq '' || $root_dir eq '.' ) {
    $root_dir = $current_focus;
  }
  elsif ( $root_dir eq '/' ) {
    $root_dir = '';
  }
  elsif ( $root_dir !~ /^\// ) {
    $root_dir = join( '/', $current_focus, $root_dir );
  }
  my $hostname = `hostname -s`;
  chomp($hostname);
  my $workingDir =
    join( '/', $root_dir, join( '.', 'cluster_align', $hostname, time(), $$ ) );
  system("mkdir -m 777 -p $workingDir");
  return ( $root_dir, $workingDir ) if ( -d $workingDir );
  ###
  ### quit since cannot create directory
  ###
  print "[ERROR]:  Working Directory NOT Created:  $workingDir\n";
  print "[INFO]:  End Time: " . `date`;
  exit(2);
}

sub do_uclust_muscle {

  # 1. Split into full vs partial length
  # 2. On full length, "clumpalign*" with maxiter=2
  #    - clumpalign is following Uclust's manual by the book, starting on p. 21
  # 3. Split partials by GT 50% (large partials) and LT 50% (small partials)
  # 4. On large partials, "progressive merge"
  #    - progressive merge is:
  #      + uclust sort
  #      + uclust uc 0.90 ident
  #      + uclust uc2fasta
  #      + split & align group by clusters, iteratively merging into parent
  # 5. On small partials, progressive merge

  my $in_file  = shift;
  my $fastaout = shift;
  my $clwout   = shift;
  my $wd_name  = shift;
  my %seqs     = ();
  my ( $header_buffer, $seq_buffer );
  open( IN_FILE, "$in_file" ) or die();

  # Create hashmap of the input sequences
  while ( my $line = <IN_FILE> ) {
    if ( $line =~ m/^\>/ ) {
      if ( defined($header_buffer) ) {
        $seqs{$header_buffer} = $seq_buffer;
      }
      $header_buffer = trim( substr( $line, 1 ) );
      $seq_buffer = "";
    }
    else {
      $seq_buffer .= trim($line);
    }
  }

  # Put last fasta from cache into hashmap
  $seqs{$header_buffer} = $seq_buffer;

# Split into full, large partials (gt 50% length), and small partials (lt 50% length)
  my $fulls_name      = $wd_name . "/full_sequences.fasta";
  my $largeparts_name = $wd_name . "/large_partial_sequences.fasta";
  my $smallparts_name = $wd_name . "/small_partial_sequences.fasta";
  my $nums_ref =
    seqsort( \%seqs, $fulls_name, $largeparts_name, $smallparts_name );
  my ( $num_full, $num_large, $num_small ) = @{$nums_ref};
  $logFh->print("[INFO]:  \$num_full: $num_full\n");
  $logFh->print("[INFO]:  \$num_large: $num_large\n");
  $logFh->print("[INFO]:  \$num_small: $num_small\n");

  #  Process each sorted bucket
  #   - On full lengths, run "clumpalign" with maxiter=2
  my $fulls_align = undef;
  if ($num_full != 0) {
    $logFh->print("[INFO]:  clumpalign fulls\n");
    $fulls_align = clumpalign( $wd_name, $fulls_name );
  }

  #   - On large partials, "progressive merge"
  my ( $largeparts_align, $largeparts_align_clw );
  if ( $num_large != 0 ) {
    if ( $num_full != 0 ) {
      $logFh->print("[INFO]:  progressive_merge fulls with largeparts\n");
      my $largeparts_results =
        progressive_merge( $wd_name, $fulls_align, $largeparts_name );
      my ( $fasta_aln, $clw_aln ) = @{$largeparts_results};
      $largeparts_align     = $fasta_aln;
      $largeparts_align_clw = $clw_aln;
    }
    else {
      $logFh->print("[INFO]:  clumpalign largeparts\n");
      $largeparts_align = clumpalign( $wd_name, $largeparts_name );
    }
  }
  else {
    $largeparts_align = $fulls_align;
  }

  #   - On small partials, "progressive merge" as well
  if ( $num_small != 0 ) {
    $logFh->print("[INFO]:  progressive_merge smallparts\n");
    my $smallparts_results =
      progressive_merge( $wd_name, $largeparts_align, $smallparts_name );
    my ( $smallparts_align, $smallparts_align_clw ) = @{$smallparts_results};
    `cp $smallparts_align $fastaout`;
    `cp $smallparts_align_clw $clwout`;
  }
  else {
    $logFh->print("[INFO]:  no smallparts\n");
    `cp $largeparts_align $fastaout`;
    unless ( defined($largeparts_align_clw) ) {
      $largeparts_align_clw = create_clw($largeparts_align);
    }
    `cp $largeparts_align_clw $clwout`;
  }

  #  Fin!
}

#
# Sort the sequences by full/large/small lengths and write to file
#
sub seqsort {
  my $seqs_href       = shift or die();
  my %s               = %{$seqs_href};
  my $fulls_name      = shift or die();
  my $largeparts_name = shift or die();
  my $smallparts_name = shift or die();
  open( FULL,      ">$fulls_name" )      or die();
  open( LARGEPART, ">$largeparts_name" ) or die();
  open( SMALLPART, ">$smallparts_name" ) or die();
  my @headers   = keys(%s);
  my $num_full  = 0;
  my $num_large = 0;
  my $num_small = 0;

  for my $header (@headers) {
    my $seq          = $s{$header};
    my $fasta        = ">" . $header . "\n" . $seq . "\n\n";
    my $cutoff_80    = cutoff_percent( \%s, 0.8 );
    my $small_cutoff = cutoff_percent( \%s, 0.5 );
    if ( ( $seq =~ m/^M/i ) && ( length($seq) > $cutoff_80 ) ) {
      print FULL "$fasta";
      $num_full++;
    }
    else {
      if ( length($seq) < $small_cutoff ) {
        print SMALLPART "$fasta";
        $num_small++;
      }
      else {
        print LARGEPART "$fasta";
        $num_large++;
      }
    }
  }
  close(FULL);
  close(LARGEPART);
  close(SMALLPART);
  my @nums = ( $num_full, $num_large, $num_small );
  return \@nums;
}

#
# Run "clumpalign" as suggested by Robert Edgar (p. 21 in Ucluster User Guide)
#
sub clumpalign {
  my $dir = shift or die();

# Clumping has issues with headers ending with pipe ('|'), so first remove pipe, then add back (if needed)
  my $infile_raw = shift or die();
  $logFh->print("[INFO]:  clumpalign($dir, $infile_raw)\n");
  my $pipes = check_pipes($infile_raw);
  my $infile;
  if ( $pipes == 0 ) {
    $infile = $infile_raw;
  }
  else {
    $infile = depipe($infile_raw);
  }
  my $sortfile = $infile . ".sorted";

  my $outfile = $infile . ".aligned";
  $logFh->print("[INFO]:  uclust (--sort $infile --output $sortfile)\n");
  `$uclust --quiet --sort $infile --output $sortfile`;
  `mkdir $dir/myclumps`;
  $logFh->print(
"[INFO]:  uclust (--uhire $sortfile --clumpfasta $dir/myclumps/ --maxclump 5000)\n"
  );
  `$uclust --quiet --uhire $sortfile --clumpfasta $dir/myclumps/ --maxclump 5000`;
  `mkdir $dir/clumpalns`;
  $logFh->print("[INFO]:  muscle clum.* and master\n");
  `cd $dir/myclumps;for f in clump.* master; do $muscle -quiet -in \$f -out ../clumpalns/\$f -maxiters 2; done`;
  $logFh->print(
    "[INFO]:  uclust (--mergeclumps $dir/clumpalns/ --output $outfile) \n");
  `$uclust --quiet --mergeclumps $dir/clumpalns/ --output $outfile`;
  my $outfile_final;

  if ( $pipes == 0 ) {
    $outfile_final = $outfile;
  }
  else {
    $outfile_final = repipe($outfile);
  }
  return $outfile_final;
}

#
# check_pipe
#
sub check_pipes {
  my $check_file = shift;
  my $pipe       = 0;
  open( CHECK_FILE, "$check_file" );
  while ( my $line = <CHECK_FILE> ) {
    if ( $line =~ m/^\>/ ) {
      if ( trim($line) =~ m/\|$/ ) {
        $pipe = 1;
        last;
      }
    }
  }
  close(CHECK_FILE);
  return $pipe;
}

#
# depipe
#
sub depipe {
  my $in_file     = shift;
  my $depipe_file = $in_file . ".depipe";
  open( DEPIPE_FILE_IN,  "$in_file" );
  open( DEPIPE_FILE_OUT, ">$depipe_file" );
  while ( my $line = <DEPIPE_FILE_IN> ) {
    $line = trim($line);
    $line =~ s/\|$//;
    print DEPIPE_FILE_OUT "$line\n";
  }
  close(DEPIPE_FILE_IN);
  close(DEPIPE_FILE_OUT);
  return $depipe_file;
}

#
# repipe
#
sub repipe {
  my $in_file     = shift;
  my $repipe_file = $in_file . ".repipe";
  open( REPIPE_FILE_IN,  "$in_file" );
  open( REPIPE_FILE_OUT, ">$repipe_file" );
  while ( my $line = <REPIPE_FILE_IN> ) {
    if ( $line =~ m/^\>/ ) {
      $line = trim($line);
      print REPIPE_FILE_OUT "$line|\n";
    }
    else {
      print REPIPE_FILE_OUT "$line";
    }
  }
  close(REPIPE_FILE_IN);
  close(REPIPE_FILE_OUT);
  return $repipe_file;
}

#
# Perform a progressive alignment and do a merge with prior results
#
sub progressive_merge {
  my $dir         = shift or die();
  my $prior_align = shift or die();
  my $infile      = shift or die();
  $logFh->print("[INFO]:  progressive_merge ($dir, $prior_align, $infile) \n");

  my $id_val   = "0.90";             # percent identity parameter for clustering
  my $sortfile = $infile . ".sorted";
  my $ucfile   = $infile . ".uc";
  my $ucfasta  = $ucfile . ".fasta";
  $logFh->print("[INFO]:  uclust (--sort $infile --output $sortfile)\n");
  `$uclust --quiet --sort $infile --output $sortfile`;
  $logFh->print(
    "[INFO]:  uclust (--input $sortfile --uc $ucfile --id $id_val)\n");
  `$uclust --quiet --input $sortfile --uc $ucfile --id $id_val`;
  $logFh->print(
    "[INFO]:  uclust (--uc2fasta $ucfile --input $sortfile --output $ucfasta)\n"
  );
  `$uclust --quiet --uc2fasta $ucfile --input $sortfile --output $ucfasta`;
  my $clusterout = clustermerge( $dir, $prior_align, $ucfasta );
  return $clusterout;
}

#
# Separate each cluster and merge to prior alignment
#
sub clustermerge {
  my $dir         = shift or die();
  my $prior_align = shift or die();
  my $clusterfile = shift or die();
  $logFh->print("[INFO]:  clustermerge ($dir, $prior_align, $clusterfile)\n");

  # Split clusters into separate files for alignment
  #   1. Read in the clustered fasta file to split
  #      - Read each line
  #        + If blank, skip
  #        + If header, parse header
  #          > 1st is group no. | 2nd is % id | 3rd is original header
  #          > If new group, add to array of existing seqs
  #          > Track no. of groups
  #          > Else dump current cache & start new group
  #       + Else add to current running seq
  #   2. Do msa merge with descending group
  my $clusterdir = $clusterfile . "_cluster";
  `mkdir $clusterdir`;
  my ( %header_groups, %seqs );
  my ( $header_buffer, $parsed_header_buffer, $seq_buffer );
  open( CLUSTER_FILE, "$clusterfile" ) or die();
  while ( my $line = <CLUSTER_FILE> ) {
    if ( $line =~ m/^\>/ ) {
      if ( defined($parsed_header_buffer) ) {
        $seqs{$parsed_header_buffer} = $seq_buffer;
      }
      $header_buffer = trim( substr( $line, 1 ) );
      my $parsed_results_ref = parse_header($header_buffer);
      my ( $val0, $val1, $val2 ) =
        @{$parsed_results_ref};    # Cluster group and header line
      my $g = $val0;
      $parsed_header_buffer = $val2;
      unless ( $header_groups{$g} ) {
        my @new_header_group = ($parsed_header_buffer);
        $header_groups{$g} = \@new_header_group;
      }
      else {
        my @header_group = @{ $header_groups{$g} };
        push( @header_group, $parsed_header_buffer );
        $header_groups{$g} = \@header_group;
      }
      $seq_buffer = "";
    }
    else {
      $seq_buffer .= trim($line);
    }
  }

  # Put last fasta from cache into hashmap
  $seqs{$parsed_header_buffer} = $seq_buffer;

  # Print out fasta file for each cluster and align
  my @groups = keys(%header_groups);
  for my $gg (@groups) {
    my $group_fasta = $clusterdir . "/$gg.fasta";
    open( GROUP_FILE, ">$group_fasta" ) or die();
    my @headers = @{ $header_groups{$gg} };
    for my $header (@headers) {
      print GROUP_FILE ">$header\n";
      my $sequence = $seqs{$header};
      print GROUP_FILE "$sequence\n\n";
    }
    close(GROUP_FILE);
    my $group_align = $group_fasta . ".aln";
    $logFh->print(
"[INFO]:  muscle (-quiet -in $group_fasta -out $group_align -maxiters 2)\n"
    );
    `$muscle -quiet -in $group_fasta -out $group_align -maxiters 2`;
  }

  # Perform MSA merge for each cluster
  # Merge prior align with first group
  my $firstmerge = "$clusterdir/0.merged.aln";
  my $fm_clw     = $firstmerge . ".clw";
  $logFh->print(
"[INFO]:  muscle (-quiet -profile -in1 $prior_align -in2 $clusterdir/0.fasta.aln -fastaout $firstmerge -clwout $fm_clw -maxiters 2)\n"
  );
  `$muscle -quiet -profile -in1 $prior_align -in2 $clusterdir/0.fasta.aln -fastaout $firstmerge -clwout $fm_clw -maxiters 2`;

  # Iterate through rest of the groups
  my $num_groups = @groups;
  my $prior_group;
  my $last_align = $firstmerge;
  my $la_clw     = $fm_clw;
  for ( my $n = 0 ; $n < $num_groups ; $n++ ) {
    unless ( defined($prior_group) ) {
      $prior_group = $n;
    }
    next if ( $n == 0 );    # Skip first group since already aligned
    my $nextmerge = "$clusterdir/$n.merged.aln";
    my $nm_clw    = $nextmerge . ".clw";
    $logFh->print(
"[INFO]:  muscle (-quiet -profile -in1 $clusterdir/$prior_group.merged.aln -in2 $clusterdir/$n.fasta.aln -fastaout $nextmerge -clwout $nm_clw -maxiters 2)\n"
    );
    `$muscle -quiet -profile -in1 $clusterdir/$prior_group.merged.aln -in2 $clusterdir/$n.fasta.aln -fastaout $nextmerge -clwout $nm_clw -maxiters 2`;
    $prior_group = $n;
    $last_align  = $nextmerge;
    $la_clw      = $nm_clw;
  }

  close(CLUSTER_FILE);
  my @last = ( $last_align, $la_clw );
  return \@last;
}

#
#
#
sub create_clw {
  my $infile  = shift or die();
  my $outfile = $infile . ".clw";
  my $in      = Bio::AlignIO->new(
    -file   => $infile,
    -format => 'fasta'
  );
  my $out = Bio::AlignIO->new(
    -file   => ">$outfile",
    -format => 'clustalw'
  );
  while ( my $aln = $in->next_aln() ) {
    $out->write_aln($aln);
  }
  return $outfile;
}

#
# Parse the ucluster header
#
sub parse_header {
  my $header = shift or die();
  my @vals = split( /\|/, $header );
  return \@vals;
}

#
# Get cutoff length by percent of max length
#
sub cutoff_percent {
  my $s_href     = shift;
  my $cutoff     = shift;
  my %s          = %{$s_href};
  my @h_array    = keys(%s);
  my $max_length = 0;
  for my $h (@h_array) {
    my $seq    = $s{$h};
    my $length = length($seq);
    if ( $length > $max_length ) {
      $max_length = $length;
    }
  }
  return $cutoff * $max_length;
}

#
# Check if file exists.  Returns 1 if true
#
sub check_file {
  my $filename = shift;
  my $result   = `if [ -f $filename ]; then echo 1; fi`;
  return trim($result);
}

#
# Removes leading and trailing whitespace from a string
#
sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

###  NOTE FROM ORIGINAL CODE ###
#
# if($prot_count < 10000){
#     $cmd = "/usr/local/bin/muscle -in $aa_file -fastaout $fasta_out -clwout $clw_out ";
# } else {
#     $cmd = "/usr/local/bin/muscle -in $aa_file -fastaout $fasta_out -clwout $clw_out -maxiters 1 -diags1 -sv ";
# }
#
################################

