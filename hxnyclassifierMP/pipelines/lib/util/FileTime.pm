package util::FileTime;
################################################################################
#
#				Required Modules
#
################################################################################

use strict;

use Carp 'confess';
use Time::Local;
use Pod::Usage;

use util::Constants;

use vars qw(
  @ISA
  @EXPORT
  $VERSION

  $ORACLE_DATE
  $UNIX_DATE

  %DATE_TYPES
);

################################################################################
#
#				Initializations
#
################################################################################

BEGIN {
  use Exporter();
  @ISA = qw(Exporter);

  $ORACLE_DATE = 'oracle_date';
  $UNIX_DATE   = 'unix_date';

  %DATE_TYPES = (
    $ORACLE_DATE => util::Constants::EMPTY_STR,
    $UNIX_DATE   => util::Constants::EMPTY_STR
  );

  @EXPORT = (
    '$ORACLE_DATE',
    '$UNIX_DATE',
    '%DATE_TYPES',

    '&OracleDateFormat',
    '&OracleDateOnlyFormat',

    '&get_str_time',
    '&get_str_date',
    '&get_oracle_str',

    '&get_cds_date',
    '&get_cds_str',

    '&get_cef_date',

    '&get_edi_str',

    '&get_gbw_time',
    '&get_gbw_str',

    '&get_hla_time',
    '&get_hla_str',

    '&get_mdy_time',
    '&get_mdy_str',

    '&get_mysql_time',
    '&get_mysql_date',
    '&get_mysql_str',

    '&get_ncbi_time',
    '&get_ncbi_str',

    'get_dbsnp_time',
    'get_dbsnp_str',

    'get_excel_time',

    'get_gene_ontology_time',

    '&get_entrez_time',
    '&get_entrez_date',

    '&get_fasta_str',

    'get_prebcp_str',

    '&get_unix_time',
    '&get_unix_str',

    '&get_file_time',

    '&set_date',

    '&equals',
    '&later_than',
    '&later_than_or_equals',

    '&SECONDS_IN_DAY'
  );

}

################################################################################
#
#			       Private Constants
#
################################################################################
###
### Time Components
###
sub _DAY_    { return 'da'; }
sub _HOUR_   { return 'hr'; }
sub _MINUTE_ { return 'mi'; }
sub _SECOND_ { return 'se'; }
sub _MONTH_  { return 'mo'; }
sub _YEAR_   { return 'yr'; }
sub _WDAY_   { return 'wd'; }
sub _YDAY_   { return 'yd'; }
sub _GMT_    { return 'gm'; }
###
### Stat Components
###
sub _MTIME_ { return 'mtime'; }
###
### Time String Checks
###
sub _CENTURY_YEAR_      { return 100; }
sub _LEAP_CENTURY_      { return 400; }
sub _LEAP_DAYS_         { return 29; }
sub _LEAP_MONTH_        { return 2; }
sub _LEAP_YEAR_         { return 4; }
sub _NUMBER_OF_HOURS_   { return 23; }
sub _NUMBER_OF_MINUTES_ { return 59; }
sub _NUMBER_OF_MONTHS_  { return 12; }
sub _NUMBER_OF_SECONDS_ { return 59; }

sub _MONTH_OFFSET_ { return 1; }
sub _YEAR_OFFSET_  { return 1900; }
###
### Time String Separators
###
sub _CDS_DATE_SEPARATOR_ { return util::Constants::SLASH; }

sub _EDI_DATE_SEPARATOR_ { return util::Constants::UNDERSCORE; }

sub _FASTA_DATE_SEPARATOR_ { return util::Constants::EMPTY_STR; }

sub _PREBCP_TIME_SEPARATOR_ { return util::Constants::EMPTY_STR; }

sub _GBW_DATE_SEPARATOR_      { return util::Constants::SLASH; }
sub _GBW_DATE_TIME_SEPARATOR_ { return util::Constants::SPACE; }
sub _GBW_TIME_SEPARATOR_      { return util::Constants::COLON; }

sub _HLA_DATE_SEPARATOR_ { return util::Constants::SLASH; }

sub _MDY_DATE_SEPARATOR_ { return util::Constants::HYPHEN; }

sub _MYSQL_DATE_SEPARATOR_      { return util::Constants::HYPHEN; }
sub _MYSQL_DATE_TIME_SEPARATOR_ { return util::Constants::SPACE; }
sub _MYSQL_TIME_SEPARATOR_      { return util::Constants::COLON; }

sub _NCBI_DATE_SEPARATOR_ { return util::Constants::HYPHEN; }

sub _DBSNP_DATE_SEPARATOR_      { return util::Constants::HYPHEN; }
sub _DBSNP_DATE_TIME_SEPARATOR_ { return util::Constants::SPACE; }
sub _DBSNP_TIME_SEPARATOR_      { return util::Constants::COLON; }

sub _ORACLE_DATE_SEPARATOR_      { return util::Constants::HYPHEN; }
sub _ORACLE_DATE_TIME_SEPARATOR_ { return util::Constants::COLON; }

###
### Excel Epoch
###
sub SECONDS_IN_DAY                          { return 86400 }
sub _SECONDS_FROM_EXEL_EPOCH_TO_UNIX_EPOCH_ { return 86400 * 25569 }

################################################################################
#
#			     Private Static Methods
#
################################################################################

sub _statComponent {
  my ($comp) = @_;
  return 9 if ( $comp eq _MTIME_ );
  return undef;
}

sub _fixStandardRepresentation {
  my ($time_ref) = @_;
  my %time = %{$time_ref};
  foreach my $key ( _MONTH_, _DAY_, _HOUR_, _MINUTE_, _SECOND_ ) {
    if ( $time{$key} < 10 ) { $time{$key} = '0' . $time{$key}; }
  }
  return %time;
}

sub _monthDays {
  my ($month_num) = @_;
  $month_num = int($month_num);
  return undef if ( $month_num < 0 || $month_num > _NUMBER_OF_MONTHS_ );
  return 28 if ( $month_num == 2 );
  return 30
    if ( $month_num == 4
    || $month_num == 6
    || $month_num == 9
    || $month_num == 11 );
  return 31;
}

