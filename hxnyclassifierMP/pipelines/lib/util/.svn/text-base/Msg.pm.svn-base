package util::Msg;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Carp 'cluck', 'confess';
use FileHandle;
use POSIX;
use Pod::Usage;

use util::Constants;
use util::Debugging;
use util::PathSpecifics;

use fields qw(
  current
  debug
  dual
  file
  filename
  hard_die
  header
  pad
  silent
);

################################################################################
#
#				Local Constants
#
################################################################################
###
### Standard Message Headers
###
sub _DIE_MSG_HEADER  { return 'ERROR(' . util::Constants::DATE . '):  '; }
sub _TIME_MSG_HEADER { return 'TIME(' . util::Constants::DATE . '):  '; }

sub _DEBUG_MSG_HEADER   { return 'DEBUG:  '; }
sub _ERROR_MSG_HEADER   { return 'ERROR:  '; }
sub _NO_MSG_HEADER      { return util::Constants::EMPTY_STR; }
sub _WARNING_MSG_HEADER { return 'WARNING:  '; }
sub _NOTE_MSG_HEADER    { return 'NOTE:  '; }
###
### Header Message Constants
###
sub _SPACES_        { return &util::Constants::SPACE x 2; }
sub _SPACES_LENGTH_ { return 2 * length(_SPACES_); }

sub _BANNER_        { return &util::Constants::SHARP x 3; }
sub _BANNER_LENGTH_ { return 2 * length(_BANNER_); }

sub _PADDING_ { return _SPACES_ . "\n"; }

################################################################################
#
#				Private Methods
#
################################################################################
###
### Standard Message Look and Feel
###
sub _splitMsg($$) {
  my util::Msg $this = shift;
  my ($msg) = @_;
  return split( /\n/, $msg, -1 );
}

sub _prepareMessage($$$) {
  my util::Msg $this = shift;
  my ( $msg, $header ) = @_;
  my @comps = $this->_splitMsg($msg);
  if ( $this->{pad} ) { unshift( @comps, '' ); push( @comps, '' ); }
  if ( $header ne util::Constants::EMPTY_STR ) {
    foreach my $index ( 0 .. $#comps ) {
      $comps[$index] = $header . $comps[$index];
    }
  }
  return $msg = join( "\n", @comps );
}
###
### Standard Time Message Header
###
sub _setTimeHeader($) {
  my util::Msg $this = shift;
  $this->{current} = $this->{header};
  $this->setHeader(_TIME_MSG_HEADER);
}
###
### Reset header
###
sub _resetHeader($) {
  my util::Msg $this = shift;
  $this->{header} = $this->{current};
}
###
### Fundamental print operator
###
sub _printMessage($$$;$$) {
  my util::Msg $this = shift;
  return if $this->{silent};
  my ( $msg, $header, $stdout, $as_is ) = @_;
  $msg = $this->_prepareMessage( $msg, $header );
  if ( !defined($as_is) || !$as_is ) { $msg .= util::Constants::NEWLINE; }
  if ( $this->isFile && !defined($stdout) ) { $this->{file}->print($msg); }
  if ( !$this->isFile || defined($stdout) || $this->isDual ) {
    print STDOUT $msg;
  }
}

################################################################################
#
#			       Class Constructor
#
################################################################################

sub new($) {
  my util::Msg $this = shift;
  $this = fields::new($this) unless ref($this);
  $this->{current}  = _NO_MSG_HEADER;
  $this->{debug}    = util::Debugging::on;
  $this->{dual}     = util::Constants::FALSE;
  $this->{file}     = new FileHandle;
  $this->{filename} = undef;
  $this->{hard_die} = util::Constants::TRUE;
  $this->{header}   = _NO_MSG_HEADER;
  $this->{pad}      = util::Constants::FALSE;
  $this->{silent}   = util::Constants::FALSE;

  return $this;
}

################################################################################
#
#				    Setters
#
################################################################################

sub setDebug {
  my util::Msg $this = shift;
  $this->{debug} = util::Constants::TRUE;
}

sub unsetDebug {
  my util::Msg $this = shift;
  $this->{debug} = util::Constants::FALSE;
}

sub setDual {
  my util::Msg $this = shift;
  $this->{dual} = util::Constants::TRUE;
}

sub unsetDual {
  my util::Msg $this = shift;
  $this->{dual} = util::Constants::FALSE;
}

