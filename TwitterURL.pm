package TwitterURL;

use strict;
use warnings;
use DBI;

my $dbname = 'twitter_url';

sub new {
    my( $class, %args ) = @_;
    my $self = {};
    bless $self, $class;

    my $db = DBI->connect(
        "dbi:Pg:dbname=$dbname",
        '', '',
        {
            AutoCommit       => 0,
            PrintError       => 0,
            RaiseError       => 0,
            FetchHashKeyName => 'NAME_lc'
        }
    ) or die "failed to connect database $dbname: $!";
    $self->{db} = $db;
    return $self;
}

sub errstr {
    shift->{db}->errstr;
}

sub fetchall_arrayref_hash {
    my( $self, $sth ) = @_;
    my $result = [];
    while( my $ref = $sth->fetchrow_hashref ) {
        push @{$result}, $ref;
    }
    return $result;
}

sub insert_url {
    my( $self, $tweet, $screen_name, $url ) = @_;

    my $sth = $self->{db}->prepare( "
        insert into twitter_url
        ( tweet, screen_name, url, created_on, updated_on )
        values ( ?, ?, ?, now(), now() )
    " );
    my $result = $sth->execute( $tweet, $screen_name, $url );
    if ($result) {
        $sth->finish;
        $self->{db}->commit;
    }
    else {
        my $errstr = $self->{db}->errstr;
        my $state = $self->{db}->state;
        $self->{db}->rollback;
        # ignore unique_violation
        if ( 23505 != $state ) {
            die "failed to commit : " . $errstr;
        }
    }
    return 1;
}

sub add_args {
    my( $self, $sql, %args ) = @_;
    my $db = $self->{db};
    for my $key ( keys %args ) {
        my $val = $args{$key};
        $key =~ s/\_/ /g;
        $sql .= sprintf " %s %s", $key, $val;
    }
    return $sql;
}

sub select_twitter_url {
    my ( $self, %args ) = @_;

    my $db  = $self->{db};
    my $sql = $self->add_args( 'select * from twitter_url', %args );
    my $sth = $db->prepare($sql) or die $db->errstr;

    my $result = $sth->execute;
    if ($result) {
        my $ref = $self->fetchall_arrayref_hash($sth);
        $sth->finish;
        return $ref;
    }
    return;
}

sub select_count {
    my $self = shift;
    my $sth = $self->{db}->prepare( "
        select count(*) as count from twitter_url
    " );
    my $result = $sth->execute;
    if ($result) {
        my $ref = $self->fetchall_arrayref_hash($sth);
        $sth->finish;
        return $ref;
    }
    return;
}

sub delete_id {
    my( $self, $id ) = @_;

    my $db  = $self->{db};
    my $sth = $db->prepare( "
        delete from twitter_url where id = ?
    " );
    my $result = $sth->execute($id);
    if ($result) {
        if ( 1 == $sth->rows ) {
            $sth->finish;
            $db->commit;
            return 1;
        }
        else {
            $db->rollback;
            die "deleted record is not 1. but " . $sth->rows;
        }
    }
    else {
        die "delete failed: $! : " . $db->errstr;
    }
}

1;
