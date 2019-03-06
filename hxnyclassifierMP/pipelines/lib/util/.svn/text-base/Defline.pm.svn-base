package util::Defline;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;
use Pod::Usage;

use util::Constants;
use util::Msg;
use util::PerlObject;

use fields qw(
  altid
  db_xref
  defline
  defline_format
  duplicate_tags
  head
  id
  msg
  separator
  serializer
);

################################################################################
#
#				Constant Methods
#
################################################################################
###
### Defline Types
###
sub RIKEN_FORMAT     { return 'riken'; }
sub STD_FORMAT       { return 'std'; }
sub VBAR_FORMAT      { return 'vbar'; }
sub VBARCOLON_FORMAT { return 'vbarcolon'; }

sub IS_FORMAT_TYPE {
  my ($type) = @_;
  return ( $type eq RIKEN_FORMAT
      || $type eq STD_FORMAT
      || $type eq VBAR_FORMAT
      || $type eq VBARCOLON_FORMAT );
}

sub DEFLINE_TYPES {
  return ( RIKEN_FORMAT, STD_FORMAT, VBAR_FORMAT, VBARCOLON_FORMAT );
}

sub DEFLINE_SEPARATORS {
  return (
    &RIKEN_FORMAT     => ' |\|',
    &STD_FORMAT       => ' \/',
    &VBAR_FORMAT      => '\|',
    &VBARCOLON_FORMAT => '\|'

  );
}
###
### Defline Tags
###
sub ALTID_TAG   { return 'altid'; }
sub DB_XREF_TAG { return 'db_xref'; }
sub DEFLINE_TAG { return 'defline'; }
sub HEAD_TAG    { return 'head'; }

sub IS_DEFLINE_TAG_TYPE {
  my ($type) = @_;
  return ( $type eq ALTID_TAG
      || $type eq DB_XREF_TAG
      || $type eq DEFLINE_TAG
      || $type eq HEAD_TAG );
}

