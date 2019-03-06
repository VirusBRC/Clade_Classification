package util::Cmd;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use FileHandle;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use fields qw(
  cmd_comps
  mode
  msg
  print_msg
  sleep
  sys_name
  tar
  tar_switch
);

################################################################################
#
#				   Constants
#
################################################################################
###
### Command Components
###
sub _CMD_CMP    { return 'cmd'; }
sub _MSG_CMP    { return 'msg'; }
sub _STATUS_CMP { return 'status'; }
sub _UNDO_CMP   { return 'undo'; }

################################################################################
#
#			       Private Methods
#
################################################################################

sub _systemSpecifics($) {
  my util::Cmd $this = shift;
  $this->{sys_name} = `uname`;
  $this->{sys_name} =~ s/\n//g;
  $this->{tar}        = undef;
  $this->{tar_switch} = undef;
  if ( $this->{sys_name} eq 'Linux' ) {
    $this->{tar}        = '/bin/tar';
    $this->{tar_switch} = 'T';
  }
  $this->{msg}->printWarning(
    "Unknown System (will not be able to use tar command)\n"
      . "  sys_name = "
      . $this->{sys_name},
    !defined( $this->{tar} )
  );
}

sub _cmdComponents($@) {
  my util::Cmd $this = shift;
  my (@cmd_comps)    = @_;
  my @cmds           = ();
  return @cmds if ( @cmd_comps == 0 || @cmd_comps % 4 != 0 );
  while ( @cmd_comps != 0 ) {
    my $cmd_struct = {};
    foreach my $comp ( @{ $this->{cmd_comps} } ) {
      $cmd_struct->{$comp} = shift(@cmd_comps);
    }
    if ( !defined( $cmd_struct->{&_STATUS_CMP} )
      || !$cmd_struct->{&_STATUS_CMP} )
    {
      $cmd_struct->{&_STATUS_CMP} = util::Constants::TRUE;
    }
    if ( defined( $cmd_struct->{&_UNDO_CMP} )
      && $cmd_struct->{&_UNDO_CMP} eq util::Constants::EMPTY_STR )
    {
      $cmd_struct->{&_UNDO_CMP} = undef;
    }
    $this->{msg}->printDebug(
      '_cmdComponents:  (' . join( ':::::', %{$cmd_struct} ) . ')' );
    push( @cmds, $cmd_struct );
  }
  return @cmds;
}

sub _cmdMsg($$$;$) {
  my util::Cmd $this = shift;
  my ( $msg, $msgs, $error ) = @_;
  ###
  ### Determine Error
  ###
  $error =
    ( defined($error) && $error )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  ###
  ### Determine formating length
  ###
  my $msg_tag_length = 0;
  foreach my $msg_tag ( keys %{$msgs} ) {
    next if ( $msg_tag_length >= length($msg_tag) );
    $msg_tag_length = length($msg_tag);
  }
  $msg_tag_length += 1;
  ###
  ### Create Message
  ###
  my $message = undef;
  if   ($error) { $message = "Unable to Perform ($msg)\n"; }
  else          { $message = "$msg:\n"; }
  foreach my $msg_tag ( sort keys %{$msgs} ) {
    $message .=
        "  $msg_tag"
      . &util::Constants::SPACE x ( $msg_tag_length - length($msg_tag) ) . '= '
      . $msgs->{$msg_tag} . "\n";
  }
  ###
  ### Print Message
  ###
  if ($error) {
    $this->{msg}->printError( $message, $error );
  }
  elsif ( $this->{print_msg} ) { $this->{msg}->printMsg($message); }
}

sub _execCmd($$$) {
  my util::Cmd $this = shift;
  my ( $error_msgs, $cmd_struct ) = @_;
  $this->_cmdMsg( $cmd_struct->{&_MSG_CMP}, $error_msgs );
  system( $cmd_struct->{&_CMD_CMP} );
  my $error_status = $?;
  return util::Constants::FALSE if ( !$error_status );
  $error_msgs->{errMsg} = $error_status;
  $this->_cmdMsg( $cmd_struct->{&_MSG_CMP}, $error_msgs, $error_status );

  if ( defined( $cmd_struct->{&_UNDO_CMP} ) ) {
    system( $cmd_struct->{&_UNDO_CMP} );
  }
  return $cmd_struct->{&_STATUS_CMP};
}

################################################################################
#
#				  Constructor
#
################################################################################

