package file::Index::Fasta;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Digest::SHA1;
use Pod::Usage;

use util::Constants;
use util::Defline;

use file::ErrMsgs;

use base 'file::Index';

use fields qw (
  defline
  tag
  type
  sha1_generator
);

################################################################################
#
#				   Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return file::ErrMsgs::FASTA_CAT; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _determineAccessionExpr {
  my ( $tag, $type, $defline_format, $error_mgr ) = @_;
  $error_mgr->exitProgram(
    ERR_CAT, 1,
    [ $defline_format, $type, $tag ],
    util::Constants::EMPTY_LINE($type) 
      || ( $type ne util::Defline::ALTID_TAG
      && $type ne util::Defline::DB_XREF_TAG
      && $type ne util::Defline::DEFLINE_TAG
      && $type ne util::Defline::HEAD_TAG )
      || ( util::Constants::EMPTY_LINE($tag)
      && $type ne util::Defline::HEAD_TAG )
  );
  my $accession_expr = util::Constants::EMPTY_STR;
  if ( $defline_format eq util::Defline::VBAR_FORMAT ) {
    $error_mgr->exitProgram(
      ERR_CAT, 2,
      [ $defline_format, $type, $tag ],
      $type ne util::Defline::DEFLINE_TAG
    );
    $accession_expr = $tag . '\|(\S+?)\|';
  }
  elsif ( $defline_format eq util::Defline::VBARCOLON_FORMAT ) {
    $error_mgr->exitProgram(
      ERR_CAT, 2,
      [ $defline_format, $type, $tag ],
      $type ne util::Defline::DEFLINE_TAG && $type ne util::Defline::HEAD_TAG
    );
    if ( $type eq util::Defline::DEFLINE_TAG ) {
      $accession_expr .= '\|$tag:(\S+?)\|';
    }
    elsif ( $type eq util::Defline::HEAD_TAG ) {
      $error_mgr->exitProgram( ERR_CAT, 2, [ $defline_format, $type, $tag ],
        !util::Constants::EMPTY_LINE($tag)
          && $tag ne util::Defline::NULL_VALUE );
      $accession_expr = '^>(\S+?)\|';
    }
  }
  elsif ( $defline_format eq util::Defline::RIKEN_FORMAT ) {
    $error_mgr->exitProgram(
      ERR_CAT, 2,
      [ $defline_format, $type, $tag ],
      $type ne util::Defline::ALTID_TAG && $type ne util::Defline::HEAD_TAG
    );
    if ( $type eq util::Defline::ALTID_TAG ) {
      $accession_expr .= "^>$tag" . '\|\S+?\|(\S+?)\|';
    }
    elsif ( $type eq util::Defline::HEAD_TAG ) {
      $accession_expr = "^>$tag" . '\|(\S+?)\|';
    }
  }
  elsif ( $defline_format eq util::Defline::STD_FORMAT ) {
    $accession_expr = ' \/';
    if ( $type eq util::Defline::ALTID_TAG ) {
      $accession_expr .= "$type=$tag" . '\|';
    }
    elsif ( $type eq util::Defline::DB_XREF_TAG ) {
      $accession_expr .= "$type=$tag" . ':';
    }
    elsif ( $type eq util::Defline::DEFLINE_TAG ) {
      $accession_expr .= "$tag=";
    }
    elsif ( $type eq util::Defline::HEAD_TAG ) {
      if ( $tag eq util::Defline::NULL_VALUE
        || util::Constants::EMPTY_LINE($tag) )
      {
        $accession_expr = '^>(\S+)';
      }
      else {
        $accession_expr = "^>$tag" . '\|(\S+)';
      }
    }
    $accession_expr .= '(\S+)( \/|$)'
      if ( $type ne util::Defline::HEAD_TAG );
  }
  return $accession_expr;
}

