package util::Svn;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Cwd 'chdir';
use Pod::Usage;

use util::Cmd;
use util::Constants;
use util::Properties;

use fields qw(
  cmds
  msg
  revision
  svn_directory
  svn_root
  svn_username
  svn_password
  svn_path
);

################################################################################
#
#				   Constants
#
################################################################################
###
### Standard properties
###
sub SVN_PROPERTIES { return ( 'svn_root', 'svn_username', 'svn_password' ); }

################################################################################
#
#				Private Methods
#
################################################################################

sub _getSvnProperties {
  my util::Svn $this = shift;
  my ($props)        = @_;
  my $properties     = new util::Properties;
  eval { $properties->loadFile($props); };
  my $status = $@;
  $this->{msg}
    ->dieOnError( "Cannot Find properties $props\n" . "  errMsg = $status",
    defined($status) && $status );
  foreach my $prop (SVN_PROPERTIES) {
    $this->{msg}->dieOnError( "Undefined svn property $prop",
      util::Constants::EMPTY_LINE($prop) );
    $this->{$prop} = $properties->getProperty($prop);
  }
}

################################################################################
#
#			       Constructor Methods
#
################################################################################

sub new {
  my util::Svn $this = shift;
  my ( $svn_props, $msg ) = @_;
  $this = fields::new($this) unless ref($this);
  $this->{cmds} = new util::Cmd($msg);
  $this->{msg}  = $msg;
  $this->_getSvnProperties($svn_props);
  ###
  ### Return the object
  ###
  return $this;
}

################################################################################
#
#				 Setter Methods
#
################################################################################

sub setRevision {
  my util::Svn $this = shift;
  my ($revision) = @_;
  $this->{revision} =
    ( util::Constants::EMPTY_LINE($revision) ) ? undef : $revision;
}

sub setSvnPath {
  my util::Svn $this = shift;
  my ($path) = @_;
  $this->{svn_path} = ( util::Constants::EMPTY_LINE($path) ) ? undef : $path;
}

sub setSvnDirectory {
  my util::Svn $this = shift;
  my ($directory) = @_;
  $this->{svn_directory} =
    $this->{cmds}
    ->createDirectory( $directory, "Create SVN directory = $directory" );
}

################################################################################
#
#				 Getter Methods
#
################################################################################

sub checkout {
  my util::Svn $this = shift;
  my ($path) = @_;
  chdir(util::Constants::DOT);
  my $curr_dir = $ENV{PWD};
  $this->{msg}->printMsg("SVN checkout $path");
  $this->{msg}
    ->dieOnError( "svn_path not defined", !defined( $this->{svn_path} ) );
  $this->{msg}->dieOnError( "svn_directory not defined",
    !defined( $this->{svn_directory} ) );
  $this->{msg}->dieOnError( "cannot set svn directory",
    !chdir( $this->{svn_directory} ) );
  my $svn_ckout = join( util::Constants::SPACE,
    'svn', 'checkout', '--username', $this->{svn_username}, '--password',
    $this->{svn_password} );

  if ( defined( $this->{revision} ) ) {
    $svn_ckout = join( util::Constants::SPACE,
      $svn_ckout, '--revision', $this->{revision} );
  }
  $svn_ckout = join( util::Constants::SPACE,
    $svn_ckout,
    join( util::Constants::SLASH, $this->{svn_root}, $this->{svn_path}, $path )
  );
  $this->{msg}->dieOnError(
    "Failed to checkout svn directory $path",
    $this->{cmds}->executeCommand(
      { ckout => 'svn checkout' },
      $svn_ckout, "svn checkout path $path"
    )
  );
  chdir($curr_dir);
}

################################################################################

1;

__END__

=head1 NAME

Svn.pm

=head1 DESCRIPTION

This class defines the mechanism reading the standard svn data from the
user root file B<.svn.properties> and executing svn operations.  This class
assumes that the file, B<~/.svn.properties>, is defined and contains the
B<svn_root>, B<svn_username>, and B<svn_password>.

=head1 METHODS

These methods are used for creating this class.

=head2 B<new util::Svn(msg)>

This method is the constructor for this class. The B<msg> is the the
messaging objectPath of type L<util::Msg>.  The constructor reads the svn
properties file, B<~/.svn.properties>. By default,
the revision and svn_path for SVN to operate on is undefined.

=head1 SETTER METHODS

The following setter methods are exported for this class.

=head2 B<setRevision(revision)>

This method sets the revision to use on SVN operations. By default,
it is undefined.

=head2 B<setSvnPath(path)>

This method sets the B<svn_path> to use from the B<svn_root> for SVN
operation. By default, it is undefined.

=head2 B<setSvnDirectory(directory)>

This method sets the B<svn_path> to use from the B<svn_root> for SVN
operation. By default, it is undefined.

=head1 GETTER METHODS

The following getter methods are exported by this class.

=head2 B<checkout(path)>

This methods checks out the relative path from the SVN repository to the
B<svn_directory>

=cut
