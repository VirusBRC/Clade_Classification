package util::blastf;

use strict;
use warnings;
use Carp;
use Data::Dumper;

sub getLookupTable {
  my ( $config, $db_handler ) = @_;

  my $tempDir       = $config->getValue("TempDir");
  my $classifierDir = $tempDir . "/" . $config->getValue("ClassifierDir");
  my $type          = $config->getValue("Type");
  my $cacheFile     = $config->getValue("lookupfile");

  unless ( -e $cacheFile ) {
    $cacheFile = "$classifierDir/$type.cached";
  }
  my $lookUp  = {};
  my $rebuild = 1;
  if ( -e $cacheFile ) {
    open( CACHE, "<$cacheFile" ) or die "Cannot open $cacheFile";
    $rebuild = 0;
    if ( defined($db_handler) && ( time() - ( stat(CACHE) )[9] ) > 86400 ) {
      $rebuild = 1;
    }
    else {
      while (<CACHE>) {
        chomp $_;
        next unless $_ =~ /\w/;
        my @array = split( "\t", $_ );
        $array[0] =~ s/\s+//g;
        $array[1] =~ s/\s+//g;
        $lookUp->{ $array[0] } = $array[1];
      }
      if ( scalar keys %{$lookUp} == 0 ) {
        warn "cache file: [$cacheFile] is empty! Rebuilding";
        $rebuild = 1;
      }
    }
    close CACHE if -e $cacheFile;
  }

  if ( $rebuild && defined $db_handler ) {
    my $blastset = $config->getValue("Type");
    my $sql      =
"select accession, blastvalue from blast_info where blastset = '$blastset'";
    my @resultRow = @{ $db_handler->getResult($sql) };
    open CACHE, ">$cacheFile" or die "Cannot open $cacheFile";
    foreach my $row (@resultRow) {
      if ( !exists( $lookUp->{ $row->[0] } ) ) {
        $lookUp->{ $row->[0] } = $row->[1];
        print CACHE "$row->[0]\t$row->[1]\n";
      }
    }
    close CACHE;
  }
  return $lookUp;
}

1;
