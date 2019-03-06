package ncbi::ErrMsgs;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::ErrMsgs;

################################################################################
#
#			     Constant Class Methods
#
################################################################################

sub ERROR_HEADER { return 'GENBANK-ERROR: '; }

sub GENBANK_CAT           { return 100000; }    ### Genbank Processing Class
sub TAXONOMY_CAT          { return 101000; }    ### Taxonomy Class
sub DATABASESEQUENCES_CAT { return 102000; }    ### Influenza Class
sub DOWNLOAD_CAT          { return 103000; }    ### Download Class
sub UTILS_CAT             { return 104000; }    ### Utils Class
sub GENBANKFILE_CAT       { return 105000; }    ### GenbankFile Class
sub INFLUENZANA_CAT       { return 106000; }    ### Influenza Na Class
sub MONTHLY_CAT           { return 107000; }    ### Monthly Processing Class
sub PAXGENE_CAT           { return 108000; }    ### PAX Gene Processing Class
sub HXNYCLASSIFIER_CAT    { return 109000; }    ### HxNy Classifier Class
sub MATPEPTIDE_CAT        { return 110000; }    ### MatPeptide Class
sub GENOTYPE_CAT          { return 111000; }    ### Genotype Class
sub MSDCOMBINED_CAT       { return 112000; }    ### MsdCombined Class
sub LOADER_CAT            { return 113000; }    ### Loader Class
sub GENES_CAT             { return 114000; }    ### Genes Parent Class
sub LINK_CAT              { return 115000; }    ### Link Class

################################################################################
#
#			     Public Static Constant
#
################################################################################

sub ERROR_MSGS {
  my $errMsgs = {

    &GENBANK_CAT => {

      1 => "Cannot perform operation on file\n"
        . "  operation = __1__\n"
        . "  file      = __2__\n"
        . "  msg       = __3__",

    },

    &MONTHLY_CAT => {

      1 => "Cannot find Genbank delete file\n" . "  file = __1__",

    },

    &INFLUENZANA_CAT => {

      1 => "Cannot open influenza na file\n"
        . "  data_dir = __1__\n"
        . "  flu_file = __2__",

    },

    &GENBANKFILE_CAT => {

      1 => "File does not exist\n" . "  file = __1__",

    },

    &TAXONOMY_CAT => {

      1 => "Failed to execute taxon query\n" . "  query = __1__",

    },

    &DATABASESEQUENCES_CAT => {

      1 => "Failed to execute database sequence query\n" . "  query = __1__",

    },

    &DOWNLOAD_CAT => {

      5 => "Downloaded Files Not Ready, Terminating Immediately",

    },

    &LINK_CAT => {

      5 => "Link Files Not Ready, Terminating Immediately",

    },

    &UTILS_CAT => {

      1 => "Special property does not have a value\n" . "  property = __1__",

      2 => "Special property does not have correct format\n"
        . "  property = __1__\n"
        . "  value    = __2__",

      3 => "Parameter option not available to evaluate property\n"
        . "  property = __1__\n"
        . "  option   = __2__",

      4 => "Cannot perform operation on file\n"
        . "  operation = __1__\n"
        . "  file      = __2__\n"
        . "  msg       = __3__",

      5 => "Cannot get value from file\n" . "  msg = __1__",

      6 => "Cannot execute command\n" . "  cmd = __1__\n" . "  msg = __2__",

      7 => "Cannot get command result\n" . "  cmd = __1__",

      8 => "Cannot instantiate Genbank Class\n"
        . "  class  = __1__\n"
        . "  errMsg = __2__",
    },

    &GENES_CAT => {

      1 => "Failed to execute database sequence query\n" . "  query = __1__",

      2 => "Cannot perform operation on file\n"
        . "  operation = __1__\n"
        . "  file      = __2__\n"
        . "  msg       = __3__",

      3 => "Sequence has motif variant 'A', G', or 'T'\n" 
        . "  variant      = __1__\n"
        . "  gb_accession = __2__",

      4 => "Failed to update staging for pax\n",
      
      5 => "Failed to find motif in reference sequence!\n"
      . "seq = __1__", 

      6 => "Sequence has bad motif variant 'G'\n" 
        . "  variant      = __1__\n"
        . "  gb_accession = __2__",

    },

    &PAXGENE_CAT => {

      1 => "Failed to execute database sequence query\n" . "  query = __1__",

      2 => "Cannot perform operation on file\n"
        . "  operation = __1__\n"
        . "  file      = __2__\n"
        . "  msg       = __3__",

      3 => "Sequence has motif variant 'A', G', or 'T'\n" 
        . "  variant      = __1__\n"
        . "  gb_accession = __2__",

      4 => "Failed to update staging for pax\n",
      
      5 => "Failed to find motif in reference sequence!\n"
      . "seq = __1__", 

    },

    &HXNYCLASSIFIER_CAT => {

      1 => "Failed to execute database sequence query\n" . "  query = __1__",

      2 => "Unable to launch job\n" . "  acc  = __1__\n" . "  tool = __2__",

      3 => "Failed to update staging for HxNy classifier\n",

      4 => "Failed to compute all classifications for HxNy classifier\n",

    },

    &MATPEPTIDE_CAT => {

      1 => "Failed to update staging for MatPeptide\n",

    },

    &GENOTYPE_CAT => {

      1 => "Failed to update staging for Genotype\n",

    },

    &MSDCOMBINED_CAT => {},

    &LOADER_CAT => {

      1 => "Error updating staging\n"
        . "  query          = __1__\n"
        . "  gb_accession   = __2__\n"
        . "  na_sequence_id = __3__",

      2 => "Error generating sequence id\n"
        . "  query          = __1__\n"
        . "  gb_accession   = __2__\n"
        . "  na_sequence_id = __3__",

    },

  };
  ###
  ### Now add the util::ErrMsgs categories
  ###
  my $utilMsgs = util::ErrMsgs::ERROR_MSGS;
  while ( my ( $category, $msgs ) = each %{$utilMsgs} ) {
    $errMsgs->{$category} = $msgs;
  }
  return $errMsgs;

}

