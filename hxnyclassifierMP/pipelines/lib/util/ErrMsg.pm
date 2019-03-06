package util::ErrMsg;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Fcntl;
use Pod::Usage;

use util::Constants;
use util::PerlObject;
use util::Table;

use base 'util::Msg';

use fields qw(
  error_cats
  error_header
  error_msgs
  print_error_msgs
  read_write_ord
);

################################################################################
#
#			       Private Constants
#
################################################################################

sub ERRMSG_CAT { return -100000; }

sub ERRMSG_MSGS {
  return {
    &ERRMSG_CAT => {
          1 => "readStatsData:  undefined attribute in file, exiting...\n"
        . "  filename = __1__\n"
        . "  attr     = __2__",

      2 => "readStatsData:  Undefined error category, exiting...\n"
        . "  filename = __1__\n"
        . "  err_cat  = __2__",

      3 => "readStatsData:  Error category names differ, exiting...\n"
        . "  filename = __1__\n"
        . "  err_cat  = __2__\n"
        . "  name\n"
        . "    file   = __3__\n"
        . "    object = __4__",

    },
  };
}
###
### read/write order
###
sub READ_WRITE_ORDER {
  return [ 'error_cats', 'error_header', 'error_msgs', ];
}

################################################################################
#
#			   Private Methods
#
################################################################################

sub _getMsg($$$$;$) {
  my util::ErrMsg $this = shift;
  my ( $err_cat, $err_num, $replace_list, $print_stats ) = @_;
  $print_stats =
    ( defined($print_stats) && $print_stats )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  if ( defined( $this->{error_cats}->{$err_cat} ) ) {
    my $counts = $this->{error_cats}->{$err_cat}->{counts};
    if ( !defined( $counts->{$err_num} ) ) { $counts->{$err_num} = 0; }
    $counts->{$err_num}++;
  }
  $this->printStats if ($print_stats);
  return '(err_cat, err_num, replace_list) = ('
    . join( util::Constants::COMMA_SEPARATOR,
    $err_cat, $err_num, @{$replace_list} )
    . ')'
    if ( !defined( $this->{error_msgs}->{$err_cat} )
    || !defined( $this->{error_msgs}->{$err_cat}->{$err_num} ) );
  my $err_msg_num =
    ( $err_cat < 0 ) ? $err_cat - $err_num : $err_cat + $err_num;
  my $msg =
      $this->{error_header}
    . "$err_msg_num:\n"
    . $this->{error_msgs}->{$err_cat}->{$err_num};
  foreach my $index ( 0 .. $#{$replace_list} ) {
    my $pattern = '__' . ( $index + 1 ) . '__';
    my $replace = $replace_list->[$index];
    if ( !defined($replace) ) { $replace = 'undef'; }
    $msg =~ s/$pattern/$replace/g;
  }
  return $msg;
}

################################################################################
#
#				 Public Methods
#
################################################################################

sub new($$;$) {
  my ( $that, $header ) = @_;
  my util::ErrMsg $this = $that->SUPER::new;
  $this->unsetHardDie;
  if ( defined($header) && $header ne util::Constants::EMPTY_STR ) {
    $this->{error_header} = $header;
  }
  else {
    $this->{error_header} = 'DEFAULT-ERROR-';
  }
  $this->{error_msgs}       = {};
  $this->{error_cats}       = {};
  $this->{read_write_ord}   = READ_WRITE_ORDER;
  $this->{print_error_msgs} = util::Constants::TRUE;

  $this->addErrorMsgs(ERRMSG_MSGS);
  $this->addErrorCat( &ERRMSG_CAT, 'util::ErrMsg' );

  return $this;
}

sub setPrintErrorMsgs {
  my util::ErrMsg $this = shift;
  my ($print_error_msgs) = @_;
  return if ( util::Constants::EMPTY_LINE($print_error_msgs) );
  $this->{print_error_msgs} =
    $print_error_msgs ? util::Constants::TRUE : util::Constants::FALSE;
}

sub printErrorMsgs {
  my util::ErrMsg $this = shift;

  return $this->{print_error_msgs};
}

sub exitProgram($$$$$) {
  my util::ErrMsg $this = shift;
  my ( $err_cat, $err_num, $msgs, $error ) = @_;
  return if ( !defined($error) || !$error );
  $this->dieOnError(
    $this->_getMsg( $err_cat, $err_num, $msgs, util::Constants::TRUE ),
    $error );
}

