package util::JSon;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use util::Constants;
use util::ErrMsgs;

use fields qw(
  booleans
  error_mgr
  functions
  integers
  special_values
);

################################################################################
#
#				Private Methods
#
################################################################################
###
### Special denotations to use in Perl object to guarantee
### being set to true or false in Javascript.
###
sub JFALSE { return '__jsFalse__'; }
sub JTRUE  { return '__jsTrue__'; }

my $_JSON_TEST = '^(' . JTRUE . '|' . JFALSE . ')$';
###
### For Conversion of JSON to Perl
###
sub false     { return 0; }
sub true      { return 1; }
sub undefined { return undef; }
sub null      { return undef; }
###
### Error Category
###
sub ERR_CAT { return util::ErrMsgs::JSON_CAT; }

################################################################################
#
#				 Public Methods
#
################################################################################

sub new {
  my util::JSon $this = shift;
  my ($error_mgr) = @_;
  $this = fields::new($this) unless ref($this);

  $this->{booleans}       = util::Constants::FALSE;
  $this->{error_mgr}      = $error_mgr;
  $this->{functions}      = util::Constants::FALSE;
  $this->{integers}       = util::Constants::FALSE;
  $this->{special_values} = [];

  return $this;
}

sub setBooleans {
  my util::JSon $this = shift;
  $this->{booleans} = util::Constants::TRUE;
}

sub setFunctions {
  my util::JSon $this = shift;
  $this->{functions} = util::Constants::TRUE;
}

sub setIntegers {
  my util::JSon $this = shift;
  $this->{integers} = util::Constants::TRUE;
}

sub setSpecialValues {
  my util::JSon $this = shift;
  my ($search_str) = @_;
  return if ( util::Constants::EMPTY_LINE($search_str) );
  push( @{ $this->{special_values} }, $search_str );
}

sub makeJsonStr($$) {
  my util::JSon $this = shift;
  my ($perl_obj)      = @_;
  my $str             = util::Constants::EMPTY_STR;
  my $ref             = ref($perl_obj);
  if ( $ref eq 'HASH' ) {
    $str = '{';
    my $key_index = util::Constants::FALSE;
    foreach my $key ( sort keys %{$perl_obj} ) {
      if ($key_index) { $str .= ','; }
      $key_index = util::Constants::TRUE;
      $str .= $key . ':' . $this->makeJsonStr( $perl_obj->{$key} );
    }
    $str .= '}';
  }
  elsif ( $ref eq 'ARRAY' ) {
    $str = '[';
    my $comp_index = util::Constants::FALSE;
    foreach my $comp ( @{$perl_obj} ) {
      if ($comp_index) { $str .= ','; }
      $comp_index = util::Constants::TRUE;
      $str .= $this->makeJsonStr($comp);
    }
    $str .= ']';
  }
  elsif ( defined($perl_obj) ) {
    if ( $perl_obj =~ /$_JSON_TEST/ ) {
      ###
      ### true and false strings are terms in JSon
      ###
      if    ( $perl_obj eq JFALSE ) { $str = 'false'; }
      elsif ( $perl_obj eq JTRUE )  { $str = 'true'; }
    }
    elsif (
      (
        $this->{booleans} && ( $perl_obj eq 'true'
          || $perl_obj eq 'false' )
      )
      || ( $this->{integers}
        && $perl_obj =~ /^(\+|-)?\d+$/ )
      || ( $this->{functions}
        && $perl_obj =~ /^function\(.*\)\s*\{.+}$/ )
      )
    {
      $str = $perl_obj;
    }
    elsif ( @{ $this->{special_values} } > 0 ) {
      foreach my $search_str ( @{ $this->{special_values} } ) {
        if ( $perl_obj =~ /$search_str/ ) {
          $str = $perl_obj;
          last;
        }
      }
    }
    else {
      ###
      ### Actions on all strings
      ###
      ### 1.  Protect \ and " with escapes '\\' and '\"', respectively
      ### 2.  Replace line-breaks with '\n'
      ### 3.  Finally double-quote string
      ###
      $perl_obj =~ s/\\/\\\\/g;
      $perl_obj =~ s/"/\\"/g;
      $perl_obj =~ s/\n/\\n/g;
      $str = '"' . $perl_obj . '"';
    }
  }
  else {
    ###
    ### Undefined string is set as JSon null
    ###
    $str = 'null';
  }
  return $str;
}