sub _monthToStr {
  my ($month_num) = @_;
  $month_num = int($month_num);
  return 'Jan' if ( $month_num == 1 );
  return 'Feb' if ( $month_num == 2 );
  return 'Mar' if ( $month_num == 3 );
  return 'Apr' if ( $month_num == 4 );
  return 'May' if ( $month_num == 5 );
  return 'Jun' if ( $month_num == 6 );
  return 'Jul' if ( $month_num == 7 );
  return 'Aug' if ( $month_num == 8 );
  return 'Sep' if ( $month_num == 9 );
  return 'Oct' if ( $month_num == 10 );
  return 'Nov' if ( $month_num == 11 );
  return 'Dec' if ( $month_num == 12 );
  return undef;
}

sub _strToMonth {
  my ($month_str) = @_;
  $month_str = ucfirst( lc($month_str) );
  return 1  if ( $month_str eq 'Jan' );
  return 2  if ( $month_str eq 'Feb' );
  return 3  if ( $month_str eq 'Mar' );
  return 4  if ( $month_str eq 'Apr' );
  return 5  if ( $month_str eq 'May' );
  return 6  if ( $month_str eq 'Jun' );
  return 7  if ( $month_str eq 'Jul' );
  return 8  if ( $month_str eq 'Aug' );
  return 9  if ( $month_str eq 'Sep' );
  return 10 if ( $month_str eq 'Oct' );
  return 11 if ( $month_str eq 'Nov' );
  return 12 if ( $month_str eq 'Dec' );
  return undef;
}

################################################################################
#
#				 Static Methods
#
################################################################################

sub OracleDateFormat     { return "'DD-Mon-yyyy:hh24:mi:ss'"; }
sub OracleDateOnlyFormat { return "'DD-Mon-yyyy'"; }

sub equals(\%\%) {
  my ( $time_ref, $later_ref ) = @_;
  return (
    ( &get_unix_str($time_ref) == &get_unix_str($later_ref) )
    ? util::Constants::TRUE
    : util::Constants::FALSE
  );
}

sub later_than(\%\%) {
  my ( $time_ref, $later_ref ) = @_;
  return (
    ( &get_unix_str($time_ref) > &get_unix_str($later_ref) )
    ? util::Constants::TRUE
    : util::Constants::FALSE
  );
}

sub later_than_or_equals(\%\%) {
  my ( $time_ref, $later_ref ) = @_;
  return (
    ( &get_unix_str($time_ref) >= &get_unix_str($later_ref) )
    ? util::Constants::TRUE
    : util::Constants::FALSE
  );
}

sub get_file_time($;$) {
  my ( $filename, $is_gmt_time ) = @_;
  my @stat_array = ();
  eval { @stat_array = stat($filename); };
  confess "Error:  Cannot get most recent mod Time in FileTime::get_file_time\n"
    . "Error:  file      = $filename\n"
    . "Error:  error msg = $@\n"
    if ( defined($@) && $@ );
  return &get_unix_time( $stat_array[ _statComponent(_MTIME_) ], $is_gmt_time );
}

sub get_str_time($;$) {
  my ( $time_str, $is_gmt_time ) = @_;
  my $time_item           = {};
  my $date_time_separator = _ORACLE_DATE_TIME_SEPARATOR_;
  my $date_separator      = _ORACLE_DATE_SEPARATOR_;
  my $day_month_year;
  (
    $day_month_year,         $time_item->{&_HOUR_},
    $time_item->{&_MINUTE_}, $time_item->{&_SECOND_}
  ) = split( /$date_time_separator/, $time_str );
  ( $time_item->{&_DAY_}, $time_item->{&_MONTH_}, $time_item->{&_YEAR_} ) =
    split( /$date_separator/, $day_month_year );
  $time_item->{&_GMT_} =
    ( defined($is_gmt_time) && $is_gmt_time )
    ? util::Constants::TRUE
    : util::Constants::FALSE;
  ###
  ### Standardize integer data
  ###
  $time_item->{&_MONTH_} = _strToMonth( $time_item->{&_MONTH_} );
  foreach my $key ( keys %{$time_item} ) {
    next if ( !defined( $time_item->{$key} ) );
    $time_item->{$key} = int( $time_item->{$key} );
  }
  ###
  ### Check Conformance
  ###
  confess "Incorrect Month Value:  $time_str\n"
    if ( !defined( $time_item->{&_MONTH_} ) );
  confess "Incorrect Year Value:  $time_str\n"
    if ( !defined( $time_item->{&_YEAR_} ) || $time_item->{&_YEAR_} <= 0 );
  confess "Incorrect Day Value:  $time_str\n"
    if ( !defined( $time_item->{&_DAY_} ) || $time_item->{&_DAY_} <= 0 );
  if ( $time_item->{&_MONTH_} == _LEAP_MONTH_ ) {
    if (
      (
           $time_item->{&_YEAR_} % _LEAP_YEAR_ == 0
        && $time_item->{&_YEAR_} % _CENTURY_YEAR_ != 0
      )
      || ( $time_item->{&_YEAR_} % _LEAP_CENTURY_ == 0 )
      )
    {
      confess "Incorrect Day Value:  $time_str\n"
        if ( $time_item->{&_DAY_} > _LEAP_DAYS_ );
    }
    else {
      confess "Incorrect Day Value:  $time_str\n"
        if ( $time_item->{&_DAY_} > _monthDays( $time_item->{&_MONTH_} ) );
    }
  }
  else {
    confess "Incorrect Day Value:  $time_str\n"
      if ( $time_item->{&_DAY_} > _monthDays( $time_item->{&_MONTH_} ) );
  }
  confess "Incorrect Hour Value:  $time_str\n"
    if ( !defined( $time_item->{&_HOUR_} )
    || $time_item->{&_HOUR_} < 0
    || $time_item->{&_HOUR_} > _NUMBER_OF_HOURS_ );
  confess "Incorrect Minute Value:  $time_str\n"
    if ( !defined( $time_item->{&_MINUTE_} )
    || $time_item->{&_MINUTE_} < 0
    || $time_item->{&_MINUTE_} > _NUMBER_OF_MINUTES_ );
  confess "Incorrect Second Value:  $time_str\n"
    if ( !defined( $time_item->{&_SECOND_} )
    || $time_item->{&_SECOND_} < 0
    || $time_item->{&_SECOND_} > _NUMBER_OF_SECONDS_ );

  return $time_item;
}