sub new($$) {
  my util::Cmd $this = shift;
  my ($msg) = @_;
  $this = fields::new($this) unless ref($this);
  $this->{cmd_comps} = [ _CMD_CMP, _MSG_CMP, _UNDO_CMP, _STATUS_CMP ];
  $this->{mode}      = '777';
  $this->{msg}       = $msg;
  $this->{print_msg} = util::Constants::TRUE;
  $this->{sleep}     = 20 * 60;
  $this->_systemSpecifics;

  return $this;
}

sub setMode {
  my util::Cmd $this = shift;
  my ($mode) = @_;
  return if ( $mode !~ /^\d\d\d$/ );
  $this->{mode} = $mode;
}

sub setPrintMsg {
  my util::Cmd $this = shift;
  $this->{print_msg} = util::Constants::TRUE;
}

sub unsetPrintMsg {
  my util::Cmd $this = shift;
  $this->{print_msg} = util::Constants::FALSE;
}

################################################################################
#
#	       Public Methods (Standard File/Directory Operators)
#
################################################################################
###
### Determination of Bad Blocks
###
sub GZIP_CKSUM($$) {
  my util::Cmd $this = shift;
  my ($file) = @_;
  return "gunzip -t '$file'";
}

sub RM_DIR($$) {
  my util::Cmd $this = shift;
  my ($dir) = @_;
  return "/bin/rm -rf '$dir'";
}

sub RM_FILE($$) {
  my util::Cmd $this = shift;
  my ($file) = @_;
  return "/bin/rm -f '$file'";
}

sub APPEND_FILE($$$) {
  my util::Cmd $this = shift;
  my ($file, $dest) = @_;
  return "/bin/cat '$file' >> '$dest'";
}

sub CATENATE_FILE($$) {
  my util::Cmd $this = shift;
  my ($file) = @_;
  return "/bin/cat '$file'";
}

sub COPY_FILE($$$) {
  my util::Cmd $this = shift;
  my ( $source, $destination ) = @_;
  return "/bin/cp -f '$source' '$destination'";
}

sub LINK_FILE($$$) {
  my util::Cmd $this = shift;
  my ( $source, $destination ) = @_;
  return "ln -s '$source' '$destination'";
}

sub MOVE_FILE($$$) {
  my util::Cmd $this = shift;
  my ( $source, $destination ) = @_;
  return "/bin/mv -f '$source' '$destination'";
}

sub RM_FILE_IF_EXISTS($$$) {
  my util::Cmd $this = shift;
  my ( $file, $if_exists_file ) = @_;
  return "if [ -e $if_exists_file ]; then " . $this->RM_FILE($file) . '; fi';
}

sub GZIP_INPLACE($$) {
  my util::Cmd $this = shift;
  my ($file) = @_;
  return "gzip '$file'";
}

sub GZIP($$$) {
  my util::Cmd $this = shift;
  my ( $file, $gzip_file ) = @_;
  return "gzip -c '$file' > '$gzip_file'";
}

sub MK_DIR($$) {
  my util::Cmd $this = shift;
  my ($dir) = @_;
  return "mkdir -m " . $this->{mode} . " -p '$dir'";
}

sub TAR_DIR($$$) {
  my util::Cmd $this = shift;
  my ( $dir, $tar_file ) = @_;
  return $this->{tar} . " cf $tar_file '$dir'";
}

sub TAR_GZIP($$$$) {
  my util::Cmd $this = shift;
  my ( $switches, $source, $gzip_tar_file ) = @_;
  return $this->{tar}
    . " cf${switches} - '$source' | gzip -c > '$gzip_tar_file'";
}

sub TAR_DIR_GZIP($$$) {
  my util::Cmd $this = shift;
  my ( $dir, $gzip_tar_file ) = @_;
  return $this->TAR_GZIP( util::Constants::EMPTY_STR, $dir, $gzip_tar_file );
}

sub TAR_LIST_GZIP($$$) {
  my util::Cmd $this = shift;
  my ( $list_file, $gzip_tar_file ) = @_;
  my $file_switch = undef;
  return $this->TAR_GZIP( $this->{tar_switch}, $list_file, $gzip_tar_file );
}

sub GUNZIP_DIR($$) {
  my util::Cmd $this = shift;
  my ($gzip_tar_file) = @_;
  return "gunzip -c '$gzip_tar_file' | " . $this->{tar} . ' xf -';
}

sub TOOL_CMD($$) {
  my util::Cmd $this = shift;
  my ( $tool, $properties_file ) = @_;
  return "$tool -P '$properties_file'";
}

sub TOUCH_CMD($$) {
  my util::Cmd $this = shift;
  my ($file) = @_;
  return "touch '$file'";
}

