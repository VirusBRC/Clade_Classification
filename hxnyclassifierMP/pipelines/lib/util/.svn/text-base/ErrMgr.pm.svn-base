package util::ErrMgr;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Pod::Usage;

use util::Constants;

use base 'util::ErrMsg';

use fields qw(
  count
  dbs
  threshold
);

################################################################################
#
#			       Private Constants
#
################################################################################

sub ERRMGR_CAT { return -200000; }

sub ERRMGR_MSGS {
  return {
    &ERRMGR_CAT => {
      1 => "Error Threshold exceeded, terminating...",

      2 => "Terminating Due to Errors...",
    },
  };
}

################################################################################
#
#				Private Methods
#
################################################################################

sub _exitProgram($$) {
  my util::ErrMgr $this = shift;
  my ($err_num) = @_;
  foreach my $db ( @{ $this->{dbs} } ) { $db->rollbackAndClose; }
  $this->printStats;
  $this->dieOnError(
    $this->_getMsg( ERRMGR_CAT, $err_num, [], util::Constants::TRUE ),
    util::Constants::TRUE );
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new($;$) {
  my ( $that, $header ) = @_;
  if ( !defined($header) || $header eq util::Constants::EMPTY_STR ) {
    $header = 'ERRMGR-ERRORS-';
  }
  my util::ErrMgr $this = $that->SUPER::new($header);
  $this->{count}     = 0;
  $this->{dbs}       = [];
  $this->{threshold} = undef;
  $this->addErrorMsgs(ERRMGR_MSGS);
  $this->addErrorCat( &ERRMGR_CAT, 'util::ErrMgr' );

  return $this;
}

sub registerError($$$$$) {
  my util::ErrMgr $this = shift;
  my ( $err_cat, $err_num, $msgs, $error ) = @_;
  return if ( !defined($error) || !$error );
  $this->printErrorMsg( $err_cat, $err_num, $msgs, $error );
  $this->{count}++;
  return
    if ( !defined( $this->{threshold} )
    || $this->{count} <= $this->{threshold} );
  $this->_exitProgram(1);
}

sub dieOnErrors {
  my util::ErrMgr $this = shift;
  return if ( $this->{count} == 0 );
  $this->_exitProgram(2);
}

sub exitProgram($$$$$) {
  my util::ErrMgr $this = shift;
  my ( $err_cat, $err_num, $msgs, $error ) = @_;
  return if ( !defined($error) || !$error );
  $this->registerError( $err_cat, $err_num, $msgs, $error );
  $this->dieOnErrors;
}

sub hardDieOnError($$$$$) {
  my util::ErrMgr $this = shift;
  my ( $err_cat, $err_num, $msgs, $error ) = @_;
  return if ( !defined($error) || !$error );
  $this->setHardDie;
  $this->registerError( $err_cat, $err_num, $msgs, $error );
  $this->dieOnErrors;
}

################################################################################
#
#				 Setter Methods
#
################################################################################

sub addDb($$) {
  my util::ErrMgr $this = shift;
  my ($db) = @_;
  return if ( !defined($db) || !ref($db) );
  push( @{ $this->{dbs} }, $db );
}

sub resetErrors {
  my util::ErrMgr $this = shift;
  $this->{count} = 0;
}

sub setThreshold($$) {
  my util::ErrMgr $this = shift;
  my ($threshold) = @_;
  if ( defined($threshold) ) {
    $threshold = int($threshold);
    return if ( $threshold < 0 );
  }
  $this->{threshold} = $threshold;
}

################################################################################
#
#				 Getter Methods
#
################################################################################

sub getErrors {
  my util::ErrMgr $this = shift;
  return $this->{count};
}

sub getThreshold {
  my util::ErrMgr $this = shift;
  return $this->{threshold};
}

################################################################################

1;

__END__

=head1 NAME

ErrMgr.pm

=head1 SYNOPSIS

  use util::ErrMgr;

  $error_mgr = new util::ErrMgr;
  $error_mgr->setThreshold(30);
  $error_mgr->resetErrors;

  $error_mgr->registerError
    ($err_cat, $err_num, 
     [$this->{gbw_profile}->genome_version,
      $this->{genome_version}],
     $this->{genome_version} != $this->{gbw_profile}->genome_version);

=head1 DESCRIPTION

This class defines the error manager and is a subclass of
L<util::ErrMsg>.  The error manager maintain an error count so that
when a threshold is exceeded it will cause the program to terminate
abnormally using B<exitProgram> (see L<util::ErrMsg>).  Also, this
class allows the program to terminate if any errors have occurred.
Objects manage the error count (incrementing it for each error
registered) and the threshold.  Finally, this class also rollbacks and
terminates database sessions registered with it (see L<"addDb(db)">.

=head1 METHODS

The following methods are provided by the class.

=head2 B<new util::ErrMgr([error_header]>

This method is the constructor for the class and creates an error
manager with an initial error count of zero (0) and an infinite error
threshold.  The error_header is optional and will be replaced by the
header B<ERRMGR-ERRORS->.

=head2 B<registerError(err_cat, err_num, msgs, error)>

This methods allows an error to be registered.  If error is TRUE(1),
then the msg is registered as an error, the error count is incremented
by one (1), and an error message is generated to the logging stream
using the err_cat, err_num and msgs array reference (see
L<util::ErrMsg>).  Finally, if the error count exceeds the error
threshold, then this class will terminate the program abnormally with
a non-zero status code and rollbacks and closes all registered
database sessions.

=head2 B<dieOnErrors>

This method will terminate the program abnormally with a non-zero
status code if the error count is greater than zero and rollbacks and
closes all registered database sessions.

=head2 B<exitProgram(err_cat, err_num, msgs, error)>

This method prints an error message and dies using L<"dieOnErrors"> if
error is TRUE, otherwise it does nothing.  This method re-implements
the same method in L<util::ErrMsg>.

=head2 B<hardDieOnError(err_cat, err_num, msgs, error)>

This method prints an error message and dies hard using
L<"dieOnErrors"> if error is TRUE, otherwise it does nothing.  This
method re-implements the same method in L<util::ErrMsg>.

=head1 SETTER METHODS

The following setter methods are provided by the class.
upon.

=head2 B<addDb(db)>

This method registers a database session with the error manager.  Upon
termination, the error manager will rollback any transactions and
close the database session.

=head2 B<resetErrors>

This method sets the error count to zero (0).

=head2 B<setThreshold(threshold)>

This method sets the error threshold.  If threshold 'undef', then the
threshold is considered infinite.

=head1 GETTER METHODS

The following getter methods are provided by the class.

=head2 B<getErrors>

This method returns the current error count.

=head2 B<getThreshold>

This method returns the current error threshold.

=cut