sub get_str_date($;$) {
  my ( $date_str, $is_gmt_time ) = @_;
  return &get_str_time( $date_str . ':00:00:00', $is_gmt_time );
}

sub get_cef_date($$$;$) {
  my ( $mon, $day, $year, $is_gmt_time ) = @_;
  ###
  ### In UNIX, format, must adjust year and month
  ###
  if ( $year < _YEAR_OFFSET_ ) {
    $year += _YEAR_OFFSET_;
    $mon  += _MONTH_OFFSET_;
  }
  return &get_str_date(
    join( _ORACLE_DATE_SEPARATOR_, $day, _monthToStr($mon), $year ),
    $is_gmt_time );
}

sub get_entrez_time($$$$$$;$) {
  my ( $mon, $day, $year, $hour, $minute, $second, $is_gmt_time ) = @_;
  return &get_str_time(
    join(
      _ORACLE_DATE_TIME_SEPARATOR_,
      join( _ORACLE_DATE_SEPARATOR_, $day, _monthToStr($mon), $year ),
      ( !defined($hour) || $hour eq util::Constants::EMPTY_STR ) ? 0 : $hour,
      ( !defined($minute) || $minute eq util::Constants::EMPTY_STR ) ? 0
      : $minute,
      ( !defined($second) || $second eq util::Constants::EMPTY_STR ) ? 0
      : $second
    ),
    $is_gmt_time
  );
}

sub get_dbsnp_time($;$) {
  my ( $date_time, $is_gmt_time ) = @_;
  my $month   = undef;
  my $day     = undef;
  my $year    = undef;
  my $hour    = undef;
  my $minutes = undef;
  if ( $date_time =~ /^(\d+)-(\d+)-(\d+) +(\d+):(\d+)$/ ) {
    $month   = $2;
    $day     = $3;
    $year    = $1;
    $hour    = $4;
    $minutes = $5;
  }
  else {
    confess "Error:  Cannot get parse dbSNP time\n"
      . "Error:  date_time    = $date_time\n"
      . "Error:  24 hr format = YYYY-MM-DD HH:SS\n";
  }
  return get_entrez_time( $month, $day, $year, $hour, $minutes, 0,
    $is_gmt_time );
}

sub get_entrez_date($;$) {
  my ( $date_time, $is_gmt_time ) = @_;
  my $month   = undef;
  my $day     = undef;
  my $year    = undef;
  my $hour    = undef;
  my $minutes = undef;
  if ( $date_time =~ /^(...) +(\d+) +(\d+) +(\d+):(\d+)(..)$/ ) {
    $month   = _strToMonth($1);
    $day     = $2;
    $year    = $3;
    $hour    = $4;
    $minutes = $5;
    my $day_part = $6;
    if ( $day_part eq 'PM' && $hour < 12 ) { $hour += 12; }
    elsif ( $day_part eq 'AM' && $hour == 12 ) { $hour = 0; }
  }
  elsif ( $date_time =~ /^(\d+)-(\d+)-(\d+) +(\d+):(\d+) +(...)$/ ) {
    $month   = $2;
    $day     = $3;
    $year    = $1;
    $hour    = $4;
    $minutes = $5;
  }
  else {
    confess "Error:  Cannot get parse entrez data\n"
      . "Error:  date_time    = $date_time\n"
      . "Error:  12-hr format = MMM [D]D YYYY [H]H:MM(AM|PM)\n"
      . "Error:  24-hr format = YYYY-MM-DD HH:MM (EDT|EST)\n";
  }
  return get_entrez_time( $month, $day, $year, $hour, $minutes, 0,
    $is_gmt_time );
}

sub get_gene_ontology_time($;$) {
  my ( $date_time, $is_gmt_time ) = @_;
  my $month   = undef;
  my $day     = undef;
  my $year    = undef;
  my $hour    = undef;
  my $minutes = undef;
  if ( $date_time =~ /^(\d+):(\d+):(\d+)\s+(\d+):(\d+)$/ ) {
    $month   = $2;
    $day     = $1;
    $year    = $3;
    $hour    = $4;
    $minutes = $5;
  }
  else {
    confess "Error:  Cannot get parse gene ontology data data\n"
      . "Error:  date_time    = $date_time\n"
      . "Error:  24 hr format = DD:MM:YYYY HH:SS\n";
  }
  return get_entrez_time( $month, $day, $year, $hour, $minutes, 0,
    $is_gmt_time );
}

sub get_cds_date($;$) {
  my ( $date_str, $is_gmt_time ) = @_;
  my $date_separator = _CDS_DATE_SEPARATOR_;
  my ( $mon, $day, $year ) = split( /$date_separator/, $date_str );
  $mon =~ s/^0//;
  return &get_str_date(
    join( _ORACLE_DATE_SEPARATOR_, $day, _monthToStr($mon), $year ),
    $is_gmt_time );
}

sub get_gbw_time($;$) {
  my ( $date_time_str, $is_gmt_time ) = @_;
  my $date_time_separator = _GBW_DATE_TIME_SEPARATOR_;
  my $date_separator      = _GBW_DATE_SEPARATOR_;
  my ( $date_str, $time_str ) = split( /$date_time_separator/, $date_time_str );
  my ( $mon, $day, $year ) = split( /$date_separator/, $date_str );
  $mon =~ s/^0//;
  return &get_str_time(
    join(
      _ORACLE_DATE_TIME_SEPARATOR_,
      join( _ORACLE_DATE_SEPARATOR_, $day, _monthToStr($mon), $year ), $time_str
    ),
    $is_gmt_time
  );
}