sub hardDieOnError($$$$$) {
  my util::ErrMsg $this = shift;
  my ( $err_cat, $err_num, $msgs, $error ) = @_;
  return if ( !defined($error) || !$error );
  $this->setHardDie;
  $this->dieOnError(
    $this->_getMsg( $err_cat, $err_num, $msgs, util::Constants::TRUE ),
    $error );
}

sub printErrorMsg($$$$$) {
  my util::ErrMsg $this = shift;
  my ( $err_cat, $err_num, $msgs, $error ) = @_;
  return if ( !defined($error) || !$error );
  my $msg = $this->_getMsg( $err_cat, $err_num, $msgs );
  $this->printError( $msg, $error ) if ( $this->{print_error_msgs} );
}

sub firstLine {
  my util::ErrMsg $this = shift;
  my ( $err_cat, $err_num ) = @_;
  my $error_cat = $this->{error_msgs}->{$err_cat};
  return undef
    if ( !defined($error_cat) || !defined( $error_cat->{$err_num} ) );
  my @err_lines = split( /\n/, $error_cat->{$err_num} );
  return $err_lines[0];
}

sub errNum {
  my util::ErrMsg $this = shift;
  my ( $err_cat, $err_num ) = @_;
  my $error_cat = $this->{error_msgs}->{$err_cat};
  return undef
    if ( !defined($error_cat) || !defined( $error_cat->{$err_num} ) );
  my $err_num_str = undef;
  if   ( $err_cat >= 0 ) { $err_num_str = $err_cat + $err_num; }
  else                   { $err_num_str = $err_cat - $err_num; }
  return $err_num_str;
}

sub printStats {
  my util::ErrMsg $this = shift;
  my @err_cats = keys %{ $this->{error_cats} };
  return if ( @err_cats == 0 );
  my %cols = (
    num   => 'Error Num',
    count => 'Count',
    line  => 'Error First Line'
  );
  foreach my $err_cat (@err_cats) {
    ###
    ### Test to see if need to generate error statistics
    ###
    my $counts   = $this->{error_cats}->{$err_cat}->{counts};
    my @err_nums = keys %{$counts};
    next if ( @err_nums == 0 );
    ###
    ### Create the table
    ###
    my $table = new util::Table( $this, %cols );
    $table->setColumnOrder( 'num', 'count', 'line' );
    $table->setColumnJustification( 'num',   util::Table::RIGHT_JUSTIFY );
    $table->setColumnJustification( 'count', util::Table::RIGHT_JUSTIFY );
    $table->setColumnJustification( 'line',  util::Table::LEFT_JUSTIFY );
    $table->setColumnWidth( 'line', 80 );
    $table->setInHeader(util::Constants::TRUE);
    $table->setRowOrder('sub {$a->{num} <=> $b->{num};}');
    my $cat_header =
        "Category Errors\n"
      . "  category\n"
      . "    name   = "
      . $this->{error_cats}->{$err_cat}->{name} . "\n"
      . "    number = $err_cat\n"
      . "  errors";
    my @data = ();

    foreach my $err_num (@err_nums) {
      my $struct = {
        num   => $this->errNum( $err_cat,    $err_num ),
        count => $counts->{$err_num},
        line  => $this->firstLine( $err_cat, $err_num ),
      };
      push( @data, $struct );
    }
    $table->setData(@data);
    $table->generateTable($cat_header);
  }
}

sub writeStatsData {
  my util::ErrMsg $this = shift;
  my ($log_prefix) = @_;
  my $filename = join( util::Constants::DOT, $log_prefix, 'err_stats', 'pl' );
  unlink($filename);
  my $objfile = new util::PerlObject( $filename, undef, $this );
  foreach my $attr ( @{ $this->{read_write_ord} } ) {
    $objfile->writeStream( $this->{$attr},
      util::PerlObject::PERL_OBJECT_WRITE_OPTIONS );
  }
  $objfile->closeIo;
}

