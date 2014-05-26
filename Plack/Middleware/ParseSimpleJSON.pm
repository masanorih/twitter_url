package Plack::Middleware::ParseSimpleJSON;
# parse simple json data from content and set to QUERY_STRING
use parent qw(Plack::Middleware);
use Plack::Request;
use JSON qw( from_json );

=pod

this works only when json is simple hash ref. sth like
    {
        a: 'b',
        c: 'd'
    }
and now supports array data. so
    {
        a: 'b',
        c: [ 'd', 'e' ]
    }
is also ok

=cut

sub call {
    my( $self, $env ) = @_;
    #use Data::Dumper; #die Dumper $env;
    #warn "psgi.input = " . $env->{'psgi.input'};
    #use Data::Dumper; warn Dumper $env->{'psgi.input'};
    #die $env->{'mojo.c'}->tx->req->headers->content_type;
    my $content_type;
    my $content;
    if ( $env->{'mojo.c'} ) {
        $req = $env->{'mojo.c'}->tx->req;
        $content_type = $req->headers->content_type;
        $content      = $req->body;
    }
    else {
        my $req = Plack::Request->new($env);
        $content_type = $req->content_type;
        $content      = $req->content;
    }
    #warn "content_type = $content_type";
    if ( $content_type and $content_type =~ m!^application/json! ) {
        $json = from_json($content);
        _json2query( $env, $json );
    }
    $self->app->($env);
}

sub _json2query {
    my( $env, $json ) = @_;
    my @query;
    for my $key ( keys %{$json} ) {
        my $val = $json->{$key};
        if ( 'ARRAY' eq ref $val ) {
            for my $v ( @{$val} ) {
                push @query, sprintf( "%s=%s", $key, $v );
            }
        }
        else {
            push @query, sprintf( "%s=%s", $key, $val );
        }
    }
    $env->{QUERY_STRING} = join( '&', @query ) if @query;
}

1;