sub get_hla_time($;$) {
  my ( $date_str, $is_gmt_time ) = @_;
  my $date_separator = _HLA_DATE_SEPARATOR_;
  my ( $day, $mon, $year ) = split( /$date_separator/, $date_str );
  $day =~ s/^0//;
  $mon =~ s/^0//;
  return &get_str_date(
    join( _ORACLE_DATE_SEPARATOR_, $day, _monthToStr($mon), $year ),
    $is_gmt_time );
}

sub get_mdy_time($;$) {
  my ( $date_str, $is_gmt_time ) = @_;
  my $date_separator = _MDY_DATE_SEPARATOR_;
  my ( $mon, $day, $year ) = split( /$date_separator/, $date_str );
  $day =~ s/^0//;
  $mon =~ s/^0//;
  return &get_str_date(
    join( _ORACLE_DATE_SEPARATOR_, $day, _monthToStr($mon), $year ),
    $is_gmt_time );
}

sub get_mysql_time($;$) {
  my ( $date_time_str, $is_gmt_time ) = @_;
  my $date_time_separator = _MYSQL_DATE_TIME_SEPARATOR_;
  my $date_separator      = _MYSQL_DATE_SEPARATOR_;
  my ( $date_str, $time_str ) = split( /$date_time_separator/, $date_time_str );
  my ( $year, $mon, $day ) = split( /$date_separator/, $date_str );
  $day =~ s/^0//;
  $mon =~ s/^0//;
  return &get_str_time(
    join(
      _ORACLE_DATE_TIME_SEPARATOR_,
      join( _ORACLE_DATE_SEPARATOR_, $day, _monthToStr($mon), $year ), $time_str
    ),
    $is_gmt_time
  );
}

sub get_mysql_date($;$) {
  my ( $date_str, $is_gmt_time ) = @_;
  my $date_separator = _MYSQL_DATE_SEPARATOR_;
  my ( $year, $mon, $day ) = split( /$date_separator/, $date_str );
  $day =~ s/^0//;
  $mon =~ s/^0//;
  return &get_str_date(
    join( _ORACLE_DATE_SEPARATOR_, $day, _monthToStr($mon), $year ),
    $is_gmt_time );
}

sub get_ncbi_time($;$) {
  my ( $date_str, $is_gmt_time ) = @_;
  my $date_separator = _NCBI_DATE_SEPARATOR_;
  my ( $day, $mon, $year ) = split( /$date_separator/, $date_str );
  $day =~ s/^0//;
  return &get_str_date( join( _ORACLE_DATE_SEPARATOR_, $day, $mon, $year ),
    $is_gmt_time );
}

sub get_unix_time($;$) {
  my ( $unix_time, $is_gmt_time ) = @_;
  my $time_item  = {};
  my @time_array = ();
  eval {
    if ( defined($is_gmt_time) && $is_gmt_time )
    {
      @time_array = gmtime($unix_time);
      $time_item->{&_GMT_} = util::Constants::TRUE;
    }
    else {
      @time_array = localtime($unix_time);
      $time_item->{&_GMT_} = util::Constants::FALSE;
    }
  };
  confess "Error:  Cannot get time record in FileTime::get_unix_time\n"
    . "Error:  unix_time = $unix_time\n"
    . "Error:  error msg = $@\n"
    if ( defined($@) && $@ );
  ###
  ### Allocate the time components of time_array
  ### from gmtime and localtime
  ###
  my $index = 0;
  foreach
    my $time_comp ( _SECOND_, _MINUTE_, _HOUR_, _DAY_, _MONTH_, _YEAR_, _WDAY_,
    _YDAY_ )
  {
    $time_item->{$time_comp} = $time_array[$index];
    if ( $time_comp eq _YEAR_ ) {
      $time_item->{$time_comp} += _YEAR_OFFSET_;
    }
    elsif ( $time_comp eq _MONTH_ ) {
      $time_item->{$time_comp} += _MONTH_OFFSET_;
    }
    $index++;
  }
  return $time_item;
}

# Our assumption is that Excel time is always GMT time, hence we don't need a
# is_gmt_time parameter to get_excel_time

sub get_excel_time ($;$) {
  my ( $excel_time, $day_fraction ) = @_;

  return undef
    if !( $excel_time =~ /^\d+$/ || $excel_time =~ /^\d+\.{1,1}\d+$/ );
  return undef if defined($day_fraction) && $day_fraction !~ /^0\.{1,1}\d+$/;

  my $days     = int($excel_time);
  my $day_part = $excel_time - $days;
  my $seconds  = ( $days * SECONDS_IN_DAY );
  $seconds += int( $day_part * SECONDS_IN_DAY );
  $seconds += int( $day_fraction * SECONDS_IN_DAY ) if defined($day_fraction);

  my $unix_time = $seconds - _SECONDS_FROM_EXEL_EPOCH_TO_UNIX_EPOCH_;
  return get_unix_time( $unix_time, util::Constants::TRUE );
}

sub set_date(\%) {
  my ($time_ref) = @_;
  $time_ref->{&_HOUR_}   = 0;
  $time_ref->{&_MINUTE_} = 0;
  $time_ref->{&_SECOND_} = 0;
}

sub get_oracle_str(\%;$) {
  my ( $time_ref, $date_only ) = @_;
  my %time     = _fixStandardRepresentation($time_ref);
  my $date_str = join(
    _ORACLE_DATE_SEPARATOR_,
    $time{&_DAY_}, _monthToStr( $time_ref->{&_MONTH_} ),
    $time{&_YEAR_}
  );
  return $date_str if ( defined($date_only) && $date_only );
  return join( _ORACLE_DATE_TIME_SEPARATOR_,
    $date_str, $time{&_HOUR_}, $time{&_MINUTE_}, $time{&_SECOND_} );
}