sub TMP_FILE($$;$) {
  my util::Cmd $this = shift;
  my ( $prefix, $suffix ) = @_;
  my $hostname = `hostname -s`;
  chomp($hostname);
  sleep(1);
  my $tmp_file = join( util::Constants::DOT, $prefix, $hostname, time(), $$ );
  if ( defined($suffix) && $suffix ne util::Constants::EMPTY_STR ) {
    $tmp_file = join( util::Constants::DOT, $tmp_file, $suffix );
  }
  return $tmp_file;
}

sub DIFF_STRINGS($$$) {
  my util::Cmd $this = shift;
  my ( $str1, $str2 ) = @_;
  my $diff_str = util::Constants::EMPTY_STR;
  my $struct   = {
    file1 => {
      str  => $str1,
      file => undef,
    },
    file2 => {
      str  => $str2,
      file => undef,
    },
  };
  my $fh = new FileHandle;
  while ( my ( $file, $fstruct ) = each %{$struct} ) {
    $fstruct->{file} = $this->TMP_FILE( $file, '__DIFF_STRINGS__' );
    $fh->open( $fstruct->{file}, '>' );
    $fh->print( $fstruct->{str} );
    $fh->close;
  }
  $fh->open(
    join( util::Constants::SPACE,
      'diff',
      $struct->{file1}->{file},
      $struct->{file2}->{file}, '|'
    )
  );
  while ( !$fh->eof ) { $diff_str .= $fh->getline; }
  $fh->close;
  foreach my $fstruct ( values %{$struct} ) { unlink( $fstruct->{file} ); }
  return $diff_str;
}

sub CREATE_TMP_FILE($$) {
  my util::Cmd $this = shift;
  my ( $content ) = @_;

  my $fh = new FileHandle;
  my $tmp_file =
    join(util::Constants::SLASH,
	 '/var', 'tmp',
	 $this->TMP_FILE('TMP', 'txt'));
  my $status = ( !$fh->open( $tmp_file, '>>' ) );
  if ($status) {
    $this->{msg}->printError( "Cannot open tmp_file\n" . "  tmp_file = $tmp_file",
      $status );
    unlink($tmp_file);
    return ($status, undef);
  }
  eval {
    $fh->autoflush(util::Constants::TRUE);
    $fh->print($content);
    $fh->close;
  };
  my $estatus = $@;
  $status =
    ((defined($estatus) && $estatus) || !-e $tmp_file)
    ? util::Constants::TRUE : util::Constants::FALSE;
  if ($status) {
    $this->{msg}->printError( "Cannot write tmp_file\n" . "  tmp_file = $tmp_file",
      $status );
    unlink($tmp_file);
    return ($status, undef);
  }
  return ($status, $tmp_file);
}

################################################################################
#
#				Public Methods
#
################################################################################

sub executeCommand($$$$;$$) {
  my util::Cmd $this = shift;
  my ( $error_msgs, $cmd, $msg, $undo, $status ) = @_;
  $this->{msg}->printDebug("executeCommand:  ($cmd, $msg, $undo, $status)");
  my @cmds = $this->_cmdComponents( $cmd, $msg, $undo, $status );
  return util::Constants::TRUE if ( @cmds == 0 );
  return $this->_execCmd( $error_msgs, $cmds[0] );
}

sub executeRetry($$$@) {
  my util::Cmd $this = shift;
  my ( $retry_attempts, $error_msgs, @cmd_comps ) = @_;
  $this->{msg}->printDebug( 'executeRetry($retry_attempts):  ('
      . join( util::Constants::COMMA_SEPARATOR, @cmd_comps )
      . ')' );
  my @cmds = $this->_cmdComponents(@cmd_comps);
  return util::Constants::TRUE if ( @cmds == 0 );
  my $local_retry_attempts = $retry_attempts;
OUTER_LOOP:
  while ( $local_retry_attempts > 0 ) {
    sleep( $this->{sleep} ) if ( $local_retry_attempts < $retry_attempts );
    $local_retry_attempts--;
    foreach my $cmd_struct (@cmds) {
      my $status = $this->_execCmd( $error_msgs, $cmd_struct );
      return $status if ( $status && $local_retry_attempts == 0 );
      next OUTER_LOOP if ($status);
    }
    return util::Constants::FALSE;
  }
}

