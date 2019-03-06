package algo::H1N1NewPand;

use strict;
use warnings;
use Cwd 'chdir';
use algo::Algo;

our @ISA = qw(algo::Algo);

sub getClassification {
  my ($self, $sequenceFile) = @_;

  my $config = $self->config;
  my $classifierDir =
   join('',
       $config->getValue("TempDir"),
       $config->getValue("ClassifierDir"));
  chdir($classifierDir);  

  my $blastCmd = $self->{"blastall"};
  $blastCmd =~ s/<INPUTFILE>/$sequenceFile/;
  my $blastResult =  `$blastCmd`;

  print $blastResult if $self->{"blastout"} ;
  print $blastResult;

  my @perc=();
  my @Types=();
  my %count =();
  foreach my $row (split( /[\n\r]/, $blastResult)){
    my ( $n , $accession,  $percid, $cov ) = split( /\t/, $row );
    push(@perc,util::Utils::trim($percid));
    my $type = $self->getLookup($accession);
    push (@Types, $type);
    $count{$type} ++;
  }
  unless( defined $perc[0]){
    warn "$blastResult";
    return undef;
  }
  if (( keys %count) == 1){
    if($Types[0] eq "Other"){
      return "Other";
    } else {
      for(@perc){
        if($_ < 97){
          return "Other";
        }
      }
      return "NPDM";
    }
  } else {
    if($count{"Other"} >= $count{"NPDM"}){
      return "Other";
    } else {
      for(my $i=0;$i<scalar(@perc);$i++){
        if($Types[$i] eq "NPDM" && $perc[$i]<98){
          return "Other";
        }
      }
      return "NPDM";
    }
  }
}
1;