sub get_gbw_str(\%;$) {
  my ( $time_ref, $date_only ) = @_;
  my %time = _fixStandardRepresentation($time_ref);
  my $date_str =
    join( _GBW_DATE_SEPARATOR_, $time{&_MONTH_}, $time{&_DAY_},
    $time{&_YEAR_} );
  return $date_str if ( defined($date_only) && $date_only );
  return join(
    _GBW_DATE_TIME_SEPARATOR_,
    $date_str,
    join(
      _GBW_TIME_SEPARATOR_,
      $time{&_HOUR_}, $time{&_MINUTE_}, $time{&_SECOND_}
    )
  );
}

sub get_hla_str(\%) {
  my ( $time_ref, $date_only ) = @_;
  my %time = _fixStandardRepresentation($time_ref);
  my $date_str =
    join( _HLA_DATE_SEPARATOR_, $time{&_DAY_}, $time{&_MONTH_},
    $time{&_YEAR_} );
  return $date_str;
}

sub get_mdy_str(\%) {
  my ( $time_ref, $date_only ) = @_;
  my %time = _fixStandardRepresentation($time_ref);
  my $date_str =
    join( _MDY_DATE_SEPARATOR_, $time{&_DAY_}, $time{&_MONTH_},
    $time{&_YEAR_} );
  return $date_str;
}

sub get_mysql_str(\%;$) {
  my ( $time_ref, $date_only ) = @_;
  my %time     = _fixStandardRepresentation($time_ref);
  my $date_str = join( _MYSQL_DATE_SEPARATOR_,
    $time{&_YEAR_}, $time{&_MONTH_}, $time{&_DAY_} );
  return $date_str if ( defined($date_only) && $date_only );
  return join(
    _MYSQL_DATE_TIME_SEPARATOR_,
    $date_str,
    join(
      _MYSQL_TIME_SEPARATOR_,
      $time{&_HOUR_}, $time{&_MINUTE_}, $time{&_SECOND_}
    )
  );
}

sub get_ncbi_str(\%;$) {
  my ($time_ref) = @_;
  my %time = _fixStandardRepresentation($time_ref);
  return join(
    _NCBI_DATE_SEPARATOR_,
    $time{&_DAY_}, uc( _monthToStr( $time{&_MONTH_} ) ),
    $time{&_YEAR_}
  );
}

sub get_dbsnp_str(\%;$) {
  my ( $time_ref, $date_only ) = @_;
  my %time     = _fixStandardRepresentation($time_ref);
  my $date_str = join( _DBSNP_DATE_SEPARATOR_,
    $time{&_YEAR_}, $time{&_MONTH_}, $time{&_DAY_} );
  return $date_str if ( defined($date_only) && $date_only );
  return join( _DBSNP_DATE_TIME_SEPARATOR_,
    $date_str,
    join( _DBSNP_TIME_SEPARATOR_, $time{&_HOUR_}, $time{&_MINUTE_} ) );
}

sub get_cds_str(\%) {
  my ($time_ref) = @_;
  my %time = _fixStandardRepresentation($time_ref);
  return
    join( _CDS_DATE_SEPARATOR_, $time{&_MONTH_}, $time{&_DAY_},
    $time{&_YEAR_} );
}

sub get_edi_str(\%) {
  my ($time_ref) = @_;
  my %time = _fixStandardRepresentation($time_ref);
  return
    join( _EDI_DATE_SEPARATOR_, $time{&_YEAR_}, $time{&_MONTH_},
    $time{&_DAY_} );
}

sub get_fasta_str(\%) {
  my ($time_ref) = @_;
  my %time = _fixStandardRepresentation($time_ref);
  return join( _FASTA_DATE_SEPARATOR_,
    $time{&_YEAR_}, $time{&_MONTH_}, $time{&_DAY_} );
}

sub get_prebcp_str(\%) {
  my ($time_ref) = @_;
  my %time = _fixStandardRepresentation($time_ref);
  return join(
    _PREBCP_TIME_SEPARATOR_,
    $time{&_YEAR_}, $time{&_MONTH_},  $time{&_DAY_},
    $time{&_HOUR_}, $time{&_MINUTE_}, $time{&_SECOND_}
  );
}

sub get_unix_str(\%) {
  my ($time_ref) = @_;
  my $unix_time;
  eval {
    my @time_array = (
      $time_ref->{&_SECOND_},
      $time_ref->{&_MINUTE_},
      $time_ref->{&_HOUR_},
      $time_ref->{&_DAY_},
      $time_ref->{&_MONTH_} - _MONTH_OFFSET_,
      $time_ref->{&_YEAR_} - _YEAR_OFFSET_
    );
    if   ( $time_ref->{&_GMT_} ) { $unix_time = timegm(@time_array); }
    else                         { $unix_time = timelocal(@time_array); }
  };
  confess "Error:  Cannot get unix time in FileTime::get_unix_str\n"
    . "Error:  Time record may be undefined\n"
    . "Error:  error msg = $@\n"
    if ( defined($@) && $@ );
  return $unix_time;
}

################################################################################

1;

__END__

=head1 NAME

FileTime.pm

=head1 SYNOPSIS

use util::FileTime;

=head1 DESCRIPTION

A time record is a reference to a hash containing the following keys:

   da - [D]D  - day of the month (1..31)--constrainted by the month
   mo -  MMM  - month of the year string (stored as an integer)
                (1-Jan, 2-Feb, 3-Mar,  4-Apr,  5-May,  6-Jun,
                 7-Jul, 8-Aug, 9-Sep, 10-Oct, 11-Nov, 12-Dec)
   yr - YYYY  - year (e.g., 1999, 2000, etc.)
   hr - [H]H  - 24-hour clock hours (0..23)
   mi - [M]M  - minutes into the hour (0..59)
   se - [S]S  - seconds into the minute (0..59)
   wd - D     - day of the week (0-6 - Sunday is 0)
   yd - [DD]D - day of the year (0-364 [or 365 for leap year])

   gm        - is GMT time? (0--FALSE, 1--TRUE)