sub makePerlObj ($$) {
  my util::JSon $this = shift;
  my ($json_str) = @_;
  $json_str =~ s/:/=>/g;
  my $obj    = eval $json_str;
  my $status = $@;
  my $error  = defined($status) && $status;
  $this->{error_mgr}->exitProgram( ERR_CAT, 1, [ $status, $json_str ], $error );
  return $obj;
}

################################################################################

1;

__END__

=head1 NAME

JSon.pm

=head1 SYNOPSIS

   use util::JSon;

=head1 DESCRIPTION

This class define mechanism for converting Perl data-structures into
JSon data-structures and vice-versa.

=head1 CONSTANTS

Special denotations to use in Perl object to guarantee being set to
true or false in Javascript.

   util::JSon::JFALSE -- '__jsFalse__'
   util::JSon::JTRUE  -- '__jsTrue__'

For Conversion of JSON to Perl

   util::JSon::false     -- 0
   util::JSon::true      -- 1
   util::JSon::undefined -- undef
   util::JSon::null      -- undef

=head1 METHODS

The following methods are exported by this class.

=head2 B<util::JSon::new(error_mgr)>

This method is the constructor for the class.  It takes a error
messaging object B<msg> that is a instance of the class
L<util::ErrMgr>.  Initially, JSon booleans, functions, and integers
are set ot FALSE (0).  Also, special_values are empty.

=head2 B<$json = makeJsonStr(perl_obj)>

This method takes a Perl object B<perl_obj> and converts it into a
JSon string.  It uses the attributes booleans, functions, integers,
and special_values (as described below) to parse the Perl object into
the correct JSon string.  Perl Hashes are converted into Javascript
Hashes, Perl Arrays are converted into Javascript arrays.  Perl scalar
objects (strings and numbers) are converted into Javascript entities
guided by booleans, functions, integers, and special_values.  Also,
special strings B<'__jsFalse__'> and B<'__jsTrue__'> are converted
into Javascript false and true values.  Finally, string that contain
'\', '"', and '\n' will be provided escape sequences respectively,
'\\\\', '\\"', and '\\n'.

=head2 B<$perl_obj = makePerlObj($json)>

This method takes a JSon string B<json> and eval's it into a perl
object as follows.  First it replaces all ':' with '=>' and then
eval's the string.  Note that is class converts a bear Javascript
B<true> to B<1>, B<false> to B<0>, B<null> to B<undef>, and
B<undefined> to B<undef>.

=head1 SETTER METHODS

The following setter methods are exported by this class

=head2 B<setBooleans>

This method sets booleans to TRUE (1).  If booleans is TRUE (1), then
in parsing Perl to JSon the strings B<'true'> and B<'false'> when
encountered will be left bear, that is, they will be Javascript true
and false values.  Otherwise, these strings will be quoted.  Initially,
booleans is set to FALSE (0).

=head2 B<setFunctions>

This method sets functions to TRUE (0).  If functions is true, then in
parsing Perl to JSon the string with the regular expression of
B<'^function\(.*\)\s*\{.+}$'> will be left bear, that is it will
represent a Javascript function.  Otherwise, this string will be
quoted.  Initially, functions is set to FALSE (0).

=head2 B<setIntegers>

This method sets integers to TRUE (0).  If integers is true, then in
parsing Perl to JSon the string with the regular expression of
B<'^(\+|-)?\d+$'> will be left bear, that is it will represent a
Javascript integer.  Otherwise, this string will be quoted.
Initially, integers is set to FALSE (0).

=head2 B<setSpecialValues(search_string)>

This method adds a regular expression string B<search_string> to
special_values to test in Parsing Perl to JSon.  If a string compares
TRUE (1) to the regular expression string, then the string will be
left bear since it represents something in Javascript.  Initially, no
search strings are set

=cut
