package TwitterURL;

use strict;
use warnings;
use DBI;

my $dbname = 'twitter_url';

use constant STATUS_LIST  => 1;
use constant STATUS_SAVED => 2;

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
            RaiseError       => 1,
            FetchHashKeyName => 'NAME_lc'
        }
    ) or die "failed to connect database $dbname: $!";
    $self->{db} = $db;
    return $self;
}

sub errstr {
    shift->{db}->errstr;
}

sub state {
    shift->{db}->state;
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
    my( $self, %args ) = @_;

    #warn "insert_url prepare";
    my $sth = $self->{db}->prepare( "
        select id from twitter_url where url = ?
    " );
    my $result = $sth->execute($args{url});
    my $ref = $self->fetchall_arrayref_hash($sth);
    #use Data::Dumper; warn Dumper $ref;
    if ( 'ARRAY' eq ref $ref and exists $ref->[0]->{id} ) {
        #warn "record already exists";
        return 1;
    }

    eval {
        alarm 5;
        local $SIG{ALRM} = sub { die "timeout" };
        $sth = $self->{db}->prepare( "
            insert into twitter_url
            ( url, screen_name, tweet, status, created_on, updated_on )
            values ( ?, ?, ?, ?, now(), now() )
        " );
        #warn "insert_url execute";
        $sth->execute( $args{url}, $args{name},
            $args{tweet}, $args{status} );
        #warn "insert_url execute end";
    };
    alarm 0;

    if ($@) {
        my $errstr = $self->{db}->errstr;
        my $state  = $self->{db}->state;
        #warn '$@=' . $@;
        warn "errstr=$errstr";
        warn "state=$state";
        $self->{db}->rollback;
        # ignore unique_violation
        #if ( 23505 ne $state ) {
        #    die "failed to commit : " . $errstr;
        #}
    }
    else {
        $sth->finish;
        $self->{db}->commit;
    }
    return 1;
}

sub add_args {
    my( $self, $sql, %args ) = @_;
    my $db = $self->{db};
    if ( $args{where} ) {
        my $hash = delete $args{where};
        my @list;
        for my $key ( keys %{$hash} ) {
            my $val = $hash->{$key};
            push @list, sprintf( "%s = %s", $key, $val );
        }
        if (@list) {
            my $where_clause = join ' and ', @list;
            $sql .= ' where ' . $where_clause;
        }
    }
    for my $key ( keys %args ) {
        my $val = $args{$key};
        $key =~ s/\_/ /g;
        $sql .= sprintf " %s %s", $key, $val;
    }
    #warn "add_args sql = $sql";
    return $sql;
}

sub select_twitter_url {
    my ( $self, %args ) = @_;

    my $db  = $self->{db};
    my $sql = $self->add_args( 'select * from twitter_url', %args );
    my $sth = $db->prepare($sql) or die $db->errstr;

    my $result = $sth->execute();
    if ($result) {
        my $ref = $self->fetchall_arrayref_hash($sth);
        $sth->finish;
        return $ref;
    }
    return;
}

sub select_count {
    my ( $self, %args ) = @_;
    my $db  = $self->{db};
    my $sql = $self->add_args( 'select count(*) as count from twitter_url',
        %args );
    my $sth = $db->prepare($sql) or die $db->errstr;
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
        elsif ( 0 == $sth->rows ) {
            # already deleted. ignore
            $db->rollback;
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

sub save_id {
    my( $self, $id ) = @_;

    my $db  = $self->{db};
    my $sth = $db->prepare( "
        update twitter_url set status = ?, updated_on = current_timestamp
        where id = ?
    " );
    my $result = $sth->execute( STATUS_SAVED, $id );
    if ($result) {
        if ( 1 == $sth->rows ) {
            $sth->finish;
            $db->commit;
            return 1;
        }
        else {
            $db->rollback;
            die "update record is not 1. but " . $sth->rows;
        }
    }
    else {
        die "update failed: $! : " . $db->errstr;
    }
}

1;