sub _deflineSeq {
  my file::Index::Fasta $this = shift;
  my ($entity) = @_;
  my @lines       = split( "\n", $entity );
  my $defline_str = $lines[0];
  my $seq         = join( util::Constants::EMPTY_STR, @lines[ 1 .. $#lines ] );
  my $defline_seq = {
    defline => $defline_str,
    seq     => $seq,
  };
  return $defline_seq;
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new {
  my ( $that, $tag, $type, $defline_format, $error_mgr ) = @_;
  ###
  ### Instantiate the object
  ###
  my file::Index::Fasta $this =
    $that->SUPER::new( '>',
    _determineAccessionExpr( $tag, $type, $defline_format, $error_mgr ),
    $error_mgr );

  $this->{tag}            = $tag;
  $this->{type}           = $type;
  $this->{defline}        = new util::Defline( $error_mgr, $defline_format );
  $this->{sha1_generator} = Digest::SHA1->new;

  return $this;
}

sub readDeflineSeq {
  my file::Index::Fasta $this = shift;
  my ($accession)             = @_;
  my $entity                  = $this->readIndex($accession);
  return $this->_deflineSeq($entity);
}

sub readCurrentDeflineSeq {
  my file::Index::Fasta $this = shift;
  my $entity = $this->readCurrent;
  return $this->_deflineSeq($entity);
}

sub parseDefline {
  my file::Index::Fasta $this = shift;
  my ($defline_str) = @_;
  $this->{defline}->parseDefline( $defline_str, ref($this) );
  return $this->{defline};
}

sub sha1 {
  my file::Index::Fasta $this = shift;
  my ($seq) = @_;
  return undef if ( util::Constants::EMPTY_LINE($seq) );
  $this->{sha1_generator}->digest;
  $this->{sha1_generator}->add($seq);
  return $this->{sha1_generator}->hexdigest;
}

sub defline {
  my file::Index::Fasta $this = shift;
  return $this->{defline};
}

sub tag {
  my file::Index::Fasta $this = shift;
  return $this->{tag};
}

sub type {
  my file::Index::Fasta $this = shift;
  return $this->{type};
}

################################################################################

1;

__END__

=head1 NAME

Fasta.pm

=head1 SYNOPSIS

   use file::Index::Fasta;

=head1 DESCRIPTION

This class defines the mechanism for generating indices for fasta text
data files.

=head1 METHODS

=head2 B<new file::Index::Fasta(tag, type, defline_format, error_mgr)>

This method is the constructor for the class.  It sets up the
information necessary for creating an index for a fasta file The
B<entity_expr> is is defined to be '>' and the B<accession_expr> is
defined by B<tag> and B<type> as follows:

   type     accession_expr for tag
   -------  -----------------------------
   altid    ' \/altid=tag\|(\S+)( \/|$)'
   db_xref  ' \/db_xref=tag:(\S+)( \/|$)'
   defline  ' \/tag=(\S+)( \/|$)'
   head     '^>tag\|(\S+) '

The B<defline_format> parameter specifies the defline format (std,
vbar, or riken)

=head1 GETTER METHODS

The following methods find an index and return the entity associated
with an index.

=head2 B<$defline_obj = defline>

The method returns the defline parsing object.  The defline object is
an instance of the class L<util::Defline>.

=head2 B<$tag = tag>

The method returns the tag attribute.

=head2 B<$type = type>

This method returns the type method.

=head2 B<$defline_obj = parseDefline(defline_str)>

The method return the defline object after the defline string is
parsed.  The defline object is an instance of the class
L<util::Defline>.

=head2 B<$sha1 = sha1(seq)>

The method return sha1 value for a given sequence.  It returns undef
if the sequence is empty or undefined.

=head2 B<$defline_seq_struct = readDeflineSeq(accession)>

This method returns the data-structure containing the defline and
sequence strings for the entity in the file associated with accession
via the index mapping.  The data-structure is a reference hash with
the following components:

   defline -- The defline 'as-is' from the file without a newline
   seq     -- Full sequence without newlines from the file

=cut