sub openFile ($$;$) {
  my util::Msg $this = shift;
  my ( $file, $unique ) = @_;
  return $this->{filename} if ( $this->isFile );
  $this->{filename} = $file;
  if ( defined($unique) ) {
    my $hostname = `hostname -s`;
    chomp($hostname);
    sleep(1);
    $this->{filename} =
      join( util::Constants::DOT, $this->{filename}, $hostname, $$, time() );
  }
  $this->{filename} = getPath( $this->{filename} );
  $this->dieOnError( "Cannot open " . $this->{filename},
    !$this->{file}->open( $this->{filename}, '>>' ) );
  $this->{file}->autoflush(util::Constants::TRUE);
  return $this->{filename};
}

sub closeFile {
  my util::Msg $this = shift;
  return if ( !$this->isFile );
  $this->{file}->close;
  $this->{filename} = undef;
}

sub setHardDie {
  my util::Msg $this = shift;
  $this->{hard_die} = util::Constants::TRUE;
}

sub unsetHardDie {
  my util::Msg $this = shift;
  $this->{hard_die} = util::Constants::FALSE;
}

sub setHeader($$) {
  my util::Msg $this = shift;
  my ($header) = @_;
  if ( !defined($header) ) { $header = _NO_MSG_HEADER; }
  $this->{header} = $header;
}

sub unsetHeader {
  my util::Msg $this = shift;
  my ($header) = @_;
  $this->{header} = _NO_MSG_HEADER;
}

sub setPad {
  my util::Msg $this = shift;
  $this->{pad} = util::Constants::TRUE;
}

sub unsetPad {
  my util::Msg $this = shift;
  $this->{pad} = util::Constants::FALSE;
}

sub setSilent {
  my util::Msg $this = shift;
  $this->{silent} = util::Constants::TRUE;
}

sub unsetSilent {
  my util::Msg $this = shift;
  $this->{silent} = util::Constants::FALSE;
}

################################################################################
#
#				    Getters
#
################################################################################

sub isDebugging {
  my util::Msg $this = shift;
  return $this->{debug};
}

sub isDual {
  my util::Msg $this = shift;
  return $this->{dual};
}

sub isFile {
  my util::Msg $this = shift;
  return defined( $this->{file}->fileno );
}

sub isHardDie {
  my util::Msg $this = shift;
  return $this->{hard_die};
}

sub getHeader {
  my util::Msg $this = shift;
  return $this->{header};
}

sub isPad {
  my util::Msg $this = shift;
  return $this->{pad};
}

################################################################################
#
#				Printing Methods
#
################################################################################

sub print($$) {
  my util::Msg $this = shift;
  my ($msg) = @_;
  $this->_printMessage( $msg, util::Constants::EMPTY_STR, undef,
    util::Constants::TRUE );
}

sub printMsg($$) {
  my util::Msg $this = shift;
  my ($msg) = @_;
  $this->_printMessage( $msg, $this->{header} );
}

sub printNote($$) {
  my util::Msg $this = shift;
  my ($msg) = @_;
  $this->_printMessage( $msg, _NOTE_MSG_HEADER );
}

sub printStdOut($$) {
  my util::Msg $this = shift;
  my ($msg) = @_;
  $this->_printMessage( $msg, $this->{header}, util::Constants::TRUE );
}

sub printHeader($$;$) {
  my util::Msg $this = shift;
  my ( $msg, $indent ) = @_;
  my $indent_str =
    ( defined($indent) && int($indent) > 0 )
    ? &util::Constants::SPACE x $indent
    : util::Constants::EMPTY_STR;
  my @comps          = $this->_splitMsg($msg);
  my $max_msg_length = 0;
  foreach my $comp (@comps) {
    if ( $max_msg_length < length($comp) ) {
      $max_msg_length = length($comp);
    }
  }
  my $header_length = &_SPACES_LENGTH_ + &_BANNER_LENGTH_ + $max_msg_length;
  my $the_banner =
      $indent_str
    . &util::Constants::SHARP x $header_length
    . &util::Constants::NEWLINE;
  my $middle_banner =
      $indent_str 
    . _BANNER_
    . &util::Constants::SPACE x ( $header_length - &_BANNER_LENGTH_ )
    . _BANNER_
    . &util::Constants::NEWLINE;
  my $header = $indent_str . _PADDING_ . $the_banner . $middle_banner;
  foreach my $comp (@comps) {
    $header .=
        $indent_str 
      . _BANNER_ 
      . _SPACES_ 
      . $comp
      . &util::Constants::SPACE x ( $max_msg_length - length($comp) )
      . _SPACES_
      . _BANNER_
      . &util::Constants::NEWLINE;
  }
  $header .= $middle_banner . $the_banner . _PADDING_;
  $this->printMsg($header);
}

