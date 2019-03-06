package parallel::Lock;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use File::Basename;
use FileHandle;
use Pod::Usage;

use util::Constants;
use util::PathSpecifics;

use parallel::ErrMsgs;

use fields qw(
  error
  error_mgr
  lock_asserted
  lock_cmd
  lock_directory
  lock_file
  lock_tag
  tag_cmd
  tools
);

################################################################################
#
#			            Static Class Constants
#
################################################################################
###
### Error Category
###
sub ERR_CAT { return parallel::ErrMsgs::LOCK_CAT; }

################################################################################
#
#				Private Methods
#
################################################################################

sub _setError {
  my parallel::Lock $this = shift;
  my ($test) = @_;
  return if ( util::Constants::EMPTY_LINE($test) || !$test );
  $this->{error} = util::Constants::TRUE;
}

################################################################################
#
#				    Methods
#
################################################################################

sub new {
  my parallel::Lock $this = shift;
  my ( $lock_file, $error_mgr, $tools ) = @_;
  $this = fields::new($this) unless ref($this);

  $lock_file = getPath($lock_file);

  $this->{error_mgr}      = $error_mgr;
  $this->{error}          = util::Constants::FALSE;
  $this->{lock_asserted}  = util::Constants::FALSE;
  $this->{lock_directory} = dirname($lock_file);
  $this->{lock_file}      = $lock_file;
  $this->{lock_tag}       = $tools->cmds->TMP_FILE('tag');
  $this->{tools}          = $tools;

  $this->{lock_cmd} = join( util::Constants::SPACE,
    'echo', util::Constants::QUOTE . $this->{lock_tag} . util::Constants::QUOTE,
    '>', $this->{lock_file}
  );
  $this->{tag_cmd} = join( util::Constants::SPACE, 'cat', $this->{lock_file} );

  $this->{error_mgr}->printHeader( "Created Lock Object\n"
      . "  lock_file = "
      . $this->{lock_file} . "\n"
      . "  lock_tag  = "
      . $this->{lock_tag} . "\n"
      . "  lock_cmd  = "
      . $this->{lock_cmd} . "\n"
      . "  tag_cmd   = "
      . $this->{tag_cmd}
      . "\n" );

  return $this;
}

sub setLock {
  my parallel::Lock $this = shift;

  my $cmds = $this->{tools}->cmds;
  ###
  ### If failed in setting lock return immediately,
  ### otherwise you know that there has not been a
  ### failure in setting the lock
  ###
  return util::Constants::FALSE if ( $this->{error} );
  ###
  ### If lock already asserted, then return
  ### immediately
  ###
  return util::Constants::TRUE if ( $this->{lock_asserted} );
  ###
  ### Now attempt to assert the lock
  ###
  $this->_setError( !-e $this->{lock_directory}
      || !-d $this->{lock_directory} );
  $this->{error_mgr}
    ->registerError( ERR_CAT, 1, [ $this->{lock_directory} ], $this->{error} );
  return util::Constants::FALSE if ( $this->{error} );
  return util::Constants::FALSE if ( -e $this->{lock_file} );
  if ( !-e $this->{lock_file} ) {
    my $status =
      $cmds->executeCommand( { lock_file => basename( $this->{lock_file} ), },
      $this->{lock_cmd}, 'Asserting Lock' );
    return util::Constants::FALSE if ($status);
    my $lock_content = $cmds->executeInline( $this->{tag_cmd} );
    return util::Constants::FALSE
      if ( $lock_content ne $this->{lock_tag} );
    $this->{error_mgr}->printMsg("Asserted Lock");
  }
  else {
    return util::Constants::FALSE;
  }
  $this->{error}         = util::Constants::FALSE;
  $this->{lock_asserted} = util::Constants::TRUE;

  return util::Constants::TRUE;
}

sub removeLock {
  my parallel::Lock $this = shift;
  ###
  ### if failed in asserting lock or lock is not
  ### currently asserted, then cannot attempt to
  ### remove it.
  ###
  return util::Constants::FALSE
    if ( $this->{error} || !$this->{lock_asserted} );
  ###
  ### Now attempt to remove asserted lock
  ###
  my $removed_lock =
    ( unlink( $this->{lock_file} ) == 1 )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  if ($removed_lock) {
    $this->{error}         = util::Constants::FALSE;
    $this->{lock_asserted} = util::Constants::FALSE;
  }
  else {
    $this->{error} = util::Constants::TRUE;
    $this->{error_mgr}->registerError( ERR_CAT, 2,
      [ $this->{lock_directory}, $this->{lock_file} ],
      !$removed_lock );
  }

  return $removed_lock;
}

sub lockAsserted {
  my parallel::Lock $this = shift;
  return $this->{lock_asserted};
}

sub errorAsserted {
  my parallel::Lock $this = shift;
  return $this->{error};
}

sub getLockFile {
  my parallel::Lock $this = shift;
  return $this->{lock_file};
}

################################################################################

1;

__END__

=head1 NAME

Lock.pm

=head1 SYNOPSIS

  use parallel::Lock;

=head1 DESCRIPTION

This class defines a standard mechanism for asserting and removing
locks

=head1 METHODS

The following methods are exported by this class.

=head2 B<new parallel::Lock(lock_file, error_mgr, tools)>

This is the constructor for the class.

=cut
