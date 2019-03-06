package util::Constants;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

################################################################################
#
#				Constant Methods
#
################################################################################
###
### Boolean Values
###
sub FALSE { return 0; }
sub TRUE  { return 1; }
###
### Standard Constants
###
sub AMPERSAND           { return '&'; }
sub ASTERISK            { return '*'; }
sub BACKSLASH           { return '\\'; }
sub CARRIAGE_RETURN     { return "\r"; }
sub CLOSE_BRACKET       { return ']'; }
sub CLOSE_PAREN         { return ')'; }
sub COLON               { return ':'; }
sub COMMA               { return ','; }
sub CTRLM               { return ""; }
sub DOT                 { return '.'; }
sub DOUBLE_COLON        { return '::'; }
sub ELLIPSES            { return '..'; }
sub EMPTY_STR           { return ''; }
sub EQUALS              { return '='; }
sub FORM_FEED           { return "\f"; }
sub GREATER_THAN        { return '>'; }
sub HYPHEN              { return '-'; }
sub NEWLINE             { return "\n"; }
sub NULL                { return 'NULL'; }
sub ONE_HUNDRED_PERCENT { return '100'; }
sub OPEN_BRACKET        { return '['; }
sub OPEN_PAREN          { return '('; }
sub PIPE                { return '|'; }
sub PLUS                { return '+'; }
sub QUOTE               { return '"'; }
sub SEMI_COLON          { return ';'; }
sub SHARP               { return '#'; }
sub SINGLE_QUOTE        { return "'"; }
sub SLASH               { return '/'; }
sub SPACE               { return ' '; }
sub TAB                 { return "\t"; }
sub TILDE               { return '~'; }
sub UNDERSCORE          { return '_'; }
###
### Separators
###
sub COMMA_SEPARATOR      { return ', '; }
sub NEWLINE_SEPARATOR    { return "\n" . ' ' x 12; }
sub SEMI_COLON_SEPARATOR { return '; '; }
###
### Standard Regular Expressions
###
sub ALL_WHITESPACE { return '^\s+$'; }    ### Fix for Xemacs ';} ###
sub ANY_STR        { return '.*'; }
sub COMMENT_LINE   { return '^#'; }
sub END_STR        { return '$'; }        ### Fix for Xemacs ';} ###
sub TAB_PATTERN    { return '\t'; }
sub WHITESPACE     { return '\s+'; }
###
### A Date
###
sub DATE { my $date = `date`; chomp($date); return $date; }
###
### Empty Line
###
sub EMPTY_LINE {
  my ($line) = @_;
  return ( !defined($line) || $line eq EMPTY_STR ) ? TRUE : FALSE;
}

################################################################################

1;

__END__

=head1 NAME

Constants.pm

=head1 SYNOPSIS

   use util::Constants;

=head1 DESCRIPTION

This module export the static constant methods used by the loaders

=head1 CONSTANT METHODS

The standard Boolean constants are:

   util::Constants::FALSE -- 0
   util::Constants::TRUE  -- 1

Other standard constants:

   util::Constants::AMPERSAND           -- '&'
   util::Constants::ASTERISK            -- '*'
   util::Constants::BACKSLASH           -- '\\'
   util::Constants::CARRIAGE_RETURN     -- "\r"
   util::Constants::CLOSE_BRACKET       -- ']'
   util::Constants::CLOSE_PAREN         -- ')'
   util::Constants::COLON               -- ':'
   util::Constants::COMMA               -- ','
   util::Constants::CTRLM               -- "^M"
   util::Constants::DOT                 -- '.'
   util::Constants::DOUBLE_COLON        -- '::'
   util::Constants::ELLIPSES            -- '..'
   util::Constants::EMPTY_STR           -- ''
   util::Constants::EQUALS              -- '='
   util::Constants::FORM_FEED           -- "\f"
   util::Constants::HYPHEN              -- '-'
   util::Constants::NEWLINE             -- "\n"
   util::Constants::NULL                -- 'NULL'
   util::Constants::ONE_HUNDRED_PERCENT -- '100'
   util::Constants::OPEN_BRACKET        -- '['
   util::Constants::OPEN_PAREN          -- '('
   util::Constants::PLUS                -- '+'
   util::Constants::QUOTE               -- '"'
   util::Constants::SEMI_COLON          -- '
   util::Constants::SHARP               -- '#'
   util::Constants::SINGLE_QUOTE        -- "'"
   util::Constants::SLASH               -- '/'
   util::Constants::SPACE               -- ' '
   util::Constants::TAB                 -- "\t"
   util::Constants::UNDERSCORE          -- '_'

Standard separators:

   util::Constants::COMMA_SEPARATOR      -- ', '
   util::Constants::NEWLINE_SEPARATOR    -- "\n" . ' ' x 12
   util::Constants::SEMI_COLON_SEPARATOR -- '; '

Standard regular expressions:

   util::Constants::ALL_WHITESPACE      -- '^\s+$'
   util::Constants::ANY_STR             -- '.*'
   util::Constants::COMMENT_LINE        -- '^#'
   util::Constants::END_STR             -- '$'
   util::Constants::TAB_PATTERN         -- '\t'
   util::Constants::WHITESPACE          -- '\s+'

A Standard 'Now' Date:

   util::Constants::DATE                -- Fri Nov 11 15:57:03 EST 2005

=head1 STATIC METHODS

The following static methods are exported by this static class.

=head2 B<EMPTY_LINE(line)>

This method return TRUE (1) if the lines is either undefined or empty,
otherwise it returns FALSE (0).

=cut
