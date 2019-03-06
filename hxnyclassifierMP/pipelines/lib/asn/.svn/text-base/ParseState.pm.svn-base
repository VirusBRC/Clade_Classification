package asn::ParseState;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use util::Constants;

use fields qw (
  char
  col_num
  cur_line_size
  error_mgr
  line_num
  lines
  size
  token
);

################################################################################
#
#				   Constants
#
################################################################################
###
### Special Tokens
###
sub TAG_OPEN  { return '{'; }
sub TAG_CLOSE { return '}'; }
sub TAG_COMMA { return ','; }
###
###
###
my $_REMOVE_FORMAT_EFFECTORS_PATTERN = join( '|',
  util::Constants::CARRIAGE_RETURN, util::Constants::FORM_FEED,
  util::Constants::NEWLINE,         util::Constants::TAB );

################################################################################
#
#			     Private Methods
#
################################################################################

sub isWhiteSpace {
  my asn::ParseState $this = shift;
  my ($char) = @_;
  return ( $char eq util::Constants::CARRIAGE_RETURN
      || $char eq util::Constants::FORM_FEED
      || $char eq util::Constants::NEWLINE
      || $char eq util::Constants::SPACE
      || $char eq util::Constants::TAB );
}

sub isDelimiter {
  my asn::ParseState $this = shift;
  my ($char) = @_;
  return ( $char eq TAG_CLOSE || $char eq TAG_COMMA || $char eq TAG_OPEN );
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new {
  my asn::ParseState $this = shift;
  my ( $lines, $line_num, $col_num, $error_mgr ) = @_;
  $this = fields::new($this) unless ref($this);
  $this->{char}          = undef;
  $this->{col_num}       = int($col_num);
  $this->{cur_line_size} = 0;
  $this->{error_mgr}     = $error_mgr;
  $this->{line_num}      = int($line_num);
  $this->{lines}         = $lines;
  $this->{size}          = scalar @{$lines};
  $this->{token}         = undef;
  if ( $this->{line_num} < $this->{size} ) {
    $this->{cur_line_size} = length( $this->{lines}->[$line_num] );
  }

  return $this;
}

sub nextChar {
  my asn::ParseState $this = shift;
  $this->{char} = undef;
  my $next_char = util::Constants::FALSE;
  while ( $this->{line_num} < $this->{size} ) {
    if ( $this->{col_num} < $this->{cur_line_size} ) {
      $this->{char} =
        substr( $this->{lines}->[ $this->{line_num} ], $this->{col_num}, 1 );
      $next_char = util::Constants::TRUE;
      $this->{col_num}++;
      last;
    }
    else {
      $this->{line_num}++;
      $this->{col_num} = 0;
      if ( $this->{line_num} < $this->{size} ) {
        $this->{cur_line_size} =
          length( $this->{lines}->[ $this->{line_num} ] );
      }
    }
  }
  return $next_char;
}

sub nextToken {
  my asn::ParseState $this = shift;
  $this->{token} = util::Constants::EMPTY_STR;
  my $on_comment = undef;
  ###
  ### Skip white space
  ###
  while ( $this->nextChar ) {
    my $char = $this->getChar;
    next if ( $this->isWhiteSpace($char) );
    ###
    ### Short circuit return if delimiter
    ###
    if ( $this->isDelimiter($char) ) {
      $this->{token} .= $char;
      return util::Constants::TRUE;
    }

    if ( $char eq util::Constants::QUOTE
      || $char eq util::Constants::SINGLE_QUOTE )
    {
      $on_comment = $char;
    }
    $this->{token} .= $char;
    last;
  }
  ###
  ### process until next white space outside a comment
  ###
  while ( $this->nextChar ) {
    my $char = $this->getChar;
    if ( defined($on_comment) ) {
      $this->{token} .= $char;
      if ( $char eq $on_comment ) { $on_comment = undef; }
    }
    elsif ( $char eq util::Constants::QUOTE
      || $char eq util::Constants::SINGLE_QUOTE )
    {
      ###
      ### There if this is the current comment char
      ### we need to accomodate it and continue one
      ### assuming it will be matched
      ###
      $on_comment = $char;
      $this->{token} .= $char;
    }
    elsif ( $this->isWhiteSpace($char) ) {
      last;
    }
    elsif ( $this->isDelimiter($char) ) {
      ###
      ###  These are delimiters
      ###
      $this->{col_num}--;
      last;
    }
    else {
      $this->{token} .= $char;
    }
  }
  return ( length( $this->{token} ) > 0 );
}

sub getChar {
  my asn::ParseState $this = shift;
  return $this->{char};
}

sub getToken {
  my asn::ParseState $this = shift;
  my $token = $this->{token};
  return $token if ( $token eq util::Constants::EMPTY_STR );
  $token =~ s/$_REMOVE_FORMAT_EFFECTORS_PATTERN//g;
  return $token;
}

################################################################################

1;

__END__

=head1 NAME

ParseState.pm

=head1 SYNOPSIS

This classes manages parsing a set of lines into characters and
tokens.

=head1 METHODS

The following static methods are exported from the class.

=head2 B<new asn::ParseState(lines, line_num, col_num, error_mgr)>

This is the constructor of the class.  The lines are an array
(reference) of strings and line_num and col_num are enumerated from 0
(zero).  line_num specifies the line in the array to start lexical
analysis on.  col_num specifies the column on the line identified by
line_num to start lexical analysis on.

=head2 B<nextChar>

This method gets the next character if there is one.  If there is a
character, then the value is placed in the char attribute and the
method returns TRUE, else the method sets the char attribute to undef
and returns FALSE.

=head2 B<getChar>

This method returns the current character generated by L<"nextChar">.

=head2 B<nextToken>

This method generates the next token if there is one and places it in
the token attribute.  If there is a token, then the value is placed in
the token attribute and the method returns TRUE, else the method sets
the token attribute to the empty string and returns FALSE.

=head2 B<getToken>

This method returns the current token generated by L<"nextToken">.

=cut