sub readStatsData {
  my util::ErrMsg $this = shift;
  my ($filename) = @_;
  my $objfile = new util::PerlObject( $filename, O_RDONLY, $this );
  my $stats_data = {};
  foreach my $attr ( @{ $this->{read_write_ord} } ) {
    $stats_data->{$attr} = $objfile->readStream;
  }
  $objfile->closeIo;
  ###
  ### First check to see that all categories
  ### are defined in this object
  ###
  my $error_mgs = $stats_data->{error_msgs};
  $this->exitProgram(
    ERRMSG_CAT, 1,
    [ $filename, 'error_mgs' ],
    !defined($error_mgs) || ref($error_mgs) ne util::PerlObject::HASH_TYPE
  );
  foreach my $err_cat ( keys %{$error_mgs} ) {
    my $msgs = $this->{error_msgs}->{$err_cat};
    $this->exitProgram( ERRMSG_CAT, 2, [ $filename, $err_cat ],
      !defined($msgs) );
  }
  my $error_cats = $stats_data->{error_cats};
  $this->exitProgram(
    ERRMSG_CAT, 1,
    [ $filename, 'error_cats' ],
    !defined($error_cats) || ref($error_cats) ne util::PerlObject::HASH_TYPE
  );
  while ( my ( $err_cat, $struct ) = each %{$error_cats} ) {
    my $name     = $struct->{name};
    my $counts   = $struct->{counts};
    my $obj_name = $this->{error_cats}->{$err_cat}->{name};
    $this->exitProgram(
      ERRMSG_CAT, 3,
      [ $filename, $err_cat, $name, $obj_name ],
      $name ne $obj_name
    );
    while ( my ( $err_num, $err_count ) = each %{$counts} ) {
      my $obj_counts = $this->{error_cats}->{$err_cat}->{counts};
      if ( !defined( $obj_counts->{$err_num} ) ) {
        $obj_counts->{$err_num} = 0;
      }
      $obj_counts->{$err_num} += $err_count;
    }
  }
}

################################################################################
#
#			    Setter Methods
#
################################################################################

sub addErrorMsg($$$) {
  my util::ErrMsg $this = shift;
  my ( $err_cat, $err_num, $err_msg ) = @_;
  $err_cat = int($err_cat);
  $err_num = int($err_num);
  return if ( $err_cat == 0 || $err_num <= 0 );
  if ( !defined( $this->{error_msgs}->{$err_cat} ) ) {
    $this->{error_msgs}->{$err_cat} = {};
  }
  $this->{error_msgs}->{$err_cat}->{$err_num} = $err_msg;
}

sub addErrorMsgs($) {
  my util::ErrMsg $this = shift;
  my ($error_msgs) = @_;
  while ( my ( $err_cat, $msgs ) = each %{$error_msgs} ) {
    while ( my ( $err_num, $err_msg ) = each %{$msgs} ) {
      $this->addErrorMsg( $err_cat, $err_num, $err_msg );
    }
  }
}

sub addErrorCat($$$) {
  my util::ErrMsg $this = shift;
  my ( $err_cat, $err_name ) = @_;
  my $error_cats = $this->{error_cats};
  return if ( $err_cat == 0
    || defined( $error_cats->{$err_cat} ) );
  $error_cats->{$err_cat} = {
    name   => $err_name,
    counts => {},
  };
}

sub addErrorCats($$) {
  my util::ErrMsg $this = shift;
  my ($error_cats) = @_;
  while ( my ( $err_cat, $err_name ) = each %{$error_cats} ) {
    $this->addErrorCat( $err_cat, $err_name );
  }
}

################################################################################

1;

__END__

=head1 NAME

ErrMsg.pm

=head1 SYNOPSIS

   use util::ErrMsg;

   sub ACCID_CAT {return 2000;}
   my $errMsg  = new util::ErrMsg('PU-ERROR-');
   $errMsg->addErrorMsg(ACCID_CAT, 23, 'Error in __1__ with a = __2__ will __3__');
   $errMsg->printErrorMsg(ACCID_CAT, 23, $foo, $bar, 'Exiting');
   $errMsg->addErrorCat(ACCID_CAT, 'PU::AccessionId');

=head1 DESCRIPTION

This class is a subclass of L<util::Msg> and extends this class to
print formated error messages as described below.

The B<err_cat>, B<err_num> and B<msgs> parameters in the methods below
have a standard definition described below.  An B<error message> is
generated by its template template that is identified by the B<error
category> (B<err_cat>) and B<error number> (B<err_num>) within the
error category.  The B<replacement substitutors> are defined by the
array reference B<msgs>.  The errors templates are added by the
L<"SETTER METHODS">.  If either the error category or error number are
not defined in the error message templates, then an simple string
listing the B<err_cat>, B<err_num> and the list of replacement
substitutors (B<msgs>) will be printed.  Each B<replace_value_I>
(1 <= I <= N) in the B<msgs> list replaces the corresponding template value
B<'__I__'> (1 <= I <= N).  Any template value that is not accounted
for in the parameter list (I > N) will be left unreplaced in the
returned message.  Any B<replace_value_I> that is undefined, B<undef>,
will also be replaced with the B<'undef'> string.

