package db::DB_Handler;
use warnings;
use strict;
use Carp;
use DBI;
use Data::Dumper;


sub new {
    my $class = shift;
    my $self = { @_ };
    bless( $self, $class);
    $self->_init;
    return $self;
}


sub _init {

    my $self = shift;
    eval{
##########        $self->{db_conn} = DBI->connect(
##########            'dbi:'.$self->{db_platform}.':dbname='.$self->{db_name}.';host='.$self->{db_host},
##########            $self->{db_user}, 
##########            $self->{db_pass},
##########            {RaiseError => 1,AutoCommit => 1}
##########        ) || die "\n".'Cannot get postgres connection.'."\n\t".$?;

        $self->{db_conn} = DBI->connect(
            'dbi:'.$self->{db_platform}.':'.$self->{db_name},
            $self->{db_user},$self->{db_pass},{RaiseError => 1,AutoCommit => 1, LongReadLen =>512*1204}
        ) || die "\n".'Cannot get postgres connection.'."\n\t".$?;

    }


}

sub close { $_[0]->{db_conn}->disconnect; }

sub db_conn{ $_[0]->{db_conn} }


sub db_name { $_[0]->{db_name} }


sub db_host { $_[0]->{db_host} }


sub db_pass { $_[0]->{db_pass} }


sub db_user { $_[0]->{db_user} }


sub db_platform { $_[0]->{db_platform} }

sub db_debug { $_[0]->{db_debug}= $_[1] if defined $_[1]; $_[0]->{db_debug}}

sub getResult { 

    my $self = $_[0];
    my $sqlQuery = $_[1];

    my @result;

    eval{

        my $sqlHandle = $self->db_conn()->prepare($sqlQuery);

        my $returnValue = $sqlHandle->execute();

        warn $returnValue if $self->db_debug();

        while(my @row = $sqlHandle->fetchrow_array()){

            push(@result,\@row);
        }

        $sqlHandle->finish();
    };


    if($@){

        warn "Error in execution of query, $sqlQuery $@";
        return;
    }

    return \@result;

}

sub update_classification {
	my $self = $_[0];

	my $sqlQuery = $_[1];

        my $sqlHandle = $self->db_conn()->prepare($sqlQuery);
	     
        my $returnValue = $sqlHandle->execute();
	     
        warn $returnValue if $self->db_debug(); 
 	
	$sqlHandle->finish();

	return 1;	   
}

sub setResult{


    my $self = $_[0];
    my $sqlQuery = $_[1];
    my $sqlHandle = $self->db_conn()->prepare($sqlQuery);

    my $returnValue = $sqlHandle->execute();

    warn $returnValue if $self->db_debug();

    $sqlHandle->finish();

    return 1;
}

1;