sub executeScript($$$$$) {
  my util::Cmd $this = shift;
  my ( $script_name, $script, $error_msgs, $msg ) = @_;
  my $tmp_file = $this->TMP_FILE( $script_name, 'cmd' );
  my $fh       = new FileHandle;
  my $status   = ( !$fh->open( $tmp_file, '>' ) );
  $this->{msg}->printError( "Cannot open tmp_file\n" . "  tmp_file = $tmp_file",
    $status );
  return $status if ($status);
  $fh->autoflush(util::Constants::TRUE);
  $fh->print($script);
  $fh->close;
  $status = $this->executeCommand(
    { tmp_file => $tmp_file },
    "chmod 775 $tmp_file",
    'Set tmp_file to executable...'
  );
  return $status if ($status);
  $status = $this->executeCommand( $error_msgs, $tmp_file, $msg );
  return $status if ($status);
  $status = $this->executeCommand(
    { tmp_file => $tmp_file },
    $this->RM_FILE($tmp_file),
    'Removing tmp_file...'
  );
  return $status;
}

sub createDirectory($$$;$) {
  my util::Cmd $this = shift;
  my ( $dir, $msg, $remove ) = @_;
  $dir = getPath($dir);
  $remove =
    ( defined($remove) && $remove )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  if ( -e $dir && $remove ) {
    $this->{msg}->dieOnError( "Error Removing directory:  $msg",
      $this->executeCommand( { tmp_dir => $dir }, $this->RM_DIR($dir), $msg ) );
  }
  if ( !-e $dir ) {
    $this->{msg}->dieOnError( "Error creating directory:  $msg",
      $this->executeCommand( { dir => $dir }, $this->MK_DIR($dir), $msg ) );
  }
  $this->{msg}
    ->dieOnError( "Directory does not exist:  $msg", !-e $dir || !-d $dir );
  return $dir;
}

sub executeInline {
  my util::Cmd $this = shift;
  my ($cmd) = @_;

  my $str = `$cmd`;
  $str =~ s/\n$//;
  return $str;
}

################################################################################

1;

__END__

=head1 NAME

Cmd.pm

=head1 SYNOPSIS

   use util::Cmd;

=head1 DESCRIPTION

This class exports standard system commands and standard mechanism for
executing commands and creating directories.

=head1 METHODS

The following methods are exported by this class.

=head2 B<util::Cmd::new(msg)>

This method is the constructor for the class.  It takes a messaging
object B<msg> that is a sub-class of the base class L<util::Msg>.

=head2 B<$execution_status = executeCommand(error_msgs, cmd, msg[, undo[, status] ])>

This method executes a system command B<cmd>.  The B<error_msgs>
referenced Perl Hash provides information to about the command to
write when an execution error occurs.  If printing informational
messages is set, then this information is also printed to the log upon
successful execution.  The message B<msg> provides information on the
purpose of the command.  The parameters B<undo> and B<status> provide
control over the command execution.  If the B<undo> command is
provided, then this command is executed if there is a command failure
in executing B<cmd>.  This method returns the execution status of
command execution.  If the command executes successfully, then FALSE
(0) is returned.  However, if command execution failed, then B<status>
is returned if it is defined not the value Zero (0).  Otherwise, upon
command execution failure, the value TRUE (1) is returned.

=head2 B<status = executeRetry(retry_attempts, error_msgs, @cmd_comps)>

This method will retry a command sequence B<retry_attempts> times.
The command sequence is identified by command list B<@cmd_comps>.
Each quadruple in the list is a command that identifies the following
components:

   cmd    -- the command
   msg    -- the informational message
   status -- return status upon unsuccessful execution (can be undef)
   undo   -- undo command (can be undef)

The B<error_msgs> referenced Perl Hash provides information to about
the command to write when an execution error occurs.  If printing
informational messages is set, then this information is also printed
to the log upon successful execution.  This method will return the
final status of executing the command sequence.  The status will be
FALSE (0), if the command sequence was executed successfully within
the B<retry_attempts> times, otherwise the status returned will not be
Zero (0).

=head2 B<$status = executeScript(script_name, script, error_msgs, msg)>

This method executed a system command script sequence contained in the
parameter B<script>.  This method creates a temporary executable
script file that contains the script and executes the script file.  If
the script is executed successfully, the the status FALSE (0) is
returned, otherwise the status TRUE (1) is returned.  If the script
fails to executed, then a error message including the B<error_msg>
Perl hash and the informational message B<msg> is written to the log.
If printing messages is set, an informational message containing the
B<error_msgs> and B<msg> will be generated to the log.

=head2 B<$created_dir = createDirectory(dir, msg[, remove ])>

This method creates a directory B<dir> if the directory does not
exist.  If the optional parameter B<remove> is presented and TRUE (1),
then an existing directory B<dir> will first be deleted before it is
created.  The B<msg> is used to print informational and error messages
about the creation of the directory.  The full pathname of the
directory is returned upon successful creation.  If there is a failure
to create the directory, the program calling this method will
terminate abnormally.