sub printDateHeader($$;$) {
  my util::Msg $this = shift;
  my ( $msg, $indent ) = @_;
  $this->printHeader( "$msg\n" . "  date = " . util::Constants::DATE, $indent );
}

sub printTime($$) {
  my util::Msg $this = shift;
  my ($msg) = @_;
  $this->_setTimeHeader;
  $this->printMsg($msg);
  $this->_resetHeader;
}

sub printWarning($$) {
  my util::Msg $this = shift;
  my ( $msg, $warning ) = @_;
  return if ( !defined($warning) || !$warning );
  $this->_printMessage( $msg, _WARNING_MSG_HEADER );
}

sub printError($$$) {
  my util::Msg $this = shift;
  my ( $msg, $error ) = @_;
  return if ( !defined($error) || !$error );
  my $pad = $this->isPad;
  if ( !$pad ) { $this->setPad; }
  $this->_printMessage( $msg, _ERROR_MSG_HEADER );
  if ( !$pad ) { $this->unsetPad; }
}

sub printMsgOrError($$$) {
  my util::Msg $this = shift;
  my ( $msg, $error ) = @_;
  if ( defined($error) && $error ) { $this->printError( $msg, $error ); }
  else                             { $this->printMsg($msg); }
}

sub printMsgOrWarning($$$) {
  my util::Msg $this = shift;
  my ( $msg, $warning ) = @_;
  if ( defined($warning) && $warning ) {
    $this->printWarning( $msg, $warning );
  }
  else { $this->printMsg($msg); }
}

sub printDebug($$) {
  my util::Msg $this = shift;
  my ($msg) = @_;
  return if ( !$this->{debug} );
  $this->_printMessage( $msg, _DEBUG_MSG_HEADER );
}

sub dieOnError($$$) {
  my util::Msg $this = shift;
  my ( $msg, $error ) = @_;
  return if ( !defined($error) || !$error );
  $this->setPad;
  $this->setDual;
  $this->_printMessage( $msg, _DIE_MSG_HEADER );
  $this->closeFile;
  if ( $this->{hard_die} ) { cluck; POSIX::_exit(2); }
  else                     { confess; }
}

################################################################################

1;

__END__

=head1 NAME

Msg.pm

=head1 SYNOPSIS

use util::Msg;

=head1 DESCRIPTION

This class defines the standard message for a program.  It provides several
services, including: stdout and/or file messaging, debugging, warnings, and
errors.  It provides headers and padding for messages.  Finally, it provides a
mechanism for graceful termination.

=head1 METHODS

The following methods are exported by this class.

=head2 B<new util::Msg>

This is the constructor for the class.  It sets the default behavior for
messaging as follows:

   Capability     Setting Setters                 Getter
   -------------  ------- ----------------------- ---------
   debugging      (*)     setDebug   unsetDebug   isDebugging
   file messaging off     openFile   closeFile    isFile
   dual messaging off     setDual    unsetDual    isDual
   hard die       on      setHardDie unsetHardDie isHardDie
   header         none    setHeader  unsetHeader  getHeader
   padding        none    setPad     unsetPad     isPad

B<Debbugging (*)> for the object is initially set to the global
debugging switch (which can be set to on or off), L<util::Debugging>,
and after that can be set or unset independently for each message
object.  This switch only has an effect on the L<"printDebug(msg)">
method.

B<File messaging> allows messages to be written to a specified file.  If file
messaging is on, then all messages will be written to the file, otherwise all
messages are written to stdout.

B<Dual messaging> allows messages to be written to both a specified file (if
file message is on) and stdout.

B<Hard die> specifies how the method L<"dieOnError(msg, error)"> terminates
processing.  If hard die is on, then processing is terminated by POSIX exit(2),
otherwise Perl confess is used.  The latter mechanism allows termination to be
trapped in eval statements and processed in exception handlers.

B<Header> specifies the header for regular messages (see L<"printMsg(msg)">,
L<"printStdOut(msg)">, L<"printHeader(msg[, indent])">),
L<"printDateHeader(msg[, indent])">),
and L<"printMsgOrError(msg, error)">, and L<"printMsgOrWarning(msg, warning)">.

B<Padding> determines whether there is a blank line before and after a message.

=head2 B<print(msg)>

