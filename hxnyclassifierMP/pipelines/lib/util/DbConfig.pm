package util::DbConfig;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;
use Carp;

use vars qw(
  @ISA
  @EXPORT
);

################################################################################
#
#				Initializations
#
################################################################################

BEGIN {
  use Exporter();
  @ISA = qw(Exporter);

  @EXPORT = ('&read_db_config_file');
}

################################################################################
#
#				 Static Methods
#
################################################################################

sub read_db_config_file($) {
  my ($file) = @_;
  my @db_params;
  open( DBCONFIG, "<$file" )
    || confess "ERROR:  Can't open db config file $file";

  $_ = <DBCONFIG>;
  /^Server\s+(\w+)/
    || confess "ERROR:  db config file line Server '$_' is incorrect";
  push( @db_params, $1 );

  $_ = <DBCONFIG>;
  /^Database\s+(\w+)/
    || confess "ERROR:  db config file line Database '$_' is incorrect";
  push( @db_params, $1 );

  $_ = <DBCONFIG>;
  /^Username\s+(\w+)/
    || confess "ERROR:  db config file line Username '$_' is incorrect";
  push( @db_params, $1 );

  $_ = <DBCONFIG>;
  /^Password\s+(.+)/
    || confess "ERROR:  db config file line Password '$_' is incorrect";
  push( @db_params, $1 );

  my $db_hash            = {};
  my $found_optional_tag = 0;
  while (<DBCONFIG>) {
    /^(\w+)\s+(\w+)/
      || confess "ERROR:  db config file line optional tag '$_' is incorrect";
    $db_hash->{$1} = $2;
    $found_optional_tag = 1;
  }
  push( @db_params, $db_hash ) if ($found_optional_tag);

  close(DBCONFIG);

  return @db_params;
}

################################################################################

1;

__END__

=head1 NAME

DbConfig.pm

=head1 SYNOPSIS

   use util::DbConfig;

=head1 STATIC METHODS

=head2 read_db_config_file($)

This function takes in a file name for a db_config file. It parses
this file and returns an array.  The first four elements are the
connection information values for the Server, Database, Username, and
Password tags, respectively.  The optional fifth element is a
reference to a hash containing the (tag, value)-pairs for any optional
tags that follow in the db_config file.

The format for the db_config file is as follows, no space at the begining of
the line:

    Server        <<SERVER NAME>>
    Database      bcdev
    Username      immport_user
    Password      immport_user
    SchemaName    DEVELOPER
    DBTEXTSIZE    2000000
    ...

The B<Server> defines the database server type.  Currently, L<util::CachedDBI>
recognizes the following two types:  B<OracleDB> and B<mySQL>.

The Server, Database, Username, and Password are required tags and
must be the above order in the db_config file.  Optional tags can
follow the required ones (e.g., SchemaName, DBTEXTSIZE, etc.) and
be in any order.

=cut