=head2 B<$diff_string = DIFF_STRINGS(str1, str2)>

This method takes the two strings B<str1> and B<str2> and stores them
temporarily into two files and executes a system diff on the two
files.  The output of the diff string returned is output generated by
the diff command.

=head1 INFORMATIONAL MESSAGE PRINTING METHODS

The following method control information messages during command
execution in this class.

=head2 B<setMode(mode)>

This method sets the mode for creating directories.  By default, it is
B<777>.

=head2 B<setPrintMsg>

This method sets informational message printing for command execution.

=head2 B<unsetPrintMsg>

This method unsets informational message printing for command
execution.

=head1 COMMAND GENERATION METHOD

The following command string generation methods are exported by this
class.

=head2 B<$cmd = GZIP_CKSUM(file)>

This method prepares the command that unzips a file with check sum

   'gunzip -t file'

=head2 B<$cmd = RM_DIR(dir)>

This method prepares the command that removes a directory from the
file system 

   '/bin/rm -rf dir'

=head2 B<$cmd = RM_FILE(file)>

This method prepares the command that forces the deletion of a file

   '/bin/rm -f file'

=head2 B<$cmd = CATENATE_FILE(file)>

This method prepares the command that catenates the file out

   '/bin/cat -u file'

=head2 B<$cmd = COPY_FILE(source, destination)>

This method prepares the command that forces a copy of a file
B<source> to another file B<destination>

   '/bin/cp -f source destination'

=head2 B<$cmd = MOVE_FILE(source, destination)>

This method prepares the command that forces the move of a file
B<source> to a destination file or directory (B<destination>)

   '/bin/mv -f source destination'

=head2 B<$cmd = RM_FILE_IF_EXISTS(source, if_exists_file)>

This method prepares the command that forces deletion of a file
B<source> if another file B<if_exists_file> exists in the file system.

   'if [ -e if_exists_file ]; then /bin/rm -f source ; fi'

=head2 B<$cmd = GZIP_INPLACE(file)>

This method prepares the command that gzips a file in-place

   'gzip file'

=head2 B<$cmd = GZIP(file, gzip_file)>

This method prepares the command that gzips a file B<file> and
identifies the gzip file as B<gzip_file> 

   'gzip -c file > gzip_file'

=head2 B<$cmd = MK_DIR(dir)>

This method prepares the command that creates a directory B<dir> and
any super directories in its path that do not exist

   'mkdir -m <mode> -p dir'

=head2 B<$cmd = TAR_DIR(dir, tar_file)>

This method prepares the command that tars a directory B<dir> into the
tar file B<tar_file> 

   '/bin/tar cf tar_file dir'

=head2 B<$cmd = TAR_GZIP(switches, source, gzip_tar_file)>

This method prepares the command that tars and gzip the tar of the
source B<source> and writes it to the file B<gzip_tar_file>.  Also,
optional switches B<switches> may be added to the tar command

   '/bin/tar cf{switches} - source | gzip -c > gzip_tar_file'

=head2 B<$cmd = TAR_DIR_GZIP(dir, gzip_tar_file)>

This method prepares the command that tars and gzip the tar of the
directory B<dir> and writes it to the file B<gzip_tar_file>.

   '/bin/tar cf - dir | gzip -c > gzip_tar_file'

=head2 B<$cmd = TAR_LIST_GZIP(list_file, gzip_tar_file)>

This method prepares the command that tars and gzips a selection
files/directories into a file B<gzip_tar_file>

   '/bin/tar cfT - list_file | gzip -c > gzip_tar_file'

=head2 B<$cmd = GUNZIP_DIR(gzip_tar_file)>

This method prepares the command that unzips and untars a gzip tar
file B<gzip_tar_file>

   'gunzip -c gzip_tar_file | /bin/tar xf -'

=head2 B<$cmd = TOOL_CMD(tool, properties_file)>

This method prepares the command that executes a tool with a
properties file 

   'tool -P properties'

=head2 B<$cmd = TOUCH_CMD(file)>

This method prepares the command that touches a file 

   'touch file'

=head2 B<$tmp_file_name = TMP_FILE(prefix [, suffix ])>

This method prepares the command that generates a temporary file name
using the B<prefix> and optional suffix B<suffix>.  The temporary file
name is defined as follows:

  B<prefix>.<hostname>.<process_id>.<current_time>[.<suffix>]

To prevent the B<current time> from being used twice in the same
program, this method does a One (1) second sleep before determing the
current (UNIX) time.

=cut
