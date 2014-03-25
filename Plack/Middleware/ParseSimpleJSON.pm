package Plack::Middleware::ParseSimpleJSON;
# parse simple json data from content and set to QUERY_STRING
use parent qw(Plack::Middleware);
use JSON qw( from_json );

sub call {
    my($self, $env) = @_;
    my $req = Plack::Request->new($env);
    if ( $req->content_type =~ m!^application/json! ) {
        my $json = from_json( $req->content );
        my @query;
        # XXX this works only when json is simple hash ref. XXX
        for my $key ( keys %{$json} ) {
            my $val = $json->{$key};
            push @query, sprintf( "%s=%s", $key, $val );
        }
        $env->{QUERY_STRING} = join( '&', @query ) if @query;
    }

    $self->app->($env);
}

1;