This method prints a message exactly as-is with no message header.  It
acts exactly like print so that they will be no newline at the end of
the message if it is not provided.

=head2 B<printMsg(msg)>

This method prints a message using the current message header and does
add a newline at the end of the line.

=head2 B<printNote(msg)>

This method prints a message using the note header B<'NOTE:  '> and does
add a newline at the end of the line.

=head2 B<printStdOut(msg)>

This method prints a message only to stdout using the current message header.

=head2 B<printHeader(msg[, indent])>

This method prints the message in a header box with an optional
indentation (0 by default), for example, with the following msg, the
header below is printed

   $msg =
    "Opened Taxonomy Index\n" .
    "  dataBank = refseq\n" .
    "  date     = " . util::Constants::DATE;

   printHeader($msg);

   ###################################################
   ###                                             ###
   ###  Opened Taxonomy Index                      ###
   ###    dataBank = refseq                        ###
   ###    date     = Wed May  4 17:37:26 EDT 2005  ###
   ###                                             ###
   ###################################################

=head2 B<printDateHeader(msg[, indent])>

This method prints the message with a date in a header box with an
optional indentation (0 by default), for example, with the following
msg, the header below is printed

   $msg = "Opened Taxonomy Index";

   printDateHeader($msg);

   ###############################################
   ###                                         ###
   ###  Opened Taxonomy Index                  ###
   ###    date = Wed May  4 17:37:26 EDT 2005  ###
   ###                                         ###
   ###############################################

=head2 B<printTime(msg)>

This method prints a message with a B<timed> message header that has the format
B<'TIME(Thu May  5 15:33:00 EDT 2005):  '>.

=head2 B<printWarning(msg, warning)>

This method prints a warning message with the header B<'WARNING: '> if warning
is TRUE.

=head2 B<printError(msg, error)>

This method prints an error message with the header B<'ERROR: '> if error is
TRUE.

=head2 B<printMsgOrError(msg, error)>

If error is TRUE, then an error message is printed, otherwise a
regular message is printed.

=head2 B<printMsgOrWarning(msg, warning)>

If warning is TRUE, then warning message is printed, otherwise a
regular message is printed.

=head2 B<printDebug(msg)>

This method prints a debugging message with the header B<'DEBUG: '> if debugging
is set on.

=head2 B<dieOnError(msg, error)>

If error is FALSE, the method is a NO-OP.  If error is TRUE, then this
method prints and error message with the header
B<'ERROR(Thu May  5 15:33:00 EDT 2005): '>
closes file messagaing, and then terminates the program with a stack
trace as follows.  If hard die is on, then the program is terminated
by POSIX exit(2), otherwise it is terminated by Perl confess.

=head1 SETTER METHODS

The following setter methods modify the behavior of message as described in
L<"new util::Msg">.

=head2 B<setDebug>

This method sets debugging on.

=head2 B<unsetDebug>

This method sets debugging off.

=head2 B<setDual>

This method set dual messaging on.

=head2 B<unsetDual>

This method sets dual messaging off.

=head2 B<$filename = openFile(filename[, unique])>

This method opens file messaging (if file messaging is not currently turned on)
and returns the name of the file that is opened.  If the unique parameter is not
provided, then the file is opened in append mode.  If the unique parameter
is provided, then a unique file is opened with the following filename format:

   <filename>.<hostname>.<processID>.<time>

=head2 B<closeFile>

This method closes the file if file messaging is on.

=head2 B<setHardDie>

This method sets hard die on.

=head2 B<unsetHardDie>

This method sets hard die off.

=head2 B<setHeader(header)>

This method sets the message header for each line to header.  If
header is not defined, then the empty string is used.

=head2 B<unsetHeader>

This method sets the message header for each line to the empty string.

=head2 B<setPad>

This method sets message padding on.

=head2 B<unsetPad>

This method sets message padding off.

=head2 B<setSilent>

This method disables all output from Msg whether it be to STDOUT or to a file

=head2 B<unsetSilent>

This method enables all output from Msg including output to STDOUT or to a file

=head1 GETTER METHODS

The following getter methods return the current settings as defined in the
L<"new util::Msg">.

=head2 B<isDebugging>

The method returns the current debugg setting.

=head2 B<isDual>

This method returns the current dual messaging setting.

=head2 B<isFile>

Thie method returns the current file messaging setting

=head2 B<isHardDie>

Thie method returns the current setting for hard die

=head2 B<getHeader>

The method returns the current message header.

=head2 B<isPad>

This method returns current setting for message padding.

=cut