sub DEFLINE_TAG_TYPES {
  return ( HEAD_TAG, DEFLINE_TAG, ALTID_TAG, DB_XREF_TAG );
}
###
### Null Head
###
sub NULL_VALUE { return 'NULL'; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _addTagValue {
  my util::Defline $this = shift;
  my ( $tag, $value, $type ) = @_;
  my $tags = $this->{$type};
  if ( $this->isDuplicateTag( $tag, $type ) ) {
    if ( !defined( $tags->{$tag} ) ) { $tags->{$tag} = []; }
    push( @{ $tags->{$tag} }, $value );
  }
  else {
    $tags->{$tag} = $value;
  }
}

sub _parseDefline {
  my util::Defline $this = shift;
  my (@comps) = @_;
  ###
  ### First, Compute Head
  ###
  if ( $comps[0] !~ /^\// ) {
    my $head  = shift(@comps);
    my $key   = undef;
    my $value = undef;
    if ( $head =~ /^(\w+?)\|(.+)$/ ) {
      $key   = $1;
      $value = $2;
    }
    else {
      $key   = NULL_VALUE;
      $value = $head;
    }
    $this->{head}->{$key} = $value;
  }
  ###
  ### Second, Compute Tags
  ###
  foreach my $comp (@comps) {
    if ( $comp =~ /^\/?(\w+?)=(.+)$/ ) {
      my $key   = $1;
      my $value = $2;
      my $type  = undef;
      if ( $key eq ALTID_TAG ) {
        $type = $key;
        my @values = ();
        ( $key, @values ) = split( /\|/, $value );
        $value = join( '|', @values );
        $value =~ s/\|$//;
      }
      elsif ( $key eq DB_XREF_TAG ) {
        $type = $key;
        my @values = ();
        ( $key, @values ) = split( /:/, $value );
        $value = join( ':', @values );
        $value =~ s/:$//;
      }
      else {
        $type = DEFLINE_TAG;
      }
      $this->_addTagValue( $key, $value, $type );
    }
  }
}

sub _parseVbarDefline {
  my util::Defline $this = shift;
  my (@comps)            = @_;
  my $num_comps          = scalar @comps;
  my $num_pairs          = int( $num_comps / 2 );
  ###
  ### First, acc definition if there is one
  ###
  if ( $num_comps != $num_pairs ) {
    $this->_addTagValue( 'definition', $comps[$#comps], DEFLINE_TAG );
  }
  ###
  ### First group components by pairs
  ###
  foreach my $tag_num ( 1 .. $num_pairs ) {
    my $key   = $comps[ 2 * $tag_num - 2 ];
    my $value = $comps[ 2 * $tag_num - 1 ];
    $this->_addTagValue( $key, $value, DEFLINE_TAG );
  }
}

sub _parseVbarColonDefline {
  my util::Defline $this = shift;
  my (@comps) = @_;
  return if ( @comps == 0 );
  ###
  ### First, get head
  ###
  $this->{head}->{&NULL_VALUE} = $comps[0];
  ###
  ### First group components by pairs
  ###
  foreach my $index ( 1 .. $#comps ) {
    my ( $key, $value ) = split( /:/, $comps[$index] );
    $this->_addTagValue( $key, $value, DEFLINE_TAG );
  }
}

sub _parseRikenDefline {
  my util::Defline $this = shift;
  my (@comps)            = @_;
  my $tag                = shift(@comps);
  my $head_id            = shift(@comps);
  my $alt_id             = shift(@comps);
  my $seq_length         = shift(@comps);

  $this->{head}->{$tag} = $head_id;
  $this->_addTagValue( $tag,         $alt_id,     ALTID_TAG );
  $this->_addTagValue( 'seq_length', $seq_length, DEFLINE_TAG );
  ###
  ### First group components by pairs
  ###
  foreach my $tag_value (@comps) {
    my ( $tag, $value ) = split( '=', $tag_value );
    $this->_addTagValue( $tag, $value, DEFLINE_TAG );
  }
}

################################################################################
#
#				Defline Methods
#
################################################################################

sub new($;$$) {
  my util::Defline $this = shift;
  my ( $msg, $defline_format ) = @_;
  $this = fields::new($this) unless ref($this);

  $defline_format =
    ( !util::Constants::EMPTY_LINE($defline_format) )
    ? $defline_format
    : STD_FORMAT;

  $this->{defline_format} =
    IS_FORMAT_TYPE($defline_format) ? $defline_format : STD_FORMAT;

  my %separators = DEFLINE_SEPARATORS;
  $this->{separator} = $separators{ $this->{defline_format} };

  $this->{altid}      = {};
  $this->{db_xref}    = {};
  $this->{defline}    = {};
  $this->{head}       = {};
  $this->{id}         = '__undefined__';
  $this->{msg}        = ( !defined($msg) || !ref($msg) ) ? new util::Msg : $msg;
  $this->{serializer} = new util::PerlObject( undef, undef, $this->{msg} );

  $this->{duplicate_tags} = {};
  foreach my $tag (DEFLINE_TAG_TYPES) {
    next if ( $tag eq HEAD_TAG );
    $this->{duplicate_tags}->{$tag} = {};
  }

  return $this;
}
###
### Allowing duplicate tags
###
sub addDuplicateTag {
  my util::Defline $this = shift;
  my ( $duplicate_tag, $type ) = @_;
  ###
  ### Set the default type (defline) if not provided
  ### and immediate return if type is HEAD_TAG
  ###
  $type = util::Constants::EMPTY_LINE($type) ? DEFLINE_TAG : $type;

  return if ( !IS_DEFLINE_TAG_TYPE($type)
    || $type eq HEAD_TAG );
  ###
  ### Disallow standard tags
  ###
  $this->{duplicate_tags}->{$type}->{$duplicate_tag} =
    util::Constants::EMPTY_STR;
}

sub isDuplicateTag {
  my util::Defline $this = shift;
  my ( $duplicate_tag, $type ) = @_;
  ###
  ### Set the default type (defline) if not provided
  ### and immediate return if type is HEAD_TAG
  ###
  $type = util::Constants::EMPTY_LINE($type) ? DEFLINE_TAG : $type;

  return util::Constants::FALSE
    if ( !IS_DEFLINE_TAG_TYPE($type)
    || $type eq HEAD_TAG );

  my $duplicate_tags = $this->{duplicate_tags}->{$type};
  return defined( $duplicate_tags->{$duplicate_tag} );
}

sub removeDuplicateTag {
  my util::Defline $this = shift;
  my ( $duplicate_tag, $type ) = @_;
  ###
  ### Set the default type (defline) if not provided
  ### and immediate return if type is HEAD_TAG
  ###
  $type = util::Constants::EMPTY_LINE($type) ? DEFLINE_TAG : $type;

  return if ( !IS_DEFLINE_TAG_TYPE($type)
    || $type eq HEAD_TAG );

  my $duplicate_tags = $this->{duplicate_tags}->{$type};
  return if ( !defined( $duplicate_tags->{$duplicate_tag} ) );
  delete( $duplicate_tags->{$duplicate_tag} );
}

sub serializeObject {
  my util::Defline $this = shift;
  foreach
    my $attr ( 'altid', 'db_xref', 'defline', 'head', 'id', 'duplicate_tags' )
  {
    $this->{msg}->printMsg(
      "attr = $attr\n"
        . $this->{serializer}->serializeObject(
        $this->{$attr}, util::PerlObject::PERL_OBJECT_WRITE_OPTIONS
        )
    );
  }
}
###
### This method parses the defline for the id replacing the old defline,
### if any.  The parse generates the following sets of tags head, defline,
### altid, and db_xref.
###
sub parseDefline {
  my util::Defline $this = shift;
  my ( $defline_str, $id ) = @_;
  $this->{altid}   = {};
  $this->{db_xref} = {};
  $this->{defline} = {};
  $this->{head}    = {};
  $this->{id}      = $id;
  return if ( !defined($defline_str) );
  my $whitespace = util::Constants::WHITESPACE;
  $defline_str =~ s/^$whitespace//;
  $defline_str =~ s/$whitespace$//;
  return if ( $defline_str eq util::Constants::EMPTY_STR );
  $defline_str =~ s/^>//;
  my $separator = $this->{separator};
  my @comps = split( /$separator/, $defline_str );
  $this->_parseDefline(@comps) if ( $this->{defline_format} eq STD_FORMAT );
  $this->_parseRikenDefline(@comps)
    if ( $this->{defline_format} eq RIKEN_FORMAT );
  $this->_parseVbarDefline(@comps)
    if ( $this->{defline_format} eq VBAR_FORMAT );
  $this->_parseVbarColonDefline(@comps)
    if ( $this->{defline_format} eq VBARCOLON_FORMAT );
}
###
### This method returns a value for a tag.  If the tag does not
### exist, it returns the default.  The tag is searched in the type
### set (head, defline, altid, db_xref).  If the type is undefined
### (undef), then all sets are search in the following order: head,
### defline, altid, db_xref.
###
sub getValue {
  my util::Defline $this = shift;
  my ( $tag, $default, $type ) = @_;
  return $default if ( defined($type) && !IS_DEFLINE_TAG_TYPE($type) );
  $tag = util::Constants::EMPTY_LINE($tag) ? NULL_VALUE : $tag;
  my $value = undef;
  if ( util::Constants::EMPTY_LINE($type) ) {
    $type = 'ALL_TYPES';
    foreach my $tag_type (DEFLINE_TAG_TYPES) {
      $value = $this->{$tag_type}->{$tag};
      last if ( defined($value) );
    }
  }
  else {
    $value = $this->{$type}->{$tag};
  }
  if ( util::Constants::EMPTY_LINE($value) ) {
    $this->{msg}
      ->printDebug( "No $type tag = $tag for identifer = " . $this->{id} );
    return $default;
  }
  if ( $this->isDuplicateTag( $tag, $type ) ) { $value = [ @{$value} ]; }
  return $value;
}
###
### This method returns a value for a tag and a type (may be undefined--undef).
### If the tag does not exist, it returns an NULL string (i.e., an empty
### string--'').
###
sub getValueOrNull {
  my util::Defline $this = shift;
  my ( $tag, $type ) = @_;
  return $this->getValue( $tag, util::Constants::EMPTY_STR, $type );
}
###
### This method returns a value for a tag and type (may be undefined--undef).
### If the tag does not exist, it returns Zero (0).
###
sub getValueOrZero {
  my util::Defline $this = shift;
  my ( $tag, $type ) = @_;
  return $this->getValue( $tag, 0, $type );
}
###
### This method returns the list of tags associated with the type (head,
### defline, altid, or db_xref).
###
sub getTags {
  my util::Defline $this = shift;
  my ($type)             = @_;
  my @tags               = ();
  return @tags if ( !IS_DEFLINE_TAG_TYPE($type) );
  push( @tags, keys %{ $this->{$type} } );
  return @tags;
}
################################################################################

1;

__END__

=head1 NAME

Defline.pm

=head1 SYNOPSIS

   use util::Defline;
   use util::ErrMgr;
   use util::ErrMsgs;

   my $error_mgr = new util::ErrMgr
   $error_mgr->addErrorMsgs(util::ErrMsgs::ERROR_MSGS);

   my $defl_obj = new util::Defline($error_mgr);
   ...

   $cds->parseDefline($str);
   $altid_value   = $cds->getValueOrNull($tag, util::Defline::ALTID_TAG);
   $db_xref_value = $cds->getValueOrNull($tag, util::Defline::DB_XREF_TAG);
   $regular_value = $cds->getValueOrNull($tag, util::Defline::DEFLINE_TAG);
   $header_value  = $cds->getValueOrNull($tag, util::Defline::HEAD_TAG);

=head1 DESCRIPTION

This module exports the static constant methods for all deflines and
methods for parsing deflines and accessing the tags.

=head1 CLASS METHODS

The following constants define the defline tags:

   util::Defline::ALTID_TAG   -- altid   tags
   util::Defline::DB_XREF_TAG -- db_xref tags
   util::Defline::DEFLINE_TAG -- defline tags
   util::Defline::HEAD_TAG    -- head tag

These tags occur in a defline as follows:

   util::Defline::ALTID_TAG   -- /altid=foo|123 /altid=bar345
   util::Defline::DB_XREF_TAG -- /db_xref=GeneID:123 db_xref=GI:234
   util::Defline::DEFLINE_TAG -- /ga_uid=123 /entity_uid=110003
                                 |GI|12345.3|
                                 |gi:12345.3|
   util::Defline::HEAD_TAG    -- CRA|123

=head1 DEFLINE COMPONENTS

A defline component is either the string between two "/" characters in
a defline, the string following the last "/" in a defline, or, for a
HEAD tag, a string appearing after an initial ">" character (if any)
and before the first "/" character in the defline. The component may
consist of up to three parts, a type, a tag, and a value.

The type of the defline component is explicit (for ALTID_TAG and
DB_XREF_TAG) or implicit (for DEFLINE_TAG and HEAD_TAG). For the altid
and db_xref types the type is simply the string "altid=" or "db_xref="
following the "/" character. A HEAD_TAG type is implicit in that the
component appears between the initial ">" character in the defline (if
any) and the first "/" character.  The DEFLINE_TAG type is implicit in
that a "/" character is not followed by either "altid=" or "db_xref=".
How tags and values are parsed from the component depends on the
type. The parsing specific for each type is specified below.

=head2 ALTID TAG

For the altid tag type, the tag consists of the string to the right of
"/altid=" and to the left of "|". The value consists of the string to
the right "|" and to the left of the next "/" character (or end of the
defline). A missing "|" results in the tag being the entire component
string to the right of "/altid=" and the value being undef.

For the example given in the CLASS METHODS section the altid tags are
"foo" and "bar345 and the values are "123" and undef.

=head2 DB_XREF TAG

For the db_xref tag type, the tag consists of the string to the right
of "/db_xref=" and to the left of ":". The value consists of the
string to the right of ":" and to the left of the next "/" character
(or end of the defline).  A missing ":" results in the tag being the
entire component string to the right of "/db_xref=" and the value
being undef.

=head2 DEFLINE TAG

For the defline tag type the tag is the string to the right of "/" and
to the left of "=".  The value is the portion of the component string
to the right of "=".  A missing "=" character results in no tag or
value being defined for that defline component.

In the example given in the CLASS METHODS section, the tags are
"ga_uid" and "entity_uid" and the values are "123" and "110003".

=head2 HEAD TAG

For the head tag, the tag consists of the string between an initial
">" character (if any) and the "|" character. The value consists of
the string between "|" and the first "/" character in the defline (or
the end of the defline if it has no "/" characters).  If the "|"
character is missing from a head tag defline component, then neither
tag nor value is defined for the head tag defline component.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new util::Defline([msg[, defline_format]])>

This method is the constructor for the class can take an optional
messaging object.  If one is not provided, it creates its own.  The
defline format is defined by the B<defline_format>.  If not provided
or not one of B<std>, B<vbar>, or B<riken>, then B<std> is assumed.

=head2 B<parseDefline(str[, id])>

This method parses the string into the tag set based on the tag types
defined above.  Also, it manages duplicate tags as explained below in
L<"SETTER METHODS">.  The gettter methods in L<"GETTER METHODS"> are
used to access the tag values for the parsed defline.  This method
can be executed several times for different strings.

=head1 SETTER METHODS

The following setter methods are exported by this class.

=head2 B<addDuplicateTag(duplicate_tag[, type])>

This method sets a defline tag (DEFLINE_TAG) as a duplicating tag.
That is, this tag can repeat several times on the defline.

Normally getters only return a scalar string value if duplicate tag is
not set for the tag.  This means if there are duplicates in the
defline only the last one is retained. Initially, all tags
(DEFLINE_TAG, ALTID_TAG, and DB_XREF_TAG) are not duplicate.

If this is not the default behavior you require on a tag that is
duplicated, then you must identify it as a dulicate tag before
parsing.  This works on DEFLINE_TAG, ALTID_TAG, and DB_XREF_TAG tags.
The value returned on a getter for a duplicate tag is either the
default value or a reference to a list of duplicates (one or more).

If the type is not defined, then the default type is DEFLINE_TAG.

=head2 B<removeDuplicateTag(duplicate_tag[, type])>

This method removes a tag for a given tag type from the duplicates tag list.
The tag type can be DEFLINE_TAG, ALTID_TAG, or DB_XREF_TAG.  The default type is
DEFLINE_TAG.

=head1 GETTER METHODS

The following setter methods are exported by this class.  In each
method the $tag parameter is a value that has been parsed from the
defline as discussed in the DEFLINE COMPONENTS section.

=head2 B<isDuplicateTag(duplicate_tag[, type])>

This method returns TRUE (1) if the tag is set to duplicating, otherwise it
returns FALSE (1).  The type can be DEFLINE_TAG, ALTID_TAG, or DB_XREF_TAG.  The
default type is DEFLINE_TAG.

=head2 B<getValue(tag[, default[, type]])>

This method returns the value of the tag of the given type that occurs
in the currently parsed defline string.  If the tag does not occur in
the string, then the default is returned.  If the default is not
provided, then the default is considered to undef.  If the type is not
defined, then the tag types are interrogated in the following order:

   util::Defline::HEAD_TAG
   util::Defline::DEFLINE_TAG
   util::Defline::ALTID_TAG
   util::Defline::DB_XREF_TAG

For defline tags (DEFLINE_TAG) that are set to duplicates, the value
will be a reference to a list of duplicates (one or more).

=head2 B<getValueOrNull(tag[, type])>

This method returns the value of the tag of the given type that occurs
in the currently parsed defline string.  If the tag does not occur in
the string, then an empty string is returned.  If the type is not
defined, then the tag types are interrogated in the following order:

   util::Defline::HEAD_TAG
   util::Defline::DEFLINE_TAG
   util::Defline::ALTID_TAG
   util::Defline::DB_XREF_TAG

For defline tags (DEFLINE_TAG) that are set to duplicates, the value
will be a reference to a list of duplicates (one or more).

=head2 B<getValueOrZero(tag[, type])>

This method returns the value of the tag of the given type that occurs
in the currently parsed defline string.  If the tag does not occur in
the string, then zero (0) is returned.  If the type is not
defined, then the tag types are interrogated in the following order:

   util::Defline::HEAD_TAG
   util::Defline::DEFLINE_TAG
   util::Defline::ALTID_TAG
   util::Defline::DB_XREF_TAG

For defline tags (DEFLINE_TAG) that are set to duplicates, the value
will be a reference to a list of duplicates (one or more).

=head2 B<getTags(type)>

For the given tag type, this method returns the unreferenced list of
tags that occurred in the currently parsed defline string.

=cut
