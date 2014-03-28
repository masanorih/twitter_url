#!perl

use strict;
use warnings;
use Encode qw( encode_utf8 );
use JSON qw( to_json from_json );
use Plack::Builder;
use Plack::Request;
use Text::Xslate;
use TwitterURL;

my $tx   = Text::Xslate->new;
my $turl = TwitterURL->new;

my $app = sub {
    my $env  = shift;
    my $req  = Plack::Request->new($env);
    my $path = $req->path_info;

    if ( not $path or $path eq '/' ) {
        return_root($req);
    }
    elsif ( $path eq '/list' ) {
        return_list($req);
    }
    elsif ( $path eq '/count' ) {
        return_count($req);
    }
    elsif ( $path eq '/delete' ) {
        return_delete($req);
    }
    elsif ( $path eq '/save' ) {
        return_save($req);
    }
    elsif ( $path eq '/insert' ) {
        return_insert($req);
    }
    else {
        [ 404, [ "Content-Type" => "text/plain" ], ["404 Not Found"] ];
    }
};

builder {
    enable "Plack::Middleware::ParseSimpleJSON";
    $app;
};

sub return_root {
    my $req = shift;
    my $res = $req->new_response(200);
    $res->content_type('text/html; charset=UTF-8');
    $res->body( render_root() );
    $res->finalize;
}

sub return_list {
    my $req = shift;
    my $width  = $req->param('width');
    my $status = $req->param('status');
    $status = 'saved' eq $status ? 2 : 1;
    my $limit = int( $width / 150 ) + 1;
    my $res   = $req->new_response(200);
    $res->content_type('application/json; charset=UTF-8');
    $res->body( render_list( limit => $limit, status => $status ) );
    $res->finalize;
}

sub return_count {
    my $req = shift;
    my $status = $req->param('status');
    $status = 'saved' eq $status ? 2 : 1;
    my $res = $req->new_response(200);
    $res->content_type('application/json; charset=UTF-8');
    $res->body( render_count( status => $status ) );
    $res->finalize;
}

sub return_delete {
    my $req = shift;
    my $id  = $req->param('id');
    my $res = $req->new_response(200);
    $res->content_type('application/json; charset=UTF-8');
    $res->body( render_delete($id) );
    $res->finalize;
}

sub return_save {
    my $req = shift;
    my $id  = $req->param('id');
    my $res = $req->new_response(200);
    $res->content_type('application/json; charset=UTF-8');
    $res->body( render_save($id) );
    $res->finalize;
}

sub return_insert {
    my $req = shift;
    my $url = $req->param('url');
    my $res = $req->new_response(200);
    $res->content_type('application/json; charset=UTF-8');
    $res->body( render_insert($url) );
    $res->finalize;
}

sub render_json {
    my $ref = shift;
    to_json( $ref, { utf8 => 1, pretty => 1 } );
}

sub render_root {
    my $vars = $turl->select_twitter_url(
        order_by => 'id',
        limit    => 5000,
    );
    return encode_utf8 $tx->render( 'list.tx', { url_list => $vars } );
}

sub render_list {
    my %args = @_;
    my $vars = $turl->select_twitter_url(
        order_by => 'id',
        limit    => $args{limit},
        where    => {
            status => $args{status},
        },
    );
    render_json($vars);
}

sub render_count {
    my %args = @_;
    my $vars = $turl->select_count(
        where => {
            status => $args{status},
        },
    );
    render_json($vars);
}

sub render_delete {
    my $id     = shift;
    my $result = $turl->delete_id($id);
    $result
        ? render_json( { result => 'ok' } )
        : render_json( { result => 'ng', message => $turl->errstr } );
}

sub render_save {
    my $id     = shift;
    my $result = $turl->save_id($id);
    $result
        ? render_json( { result => 'ok' } )
        : render_json( { result => 'ng', message => $turl->errstr } );
}

sub render_insert {
    my $url    = shift;
    my $result = $turl->insert_url( text => '', name => 'web',
        url => $url, status => 2 );
    $result
        ? render_json( { result => 'ok' } )
        : render_json( { result => 'ng', message => $turl->errstr } );
}
