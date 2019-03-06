package ncbi::GenbankFile;
######################################################################
#                  Copyright (c) 2012 Northrop Grumman.
#                          All rights reserved.
######################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use ncbi::ErrMsgs;

use fields qw(
  error_mgr
  family_names
  fh
  ncbi_utils
  patterns
  previous_fs
  record
  separator
  seq_types
  source_type
  struct
  tools
  utils
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Genbank Sequence File Specifics
###
sub NC_RECORD_SEPARATOR { return 'LOCUS '; }

sub NC_RECORD_PATTERNS {
  return [
    [ '^\s+\/db_xref="taxon:(\d+)"$', [ 'taxon_id', ] ],
    [ '^\s+\/organism="(.+)"$',       [ 'source_organism', ] ],
    [
      '^LOCUS\s+(\S+)\s+.+ (\w+)\s+(\d\d-\w+-\d\d\d\d)$',
      [ 'locus', 'seq_type', 'date', ]
    ],
    [ '^ACCESSION\s+(\S+).*$',     [ 'gb_accession', ] ],
    [ '^SOURCE\s+(.+)$',                  [ 'source_type', ] ],
    [ '^\s+ORGANISM\s+(.+\.)\nREFERENCE', [ 'organism', ] ],
  ];
}
###
### Error Category
###
sub ERR_CAT { return ncbi::ErrMsgs::GENBANKFILE_CAT; }

################################################################################
#
#			    Private Methods
#
################################################################################

sub _setSeqTypes {
  my ncbi::GenbankFile $this = shift;

  my $ncbi_utils = $this->{ncbi_utils};
  my $properties = $ncbi_utils->getProperties;
  my $seq_type   = $properties->{seqType};

  foreach my $seqType ( @{$seq_type} ) {
    $this->{seq_types}->{$seqType} = util::Constants::EMPTY_STR;
  }
}

sub _setFamilyNames {
  my ncbi::GenbankFile $this = shift;

  my $ncbi_utils   = $this->{ncbi_utils};
  my $properties   = $ncbi_utils->getProperties;
  my $family_names = $properties->{familyNames};

  foreach my $familyName ( @{$family_names} ) {
    $this->{family_names}->{$familyName} = util::Constants::EMPTY_STR;
  }
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my ncbi::GenbankFile $this = shift;
  my ( $error_mgr, $tools, $utils, $ncbi_utils ) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{error_mgr}    = $error_mgr;
  $this->{family_names} = {};
  $this->{fh}           = new FileHandle;
  $this->{ncbi_utils}   = $ncbi_utils;
  $this->{patterns}     = NC_RECORD_PATTERNS;
  $this->{previous_fs}  = util::Constants::NEWLINE;
  $this->{record}       = undef;
  $this->{separator}    = NC_RECORD_SEPARATOR;
  $this->{seq_types}    = {};
  $this->{struct}       = undef;
  $this->{source_type}  = $ncbi_utils->getProperties->{sourceType};
  $this->{tools}        = $tools;
  $this->{utils}        = $utils;

  $this->_setSeqTypes;
  $this->_setFamilyNames;

  return $this;
}

sub eof {
  my ncbi::GenbankFile $this = shift;

  return $this->{fh}->eof;
}

sub open {
  my ncbi::GenbankFile $this = shift;
  my ($file) = @_;

  my $utils = $this->{utils};

  $this->{error_mgr}
    ->exitProgram( ERR_CAT, 1, [ $file, ], !-e $file || !-f $file || -z $file );
  ###
  ### Open the file
  ###
  $this->close;
  $this->{previous_fs} = $/;
  $/                   = $this->{separator};
  $this->{fh}          = $utils->openFile( $file, '<' );
}

sub close {
  my ncbi::GenbankFile $this = shift;

  return if ( !defined( $this->{fh}->fileno ) );
  $/ = $this->{previous_fs};
  $this->{previous_fs} = util::Constants::NEWLINE;
  $this->{fh}->close;
}

sub nextRecord {
  my ncbi::GenbankFile $this = shift;

  $this->{record} = undef;
  $this->{struct} = {};

  my $familyNames = $this->{family_names};

  my $record = $this->{fh}->getline;
  chomp($record);
  return undef if ( util::Constants::EMPTY_LINE($record) );
  $this->{record} = $this->{separator} . $record;
  $this->{struct} =
    $this->{utils}->getAllPatternInfo( $this->{record}, $this->{patterns} );
  ###
  ### Now generate family names
  ###
  my @rows = split( /\n/, $this->{struct}->{organism} );
  my $family_name = undef;
FAMILY_NAMES_LOOP:
  foreach my $row (@rows) {
    $row =~ s/^\s+//;
    $row =~ s/(\.|;)$//;
    my @fnames = split( /; /, $row );
    foreach my $fname (@fnames) {
      next if ( !defined( $familyNames->{$fname} ) );
      $family_name = $fname;
      last FAMILY_NAMES_LOOP;
    }
  }
  if ( defined($family_name) ) {
    $this->{struct}->{family_name} = $family_name;
  }
}

sub getRecord {
  my ncbi::GenbankFile $this = shift;

  return $this->{record};
}

sub getStruct {
  my ncbi::GenbankFile $this = shift;

  return $this->{struct};
}

sub recordDefined {
  my ncbi::GenbankFile $this = shift;

  return util::Constants::FALSE
    if ( util::Constants::EMPTY_LINE( $this->{record} )
    || util::Constants::EMPTY_LINE( $this->{struct}->{gb_accession} ) );
  return util::Constants::TRUE;
}

sub permissibleStruct {
  my ncbi::GenbankFile $this = shift;
  my ($struct) = @_;

  my $seq_types         = $this->{seq_types};
  my $source_type       = $this->{source_type};
  my $source_having     = $this->{source_type}->{having};
  my $source_not_having = $this->{source_type}->{not_having};

  return ( defined( $seq_types->{ $struct->{seq_type} } )
      && $struct->{source_type} =~ /$source_having/i
      && $struct->{source_type} !~ /$source_not_having/i
      && defined( $struct->{family_name} ) )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}

################################################################################
1;

__END__

=head1 NAME

GenbankFile.pm

=head1 SYNOPSIS

  use ncbi::GenbankFile;

=head1 DESCRIPTION

This class defines a standard mechanism for reading Genbank files
for extracting flu sequence records from genbank data.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new ncbi::GenbankFile( error_mgr, tools, utils, ncbi_utils)>

This is the constructor for the class.

=cut