sub ERROR_CATS {
  return {
    &DATABASESEQUENCES_CAT => 'ncbi::DatabaseSequences',
    &DOWNLOAD_CAT          => 'ncbi::Download',
    &GENBANKFILE_CAT       => 'ncbi::GenbankFile',
    &GENBANK_CAT           => 'ncbi::Genbank',
    &GENOTYPE_CAT          => 'ncbi::Genotype',
    &HXNYCLASSIFIER_CAT    => 'ncbi::HxNyClassifier',
    &INFLUENZANA_CAT       => 'ncbi::Influenza',
    &LOADER_CAT            => 'ncbi::Loader',
    &MATPEPTIDE_CAT        => 'ncbi::MatPeptide',
    &MONTHLY_CAT           => 'ncbi::Monthly',
    &MSDCOMBINED_CAT       => 'ncbi::MsdCombined',
    &PAXGENE_CAT           => 'ncbi::PAXGene',
    &TAXONOMY_CAT          => 'ncbi::Taxonomy',
    &UTILS_CAT             => 'ncbi::Utils',
  };
}

################################################################################

1;

__END__

=head1 NAME

ErrMsgs.pm

=head1 SYNOPSIS

   use util::ErrMsgs;

   my $error_msgs  = ncbi::ErrMsgs::ERROR_MSGS;
   my $error_names = ncbi::ErrMsgs::ERROR_CATS;

=head1 DESCRIPTION

This static class returns the error message templates for parallel library.

=head1 CONSTANTS

The following constants define the pre-defined error message
categories define by this class.

   ncbi::ErrMsgs::GENBANK_CAT            -- ( 100000) Genbank Processing Class
   ncbi::ErrMsgs::TAXONOMY_CAT           -- ( 101000) Taxonomy Class
   ncbi::ErrMsgs::DATABASESEQUENCES_CAT  -- ( 102000) DatabaseSequences Class
   ncbi::ErrMsgs::DOWNLOAD_CAT           -- ( 103000) Download Class
   ncbi::ErrMsgs::UTILS_CAT              -- ( 104000) Utils Class
   ncbi::ErrMsgs::GENBANKFILE_CAT        -- ( 105000) Genbank File Class
   ncbi::ErrMsgs::INFLUENZANA_CAT        -- ( 106000) Influenza NA Class
   ncbi::ErrMsgs::MONTHLY_CAT            -- ( 107000) Monthly Class
   ncbi::ErrMsgs::PAXGENE_CAT            -- ( 108000) PAX Gene processing Class
   ncbi::HXNYCLASSIFIER_CAT              -- ( 109000) HxNy Classifier Processing Class
   ncbi::MATPEPTIDE_CAT                  -- ( 110000) MatPeptide Class
   ncbi::GENOTYPE_CAT                    -- ( 111000) Genotype Class
   ncbi::MSDCOMBINED_CAT                 -- ( 112000) MsdCombined Class
   ncbi::LOADER_CAT                      -- ( 113000) Loader Class

=head1 STATIC CLASS METHODS

=head2 B<util::ErrMsgs::ERROR_MSGS>

This method returns a data-structure acceptable to the class
L<util::ErrMsg> method B<addErrorMsgs> that deploys error messages to
error categories and numbers.

=head2 B<util::ErrMsgs::ERROR_CATS>

This method returns a data-structure acceptable to the class
L<util::ErrMsg> method B<addErrorCats> that deploys that deploys
category names for statistics reporting.

=cut

