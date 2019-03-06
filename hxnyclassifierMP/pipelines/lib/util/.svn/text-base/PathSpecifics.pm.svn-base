package util::PathSpecifics;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'cwd';
use File::Basename;
use Pod::Usage;

use util::Constants;

################################################################################
#
#				Initializations
#
################################################################################

BEGIN {
  use Exporter();
  use vars qw(@ISA @EXPORT);
  @ISA = qw(Exporter);
  @EXPORT = ( '&strip_whitespace', '&setPath', '&getPath' );
}

sub _GET_CURRENT_HOST {
  my $hostname = `hostname`;
  chomp($hostname);
  return ( $hostname eq 'RKVSMITHTJL01' )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
}
my $_WINDOWS_HOST = _GET_CURRENT_HOST;

################################################################################
#
#			     Public Static Methods
#
################################################################################

sub strip_whitespace {
  my ($str) = @_;
  my $whitespace = util::Constants::WHITESPACE;
  $str =~ s/^$whitespace//;
  $str =~ s/$whitespace$//;
  return $str;
}

sub setPath {
  my ($filename) = @_;
  return ( undef, undef )
    if ( !defined($filename) || $filename eq util::Constants::EMPTY_STR );
  ###
  ### Remove whitespace at either end
  ###
  $filename = &strip_whitespace($filename);
  ###
  ### Remove spurious slashes
  ###
  if ($_WINDOWS_HOST) {
    ###
    ### 1.  Dots and slashes /./
    ### 2.  Multiple slashes to one slash //+
    ### 3.  Trailing slash and optional dot (/.?$)
    ###
    while ( $filename =~ /\\\.\\/ ) { $filename =~ s/\\\.\\//g; }
    while ( $filename =~ /\\\\+/ )  { $filename =~ s/\\\\+//g; }
    while ( $filename =~ /\\\.?$/ ) { $filename =~ s/\\\.?$//; }
  }
  else {
    ###
    ### 1.  Multiple slashes to one slash (\/(\/)+)
    ### 2.  Trailing slash and optional dot (\/\.?$)
    ### 3.  Dots and slashes /./
    ###
    while ( $filename =~ /\/\.\// ) { $filename =~ s/\/\.\//\//g; }
    while ( $filename =~ /\/\/+/ )  { $filename =~ s/\/\/+/\//g; }
    while ( $filename =~ /\/\.?$/ ) { $filename =~ s/\/\.?$//; }
  }
  ###
  ### Decompose filename to file_name and file_path
  ###
  my ( $file_name, $file_path, $file_suffix ) = fileparse($filename);
  ###
  ### Then adjust file_path
  ###
  my $make_absolute = undef;
  if ($_WINDOWS_HOST) {
    ###
    ### Removing spurious dot-slashes (./) (This assumes
    ### that filenames do not end in dot (.)
    ###
    $file_path =~ s/\.\\//g if ( $file_path !~ /\.\./ );
    $make_absolute =
      (    $file_path eq util::Constants::EMPTY_STR
        || $file_path !~ /^c:(\\|\/)/i )
      ? util::Constants::TRUE
      : util::Constants::FALSE;
  }
  else {
    $file_path =~ s/\.\///g if ( $file_path !~ /\.\./ );
    $make_absolute =
      ( $file_path eq util::Constants::EMPTY_STR || $file_path =~ /^[^\/]/ )
      ? util::Constants::TRUE
      : util::Constants::FALSE;
  }
  ###
  ### Make absolute file_path
  ###
  if ($make_absolute) {
    $file_path = join( util::Constants::SLASH, cwd(), $file_path );
  }
  ###
  ### Remove some weirdness that the automounter setup is creating.
  ### V51 also adds some weirdness that needs removing.
  ###
  $file_path =~ s/^\/cluster\/members\/member\d*\//\//;
  $file_path =~ s/^\/auto\/mount\//\//;

  return ( $file_name, $file_path );
}

sub getPath {
  my ($input_path) = @_;
  return undef
    if ( !defined($input_path) || $input_path eq util::Constants::EMPTY_STR );
  my ( $suffix_name, $prefix_path ) = &setPath($input_path);
  return $prefix_path . $suffix_name;
}

################################################################################

1;

__END__

=head1 NAME

PathSpecifics.pm

=head1 SYNOPSIS

   use util::PathSpecifics;

   my $foo = '   ffff ';
   $foo = &strip_whitespace($foo);
   my $path = getPath(shift);
   my ($basename, $pathname) = setPath($filename);

=head1 DESCRIPTION

This static class exports the function for resolving path names.

=head1 STATIC METHODS

The following static methods are exported from this static class.

=head2 B<strip_whitespace($str)>

This static method returns the string str with all whitespace removed
from its head and tail.  White is includes space, tab, and format
effectors.

=head2 B<setPath(filename)>

This static method takes a filename (directory or file) and resolves
it to its full (standard) well-formed pathname with extraneous network
file systems prefixes, leading/trailing whitespace, dot's ('.'), and
slashes ('/').  The filename can be either relative or full.  This
method returns two values: file_name and file_path.  The file_name is
the base name of the filename and the file_path is the pathname of the
directory (including final slash '/') containing the filename.  If
filename is undefined (undef) or empty, then B<(undef, undef)> pair is
returned.

=head2 B<getPath($input_path)>

This static method takes the input_path (directory or file) and
returns the resolved well-formated full path name of the input_path
with extraneous network file systems prefixes, leading/trailing
whitespace, dot's ('.') and slashes ('/').  This method uses
L<"setPath(filename)">.  If input_path is undefined (undef) or empty,
then undef is returned.

=cut