=head1 METHODS

The following methods are exported by this class including all the
method of the super class.

=head2 B<new util::ErrMsg([error_header])>

This method is the constructor of the class.  If the error_header is
not provided or is empty, it is set to B<DEFAULT-ERROR->.  This class
initially has no specialized error messages.  There are setter methods
to add these messages for a particular program or library.

B<This class sets the hard die to off.>

=head2 B<setPrintErrorMsgs(print_error_msgs)>

This method defines whether error messages will be printed
(print_error_msgs TRUE (1)) or not (print_error_msgs FALSE(0)) by
B<printErrorMsg>.  If print_error_msgs is undefined or empty, no
action is taken.  By default, printing error messages is set to TRUE(1).

=head2 B<exitProgram(err_cat, err_num, msgs, error)>

This method prints an error message and dies using B<dieOnError> if error is
TRUE, otherwise it does nothing.

=head2 B<hardDieOnError(err_cat, err_num, msgs, error)>

This method prints an error message and dies hard using B<dieOnError> if error
is TRUE, otherwise it does nothing.

=head2 B<printErrorMsg(err_cat, err_num, msgs, error)>

This method prints an error message if error is TRUE, otherwise it does nothing.

=head2 B<$first_line = firstLine(err_cat, err_num)>

This method returns the first line to the error message for the pair
B<(err_cat, err_num)>.  If there is none, then B<undef> is returned.

=head2 B<$error_num = errNum(err_cat, err_num)>

This method returns the error number associated with the error message
for the pair B<(err_cat, err_num)>.  If there is none, then B<undef>
is returned.

=head2 B<printStats>

This method prints the standard error message summary to the log

=head2 B<writeStatsData(log_prefix)>

This method writes the following object's attributes as Perl objects
to the file B<log_prefix.err_stats.pl>:

   error_cats
   error_header
   error_msgs

=head1 SETTER METHODS

These setter methods provide the mechanism for defining major and
minor error categories.

=head2 B<addErrorMsg(err_cat, err_num, err_msg)>

This method adds a new B<error message> (a string message) template
for a given B<error category> and B<error number>, a non-zero integer
B<err_cat> and positive integer B<err_num>, respectively.  If the
B<error category> is not defined, it will be.  If the B<error number>
already exists, it will be replaced.  Initially, the object will have
no error messages.  An B<error message> can be (multi-line) message
that contains replacement substitutors.  Each substitutor will have
the form B<'__I__'> where B<'I'> is an positive integer value.  This
designates the replacement substitutor as defined in L<"DESCRIPTION">
above.

=head2 B<addErrorMsgs(error_msgs)>

This method adds all the error message templates in B<error_msgs> in
the hash referenced data-structure to the object.  The data-structure
must have the following structure:

   $err_msg = $err_msgs->{$err_cat}->{$err_num}

This method iteratively call the L<"addErrorMsg(err_cat, err_num, err_msg)">
method using the triple:

   ($err_cat, $err_num, $err_msg)

=head2 B<addErrorCat(err_cat, err_name)>

This method adds a new B<error category> name for statistics
gathering.  and creates the counting data-structure. for the error
category.  The error_cat must be a non-zero integer.

=head2 B<addErrorCats(error_cats)>

This method adds all the error category names B<error_cats> in
the hash referenced data-structure to the object.  The data-structure
must have the following structure:

   $err_name = $err_cats->{$err_cat}

This method iteratively call the L<"addErrorCat(err_cat, err_name)">
method using the triple:

   ($err_cat, $err_name)

=head2 B<readStatsData(filename)>

This method reads the B<filename> assuming that the file has been
created by L<"writeStatsData(log_prefix)"> for an error messaging object
that has common error message categories and
names.  The method reads in the Perl object components in
the order as the writer:

   error_cats
   error_header
   error_msgs

Next, this method checks the consistency of the data.  Finally, this
method adds the statistics for the error categories into the object.
This allows statistics from several runs to be accumulated into one
object before being written or printed.

=cut