The B<'gm'> component is used by the get_unix_str static method to
convert a time record into a UNIX time.

This module provides the basic static methods for converting various
sorts of time formats to time record for comparison and conversion.
The time formats currently supported include:

   Type     Format                       Time Type To Time Record  To String Format
   ----     ------                       --------- --------------  ----------------
   CDS      MM/DD/YYYY                   date only get_cds_date    get_cds_str

   CEF      (month, day, year) integers  date only get_cef_date
   
   Excel    nn.nn [0.nnn]                date time get_excel_time 
            int part = 
               days since 1/1/1900
            fractional part =
               fraction of day

   Fasta    YYYYMMDD                     date only                 get_fasta_str

   File     UNIX timestamp               date time get_file_time
            (last mod time of file)

   EDI      YYYY_MM_DD                                             get_edi_str

   GBW      MM/DD/YYYY HH:MM:SS          date time get_gbw_time    get_gbw_str

   HLA      [D]D/[M]M/YYYY               date only get_hla_time    get_hla_str

   MDY      [M]M-[D]D-YYYY               date only get_mdy_time    get_mdy_str

   MySQL    YYYY-MM-DD HH:MM:SS          date time get_mysql_time  get_mysql_str
            YYYY-MM-DD                   date only get_mysql_date  get_mysql_str

   NCBI     DD-MMM-YYYY                  date only get_ncbi_time   get_ncbi_str

   Oracle   [D]D-MMM-YYYY:[H]H:[M]M:[S]S date time get_str_time    get_oracle_str
            [D]D-MMM-YYYY                date only get_str_date    get_oracle_str

   PreBcp   YYYYMMDDhhmmss               date time                 get_prebcp_str

   UNIX     UNIX timestamp               date time get_unix_time   get_unix_str

   dbSNP    YYYY-MM-DD HH:MM             date time get_dbsnp_time  get_dbsnp_str

   Entrez   (month, day, year,           date time get_entrez_time
   Gene     hour, minute, second)
            integers--hour, minute,
            second may be undefined
            or empty string

   Entrez   MMM [D]D YYYY [H]H:MM(AM|PM) date time get_entrez_date
   Gene     YYYY-MM-DD HH:MM (EDT|EST)

   Gene     DD:MM:YYYY HH:MM             date time get_gene_ontology_time
   Ontology

The B<To Time Record> (setter) static method converts the time format
to a time record and the B<To String Format> (getter) static method
convert a time record to the corresponding format.  Also, there is the
(setter) static method B<set_date> that set a time record to the
beginning of the day (zero's out the hours, minutes, and seconds).

The time comparison operators included in this module are: B<equals>,
B<later_than>, and B<later_than_or_equals>.

=head1 CONSTANTS

The following constants are exported from this static class.

   $ORACLE_DATE -- oracle_date
   $UNIX_DATE   -- unix_date

   %DATE_TYPES
   -- Hash list whose keys are the date types.

   OracleDateFormat
   -- The standard Oracle Full Date-Time format specifier used by this class
      'DD-Mon-yyyy:hh24:mi:ss'

   OracleDateOnlyFormat
   -- The standard Oracle Date format specifier used by this class
      'DD-Mon-yyyy'

=head1 SETTER STATIC METHODS

The following setter static methods create time records from string
versions of time formats or modify time records them.


=head2 B<get_cds_date(date_str[, is_gmt_time])>

Given the string B<date_str> in CDS-style time format specifying the
date only (i.e., MM/DD/YYYY), generate the time record for this time
contained in the string B<date_str>.  This time is set to the
beginning of the day that the date specifies.  If the optional Boolean
parameter B<is_gmt_time> is defined and TRUE(1), then set the B<'gm'>
component to the TRUE(1), else set it to FALSE(0).  If the time format
is incompatible with the above CDS-style time format or the date is
inconsistent (i.e., not a real date), then this static method fails
with an error message.

=head2 B<get_cef_date(month, day, year[, is_gmt_time])>

Given the month, day, and year in numeric format specifying the date
only (day and month starting at 1 and year as four digits), generate
the time record for this date.  The time is set to the beginning of
the day that the date specifies.  If the optional Boolean parameter
B<is_gmt_time> is defined and TRUE(1), then set the B<'gm'> component
to the TRUE(1), else set it to FALSE(0).  If the date is inconsistent
(i.e., not a real date), then this static method fails with an error
message.  If the format is in UNIX format (i.e., 101 for 2001 since
offset is 1900), then year and month must be adjust by adding the year
offset (1900) and the month offset (0) to the year and the month,
respectively.

=head2 B<get_excel_time(days.dayfraction [, dayfraction])>

Given an Excel date-time and an optional Excel time generate a time record for these
parameters.

The first input parameter is an internal Excel date-time value which should be parsed from
an Excel spreadsheet. Since Excel stores date-times internally as gmt there is no
parameter to set whether the input date represents a gmt time; that it is a gmt time
is a known fact.

If the first input parameter is an integer, the integer is simply days since 1/1/1900.
If the first input parameter is a float then it represents days since 1/1/1900 plus a fractional
part of a day since 1/1/1900.

The optional second parameter represents an Excel time which is stored as a fraction of a
day.  The Excel time value must be a float with value in the interval 0 E<lt> float E<lt> 1. 
If the second parameter is defined, it's value is added to the value of the first
parameter. The second parameter is typically used when and Excel spreadsheet stores a date
and time as a zero hour date in one column and a time in the second column.

=head2 B<get_entrez_time(month, day, year, hour, minute, second[, is_gmt_time])>

Given the month, day, year, hour, minute, second in numeric format
specifying the date time (day and month starting at 1 and year as four
digits), generate the time record for this date time.  If the optional
Boolean parameter B<is_gmt_time> is defined and TRUE(1), then set the
B<'gm'> component to the TRUE(1), else set it to FALSE(0).  If the
date is inconsistent (i.e., not a real date-time), then this static
method fails with an error message.

=head2 B<get_entrez_date(date_time[, is_gmt_time])>

Given the date-time in Entrez Gene string format, 'MMM [D]D YYYY [H]H:MM(AM|PM)'
or 'YYYY-MM-DD HH:MM (EDT|EST)' this static method converts it into a time
record.  The first format is a 12-hour format, while the second is a
24-hour format. If the optional Boolean parameter B<is_gmt_time> is
defined and TRUE(1), then set the B<'gm'> component to the TRUE(1),
else set it to FALSE(0).  If the date-time is inconsistent (i.e., not
a real date-time), then this static method fails with an error
message.

=head2 B<get_dbsnp_time(date_time[, is_gmt_time])>

Given the date-time in dBSNP string format, 'YYYY-MM-DD HH:MM' this
static method converts it into a time record.  If the optional Boolean
parameter B<is_gmt_time> is defined and TRUE(1), then set the B<'gm'>
component to the TRUE(1), else set it to FALSE(0).  If the date-time
is inconsistent (i.e., not a real date-time), then this static method
fails with an error message.

=head2 B<get_gene_ontology_time(date_time[, is_gmt_time])>

Given the date-time in Gene Onotology string format, 'DD:MM:YYYY
HH:MM' this static method converts it into a time record.  If the
optional Boolean parameter B<is_gmt_time> is defined and TRUE(1), then
set the B<'gm'> component to the TRUE(1), else set it to FALSE(0).  If
the date-time is inconsistent (i.e., not a real date-time), then this
static method fails with an error message.

=head2 B<get_file_time(filename[, is_gmt_time])>

Given the B<filename> parameter, produces the time record representing
the last modified time (in local time) on the file with this
B<filename> in the file system.  If the Boolean parameter
B<is_gmt_time> is defined and TRUE(1), then the time record will
represent GMT-time.  In all other cases, the time record will
represent local time.

=head2 B<get_gbw_time(date_time_str[, is_gmt_time])>

Given the string B<date_time_str> in GBW-style time format specifying
the date and time (i.e., 'MM/DD/YYYY HH:MM:SS'), generate the time
record for this time contained in the string B<date_time_str>.  If the
optional Boolean parameter B<is_gmt_time> is defined and TRUE(1), then
set the B<'gm'> component to the TRUE(1), else set it to FALSE(0).  If
the time format is incompatible with the above GBW-style time format
or the date is inconsistent (i.e., not a real date), then this static
method fails with an error message.

=head2 B<get_hla_time(date_str[, is_gmt_time])>

Given the string B<date_str> in HLA-style time format specifying
the date (i.e., '[D]D/[M]M/YYYY'), generate the time
record for this time contained in the string B<date_str>.  If the
optional Boolean parameter B<is_gmt_time> is defined and TRUE(1), then
set the B<'gm'> component to the TRUE(1), else set it to FALSE(0).  If
the time format is incompatible with the above HLA-style time format
or the date is inconsistent (i.e., not a real date), then this static
method fails with an error message.

=head2 B<get_mdy_time(date_str[, is_gmt_time])>

Given the string B<date_str> in Month-Day-Year time format specifying
the date (i.e., '[D]D-[M]M-YYYY'), generate the time
record for this time contained in the string B<date_str>.  If the
optional Boolean parameter B<is_gmt_time> is defined and TRUE(1), then
set the B<'gm'> component to the TRUE(1), else set it to FALSE(0).  If
the time format is incompatible with the above HLA-style time format
or the date is inconsistent (i.e., not a real date), then this static
method fails with an error message.

=head2 B<get_mysql_time(date_time_str[, is_gmt_time])>

Given the string B<date_time_str> in MySQL-style time format specifying
the date and time (i.e., 'YYYY-MM-DD HH:MM:SS'), generate the time
record for this time contained in the string B<date_time_str>.  If the
optional Boolean parameter B<is_gmt_time> is defined and TRUE(1), then
set the B<'gm'> component to the TRUE(1), else set it to FALSE(0).  If
the time format is incompatible with the above MySQL-style time format
or the date is inconsistent (i.e., not a real date), then this static
method fails with an error message.

=head2 B<get_ncbi_time(date_str[, is_gmt_time])>

Given the string B<date_time_str> in NCBI-style time format specifying
the date (i.e., 'DD-MMM-YYYY'), generate the time
record for this time contained in the string B<date_str>.  If the
optional Boolean parameter B<is_gmt_time> is defined and TRUE(1), then
set the B<'gm'> component to the TRUE(1), else set it to FALSE(0).  If
the time format is incompatible with the above NCBI-style time format
or the date is inconsistent (i.e., not a real date), then this static
method fails with an error message.

=head2 B<get_str_date(date_str[, is_gmt_time])>

Given the string B<date_str> in Oracle-style time format specifying
the date only (i.e., [D]D-MMM-YYYY), generate the time record for this
time contained in the string B<date_str>.  This time is set to the
beginning of the day that the date specifies.  If the optional Boolean
parameter B<is_gmt_time> is defined and TRUE(1), then set the B<'gm'>
component to the TRUE(1), else set it to FALSE(0).  If the time format
is incompatible with the above Oracle-style time format or the date is
inconsistent (i.e., not a real date), then this static method fails
with an error message.

=head2 B<get_mysql_date(date_str[, is_gmt_time])>

Given the string B<date_str> in MySQL-style time format specifying
the date only (i.e., YYYY-MM-DD), generate the time record for this
time contained in the string B<date_str>.  This time is set to the
beginning of the day that the date specifies.  If the optional Boolean
parameter B<is_gmt_time> is defined and TRUE(1), then set the B<'gm'>
component to the TRUE(1), else set it to FALSE(0).  If the time format
is incompatible with the above MySQL-style time format or the date is
inconsistent (i.e., not a real date), then this static method fails
with an error message.

=head2 B<get_str_time(time_str[, is_gmt_time])>

Given the string B<time_str> in Oracle-style time format, generate the
time record for the time contained in the string B<time_str>.  If the
optional Boolean parameter B<is_gmt_time> is defined and TRUE(1), then
set the B<'gm'> component to the TRUE(1), else set it to FALSE(0).  If
the time format is incompatible with the above Oracle-style time
format or the date is inconsistent (i.e., not a real date), then this
static method fails with an error message.

The Oracle-style formatted time string has the following format:

   "[D]D-MMM-YYYY:[H]H:[M]M:[S]S"

The month is the case case-insensitive string as indicated above in
the 'mo' filed for a time record.  The month is stored as the
corresponding integer.  An optional zero (0) prefix for day, hour,
minute, and second is allowed but not necessary.  For example, the
time value

   '7-Jul-2000:14:30:00'

represents

   July 7, 2000 14:30:00 hours.

=head2 B<get_unix_time(unix_time[, is_gmt_time])>

Given the B<unix_time>, generate the time record representing the unix
time provided by the unix time in B<unix_time>.  If the Boolean
parameter B<is_gmt_time> is defined and TRUE(1), then the time record
will represent GMT time.  In all other cases, the time record will
represent local time.

=head2 B<set_date(time_ref)>

This static method sets the time in the B<time_ref> to its date. That
is, this static method sets the time to beginning of the day that the
B<time_ref> specifies.

=head1 GETTER STATIC METHODS

The following getter static methods return string versions of time
formats from time records.

=head2 B<get_dbsnp_str(time_ref[, date_only])>

This static method takes a time record and returns the corresponding
dbSNP-style date string, 'YYYY-MM-DD HH:MM', where all the fields are
numeric.  The day month, hour, and minute are zero-padded on the left
if the value is less than 10.  If B<date_only> is provided and TRUE,
then only the date portion of the format (YYYY-MM-DD) is provided.

=head2 B<get_cds_str(time_ref)>

This static method takes a time record and returns the corresponding
CDS-style date string, MM/DD/YYYY, where all the fields are numeric.
The day and month are zero-padded on the left if the value is less
than 10.

=head2 B<get_edi_str(time_ref)>

This static method takes a time record and returns the corresponding
EDI-style date string, YYYY_MM_DD, where all the fields are numeric.
The day and month are zero-padded on the left if the value is less
than 10.

=head2 B<get_fasta_str(time_ref)>

This static method takes a time record and returns the corresponding
FASTA-FILE-style date string, YYYYMMDD, where all the fields are
numeric.  The day and month are zero-padded on the left if the value
is less than 10.

=head2 B<get_gbw_str(time_ref[, date_only])>

This static method takes a time record and returns the corresponding
GBW-style time string, 'MM/DD/YYYY HH:MM:SS'.  If the optional Boolean
parameter B<date_only> is defined and TRUE (1), then only the date
portion (MM/DD/YYYY) of the GBW time string is returned (i.e., no
hours, minutes, or seconds).  In all other cases, the entire GBW time
string is returned.  The day, hours, minutes, seconds are zero-padded
on the left if the value is less than 10.

=head2 B<get_hla_str(time_ref)>

This static method takes a time record and returns the corresponding
HLA-style date string, '[D]D/[M]M/YYYY'.

=head2 B<get_mdy_str(time_ref)>

This static method takes a time record and returns the corresponding
Month-Day-Year date string, '[D]D-[M]M-YYYY'.

=head2 B<get_mysql_str(time_ref[, date_only])>

This static method takes a time record and returns the corresponding
MySQL-style time string, 'YYYY-MM-DD HH:MM:SS'.  If the optional Boolean
parameter B<date_only> is defined and TRUE (1), then only the date
portion (YYYY-MM-DD) of the MySQL time string is returned (i.e., no
hours, minutes, or seconds).  In all other cases, the entire MySQL time
string is returned.  The day, hours, minutes, seconds are zero-padded
on the left if the value is less than 10.

=head2 B<get_ncbi_str(time_ref)>

This static method takes a time record and returns the corresponding
NCBI-style time string, 'DD-MMM-YYYY', where the day and year fields
are numeric and the month field is the oracle month.  The day is 
zero-padded on the left if the value is less than 10.

=head2 B<get_oracle_str(time_ref[, date_only])>

This static method takes a time record and returns the corresponding
Oracle-style time string, DD-MMM-YYYY:HH:MM:SS.  If the optional
Boolean parameter B<date_only> is defined and TRUE (1), then only the
date portion (DD-MMM-YYYY) of the Oracle time string is returned
(i.e., no hours, minutes, or seconds).  In all other cases, the entire
Oracle time string is returned.  The day, hours, minutes, seconds are
zero-padded on the left if the value is less than 10.

=head2 B<get_prebcp_str(time_ref)>

This static method takes a time record and returns the corresponding
PRE-BCP style date-time string, YYYYMMDDhhmmss, where all the fields
are numeric.  The day, month, hour, minute, and second are zero-padded
on the left if the value is less than 10.

=head2 B<get_unix_str(time_ref)>

This static method takes a time record and returns the corresponding
unix time.

=head1 STATIC RELATIONAL METHODS

The following static relational methods are exported from this static
class.

=head2 B<equals(time_ref, later_ref)>

This static method takes two time records, B<time_ref> and
B<later_ref>, and returns TRUE(1) if B<time_ref> equals B<later_ref>
(i.e., they are the same time), otherwise it returns FALSE(0).

=head2 B<later_than(time_ref, later_ref)>

This static method takes two time records, B<time_ref> and
B<later_ref>, and returns TRUE(1) if B<time_ref> is later than
B<later_ref> (i.e., B<time_ref> is more recent than B<later_ref>),
else it returns FALSE(0) (i.e., B<time_ref> is no more recent than
B<later_ref>).

=head2 B<later_than_or_equals(time_ref, later_ref)>

This static method takes two time records, B<time_ref> and
B<later_ref>, and returns TRUE(1) if B<time_ref> is later than or
equal to B<later_ref> (i.e., B<time_ref> is at least as recent as
B<later_ref>), else returns FALSE(0) (i.e., B<time_ref> is in the past
of B<later_ref>).

=cut
